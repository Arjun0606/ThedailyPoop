import SwiftUI
import CoreLocation
import UIKit

struct DropComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    // Subscription removed
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var friendsManager: FriendsManager
    
    @State private var caption: String = ""
    @State private var selectedSkinId: String? = nil
    @State private var isDropping = false
    // Pro removed
    @State private var showingLocationError = false
    @State private var currentLocation: CLLocation?
    @State private var isNoPoop = false // Toggle for "no poop" option
    
    // NEW: Rating and music
    @State private var rating: Double = 5.0 // 1-10 slider, default 5
    @State private var musicLink: String = ""
    @State private var musicData: MusicData? = nil
    
    private let freeCharLimit = 50
    private let proWordLimit = 200
    
    // Available skins
    private let freeSkins = ["💩"] // Default poop
    private let proSkins: [String] = []
    
    var availableSkins: [String] {
        freeSkins
    }
    
    var captionLimitText: String {
            return "\(caption.wordCount)/\(proWordLimit) words"
    }
    
    var isAtLimit: Bool {
            return caption.wordCount >= proWordLimit
    }
    
    var canDrop: Bool {
        // For "no poop", don't require location or caption
        if isNoPoop {
            return !isDropping
        }
        // For regular poop, require location and caption
        return currentLocation != nil && !isDropping && !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Poop type selector
                        PoopTypeSelector(isNoPoop: $isNoPoop)
                        
                        // Location info (only for regular poops)
                        if !isNoPoop {
                            if let location = currentLocation {
                                LocationInfoView(location: location)
                            } else {
                                LocationLoadingView()
                            }
                        }
                        
                        // Single poop type only - remove style selector
                        
                        // NEW: Poop Rating Slider
                        if !isNoPoop {
                            PoopRatingSlider(rating: $rating)
                        }
                        
                        // Caption input
                        CaptionInputView(
                            caption: $caption,
                            userIsPro: true,
                            freeCharLimit: freeCharLimit,
                            proWordLimit: proWordLimit,
                            limitText: captionLimitText,
                            isAtLimit: isAtLimit,
                            onLimitReached: {}
                        )
                        
                        // NEW: Music Link Input
                        if !isNoPoop {
                            MusicLinkInput(musicLink: $musicLink, musicData: $musicData)
                        }
                        
                        // Pro removed
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Drop button
                VStack {
                    Spacer()
                    DropButton(
                        canDrop: canDrop,
                        isDropping: isDropping,
                        isNoPoop: isNoPoop,
                        action: createDrop
                    )
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Drop a Poop 💩")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            getCurrentLocation()
        }
        // Pro removed
        .alert("Location Required", isPresented: $showingLocationError) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("TheDailyPoop needs location access to drop poops. Please enable location access in Settings.")
        }
    }
    
    private func getCurrentLocation() {
        // Only get location for regular poops
        guard !isNoPoop else { return }
        
        Task {
            do {
                currentLocation = try await locationManager.getCurrentLocation()
            } catch {
                showingLocationError = true
            }
        }
    }
    
    private func createDrop() {
        guard let user = authManager.currentUser else { return }
        
        // For regular poops, require location
        if !isNoPoop && currentLocation == nil {
            showingLocationError = true
            return
        }
        
        isDropping = true
        
        // Simplified - no Pro features, use word limit for all users
        let finalCaption = caption.truncatedToWordLimit(200)
        
        Task {
            // Resolve city/state/country once to avoid slow geocoding later
            var resolvedCity: String? = nil
            var resolvedCountry: String? = nil
            var resolvedContinent: String? = nil
            if !isNoPoop, let loc = currentLocation {
                let geocoder = CLGeocoder()
                if let placemark = try? await geocoder.reverseGeocodeLocation(loc).first {
                    resolvedCity = placemark.locality
                    resolvedCountry = placemark.country
                    resolvedContinent = getContinent(for: placemark.country ?? "")
                }
            }
        
        let drop = Drop(
                userID: user.id,
                username: user.username,
                location: isNoPoop ? nil : currentLocation?.coordinate,
                city: resolvedCity,
                country: resolvedCountry,
                continent: resolvedContinent,
            skinId: isNoPoop ? nil : selectedSkinId,
            caption: finalCaption.isEmpty ? nil : finalCaption,
            isNoPoop: isNoPoop,
                isSponsored: false,
                rating: isNoPoop ? nil : Int(rating),
                musicTitle: musicData?.title,
                musicArtist: musicData?.artist,
                musicURL: musicData?.url,
                musicCoverArt: musicData?.coverArtURL
            )

            do {
                print("🚀 Creating drop for user: \(user.username) at location: \(String(describing: drop.location))")
                try await cloudKitManager.saveDrop(drop)
                print("✅ Drop saved successfully to CloudKit")
                
                // Update user's streak and total drops FIRST (before other operations)
                await updateUserStats()
                
                // Check for badge eligibility with updated stats
                let badgeManager = BadgeManager()
                let userDrops = try await cloudKitManager.fetchUserDrops(for: user)
                await badgeManager.checkBadgeEligibility(for: user, drops: userDrops)
                
                // Notify friends about the drop
                do {
                    let friends = try await CloudKitManager.shared.fetchFriends(for: user)
                    await NotificationManager.shared.notifyFriendPooped(
                        friend: user,
                        drop: drop,
                        recipients: friends
                    )
                } catch {
                    print("Failed to notify friends of drop: \(error)")
                }
                
                // Schedule next poop reminder (12 hours from now)
                await NotificationManager.shared.schedulePoopReminder(for: user)
                
                await MainActor.run {
                    isDropping = false
                    dismiss()
                    print("🗺️ Posting DID_CREATE_DROP notification to switch to map")
                    // Post notification so MainTabView can switch to Map and center on this drop
                    NotificationCenter.default.post(name: Notification.Name("DID_CREATE_DROP"), object: nil, userInfo: ["drop": drop])
                    // Post notification to refresh profile stats
                    NotificationCenter.default.post(name: Notification.Name("USER_STATS_UPDATED"), object: nil)
                }
                
            } catch {
                print("❌ ERROR creating drop: \(error)")
                
                await MainActor.run {
                    isDropping = false
                    // Even if CloudKit fails, post the drop locally so map shows it
                    print("🗺️ CloudKit failed, but posting drop locally to show on map")
                    dismiss()
                    NotificationCenter.default.post(name: Notification.Name("DID_CREATE_DROP"), object: nil, userInfo: ["drop": drop])
                    // Post notification to refresh profile stats
                    NotificationCenter.default.post(name: Notification.Name("USER_STATS_UPDATED"), object: nil)
                }
            }
        }
    }
    
    private func updateUserStats() async {
        guard var user = authManager.currentUser else { return }
        
        print("📊 Updating user stats: totalDrops was \(user.totalDrops), streak was \(user.streak)")
        
        // Update total drops
        user.totalDrops += 1
        
        // Calculate drops today for max tracking
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        // Wait a moment for CloudKit to catch up with the drop we just saved
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        do {
            let userDrops = try await cloudKitManager.fetchUserDrops(for: user)
            print("📊 Fetched \(userDrops.count) total drops for user (should include drop we just saved)")
            
            // Calculate max drops in any single 24-hour day (00:00 to 23:59)
            // Group all drops by day and find the day with most drops
            var dropsPerDay: [String: Int] = [:]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            // Count only the drops returned from CloudKit (which already includes the drop we just saved)
            for drop in userDrops where !drop.isNoPoop {
                let dayKey = dateFormatter.string(from: drop.timestamp)
                dropsPerDay[dayKey, default: 0] += 1
            }
            
            // Find the maximum drops in any single day
            let maxInAnyDay = dropsPerDay.values.max() ?? 0
            let todayKey = dateFormatter.string(from: today)
            let todayDrops = dropsPerDay[todayKey] ?? 0
            
            print("📊 Today's drops: \(todayDrops), max drops in any day: \(maxInAnyDay)")
            print("📊 Drops per day breakdown: \(dropsPerDay)")
            print("📊 Total drops from CloudKit: \(userDrops.count)")
            
            // Update max drops in day to the highest count across all days
            user.maxDropsInDay = maxInAnyDay
            print("📊 Set maxDropsInDay to \(maxInAnyDay)")
            
            // Calculate longest no-poop streak
            calculateLongestNoPoopStreak(userDrops: userDrops, user: &user)
            
        } catch {
            print("❌ Failed to fetch user drops for stats: \(error)")
            // Even if fetch fails, still count this drop
            if user.maxDropsInDay == 0 {
                user.maxDropsInDay = 1
            }
        }
        
        // Update streak
        if let lastDropDate = user.lastDropDate {
            if calendar.isDate(lastDropDate, inSameDayAs: today) {
                // Same day, don't change streak
            } else if calendar.isDate(lastDropDate, equalTo: calendar.date(byAdding: .day, value: -1, to: today) ?? today, toGranularity: .day) {
                // Yesterday, increment streak
                user.streak += 1
            } else {
                // Streak broken, reset to 1
                user.streak = 1
            }
        } else {
            // First drop, start streak
            user.streak = 1
        }
        
        user.lastDropDate = today
        if !isNoPoop {
            user.lastRealDropDate = today
        }
        
        // Update travel tracking if location is available
        if !isNoPoop, let location = currentLocation {
            await updateTravelStats(for: &user, location: location)
        }
        
        print("📊 Updated user stats: totalDrops now \(user.totalDrops), streak now \(user.streak), maxDropsInDay: \(user.maxDropsInDay), countries: \(user.countriesVisited.count), continents: \(user.continentsVisited.count)")
        
        do {
            try await cloudKitManager.saveUser(user)
            await MainActor.run {
                authManager.currentUser = user
                print("✅ User stats saved to CloudKit and updated in authManager")
                // Notify profile to refresh stats
                NotificationCenter.default.post(name: Notification.Name("USER_STATS_UPDATED"), object: nil)
            }
        } catch {
            print("❌ Failed to save user stats to CloudKit: \(error), but updating locally")
            await MainActor.run {
                authManager.currentUser = user
                // Still notify even if save failed, to update UI with local changes
                NotificationCenter.default.post(name: Notification.Name("USER_STATS_UPDATED"), object: nil)
            }
        }
    }
    
    private func calculateLongestNoPoopStreak(userDrops: [Drop], user: inout User) {
        let calendar = Calendar.current
        let sortedDrops = userDrops.sorted { $0.timestamp < $1.timestamp }
        
        var longestStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        for drop in sortedDrops {
            let dropDate = drop.timestamp
            
            if let last = lastDate {
                let daysDifference = calendar.dateComponents([.day], from: last, to: dropDate).day ?? 0
                
                if daysDifference > 1 && !drop.isNoPoop {
                    // Gap found and it's a real poop (not no-poop)
                    currentStreak = daysDifference - 1
                    longestStreak = max(longestStreak, currentStreak)
                    currentStreak = 0
                }
            }
            
            lastDate = dropDate
        }
        
        // Check current gap from last drop to today
        if let lastDate = lastDate {
            let daysSinceLastDrop = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if daysSinceLastDrop > 0 {
                longestStreak = max(longestStreak, daysSinceLastDrop)
            }
        }
        
        user.longestNoPoopStreak = max(user.longestNoPoopStreak, longestStreak)
    }
    
    private func updateTravelStats(for user: inout User, location: CLLocation) async {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                // Add country
                if let country = placemark.country {
                    let wasNew = user.countriesVisited.insert(country).inserted
                    if wasNew {
                        print("🌍 New country visited: \(country)! Total countries: \(user.countriesVisited.count)")
                    }
                }
                
                // Add continent based on country
                if let country = placemark.country {
                    let continent = getContinent(for: country)
                    let wasNew = user.continentsVisited.insert(continent).inserted
                    if wasNew {
                        print("🌏 New continent visited: \(continent)! Total continents: \(user.continentsVisited.count)")
                    }
                }
            }
        } catch {
            print("Failed to get location details for travel tracking: \(error)")
        }
    }
    
    private func getContinent(for country: String) -> String {
        // Map countries to continents
        let continentMap: [String: String] = [
            // North America
            "United States": "North America", "Canada": "North America", "Mexico": "North America",
            "Guatemala": "North America", "Belize": "North America", "Costa Rica": "North America",
            
            // South America
            "Brazil": "South America", "Argentina": "South America", "Chile": "South America",
            "Peru": "South America", "Colombia": "South America", "Venezuela": "South America",
            
            // Europe
            "United Kingdom": "Europe", "France": "Europe", "Germany": "Europe", "Italy": "Europe",
            "Spain": "Europe", "Netherlands": "Europe", "Sweden": "Europe", "Norway": "Europe",
            
            // Asia
            "China": "Asia", "Japan": "Asia", "India": "Asia", "South Korea": "Asia",
            "Thailand": "Asia", "Singapore": "Asia", "Malaysia": "Asia", "Indonesia": "Asia",
            
            // Africa
            "South Africa": "Africa", "Egypt": "Africa", "Morocco": "Africa", "Kenya": "Africa",
            "Nigeria": "Africa", "Ghana": "Africa", "Tanzania": "Africa",
            
            // Oceania
            "Australia": "Oceania", "New Zealand": "Oceania", "Fiji": "Oceania", "Papua New Guinea": "Oceania",
            
            // Antarctica (for adventurous poopers!)
            "Antarctica": "Antarctica"
        ]
        
        return continentMap[country] ?? "Unknown"
    }
}

// MARK: - Supporting Views

struct LocationInfoView: View {
    let location: CLLocation
    @State private var address: String?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
                Text("Current Location")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            if let address = address {
                HStack {
                    Text(address)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            Task {
                address = await LocationManager().getAddressFromLocation(location)
            }
        }
    }
}

struct LocationLoadingView: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Getting your location...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SkinSelectorView: View {
    @Binding var selectedSkinId: String?
    let availableSkins: [String]
    let userIsPro: Bool
    let onProSkinTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Choose Your Poop Style")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if userIsPro {
                    Text("PRO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.yellow)
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(availableSkins, id: \.self) { skin in
                    Button(action: {
                        selectedSkinId = skin == "💩" ? nil : skin
                    }) {
                        Text(skin)
                            .font(.system(size: 32))
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(selectedSkinId == skin || (selectedSkinId == nil && skin == "💩") ? Color.white.opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                // Pro skins for free users (locked)
                if !userIsPro {
                    ForEach(["🌈💩", "✨💩", "👑💩"], id: \.self) { skin in
                        Button(action: onProSkinTapped) {
                            ZStack {
                                Text(skin)
                                    .font(.system(size: 32))
                                    .frame(width: 60, height: 60)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.yellow, lineWidth: 2)
                                    )
                                
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                    .offset(x: 15, y: -15)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct CaptionInputView: View {
    @Binding var caption: String
    let userIsPro: Bool
    let freeCharLimit: Int
    let proWordLimit: Int
    let limitText: String
    let isAtLimit: Bool
    let onLimitReached: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Caption")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(limitText)
                    .font(.caption)
                    .foregroundColor(isAtLimit ? .red : .white.opacity(0.6))
            }
            
            if userIsPro {
                TextEditor(text: $caption)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .onChange(of: caption) { newValue in
                        if newValue.wordCount > proWordLimit {
                            caption = newValue.truncatedToWordLimit(proWordLimit)
                        }
                    }
            } else {
                TextField("What's happening? (50 chars max)", text: $caption, axis: .vertical)
                    .lineLimit(3)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .onChange(of: caption) { newValue in
                        if newValue.count > freeCharLimit {
                            caption = String(newValue.prefix(freeCharLimit))
                            onLimitReached()
                        }
                    }
            }
        }
    }
}

struct ProFeaturesTeaser: View {
    let onUpgrade: () -> Void
    
    var body: some View {
        Button(action: onUpgrade) {
            VStack(spacing: 8) {
                HStack {
                    Text("🚀 Upgrade to Pro")
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                    Text("$3.99/mo")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                }
                
                Text("• 200-word captions • Premium skins • All emojis • Exclusive themes")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.yellow, Color.orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }
}

struct PoopTypeSelector: View {
    @Binding var isNoPoop: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's happening?")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                // Regular poop option
                Button(action: {
                    isNoPoop = false
                }) {
                    VStack(spacing: 8) {
                        Text("💩")
                            .font(.system(size: 40))
                        
                        Text("I Pooped!")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(!isNoPoop ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(!isNoPoop ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
                            )
                    )
                }
                
                // No poop option
                Button(action: {
                    isNoPoop = true
                }) {
                    VStack(spacing: 8) {
                        Text("😵‍💫")
                            .font(.system(size: 40))
                        
                        Text("No Poop")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isNoPoop ? Color.white.opacity(0.2) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isNoPoop ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
                            )
                    )
                }
            }
            
            if isNoPoop {
                Text("Keep your streak alive even when nature doesn't call! 🔥")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct DropButton: View {
    let canDrop: Bool
    let isDropping: Bool
    let isNoPoop: Bool
    let action: () -> Void
    
    var buttonText: String {
        if isDropping {
            return isNoPoop ? "Recording..." : "Dropping..."
        } else {
            return isNoPoop ? "Record No Poop" : "Drop It!"
        }
    }
    
    var buttonEmoji: String {
        return isNoPoop ? "😵‍💫" : "💩"
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isDropping {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.black)
                    Text(buttonText)
                } else {
                    Text(buttonEmoji)
                        .font(.title2)
                    Text(buttonText)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canDrop ? Color.white : Color.gray)
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
        .disabled(!canDrop)
    }
}


// MARK: - Music Data Model
struct MusicData {
    let title: String
    let artist: String
    let url: String
    let coverArtURL: String?
}

// MARK: - iTunes API Response
struct ITunesResponse: Codable {
    let results: [ITunesTrack]
    let resultCount: Int
}

struct ITunesTrack: Codable {
    // Required fields with defaults for when they might be missing
    let trackName: String
    let artistName: String
    let artworkUrl100: String
    
    // Optional fields
    let trackViewUrl: String?
    let collectionViewUrl: String?
    let previewUrl: String?
    let collectionName: String?
    let primaryGenreName: String?
    let releaseDate: String?
    
    // Handle missing fields with coding keys
    enum CodingKeys: String, CodingKey {
        case trackName, artistName, artworkUrl100, trackViewUrl, collectionViewUrl, 
             previewUrl, collectionName, primaryGenreName, releaseDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle missing trackName (might be an album)
        if let name = try? container.decode(String.self, forKey: .trackName) {
            trackName = name
        } else if let name = try? container.decode(String.self, forKey: .collectionName) {
            trackName = name
        } else {
            trackName = "Unknown Track"
        }
        
        // Required fields with fallbacks
        artistName = try container.decodeIfPresent(String.self, forKey: .artistName) ?? "Unknown Artist"
        artworkUrl100 = try container.decodeIfPresent(String.self, forKey: .artworkUrl100) ?? ""
        
        // Optional fields
        trackViewUrl = try container.decodeIfPresent(String.self, forKey: .trackViewUrl)
        collectionViewUrl = try container.decodeIfPresent(String.self, forKey: .collectionViewUrl)
        previewUrl = try container.decodeIfPresent(String.self, forKey: .previewUrl)
        collectionName = try container.decodeIfPresent(String.self, forKey: .collectionName)
        primaryGenreName = try container.decodeIfPresent(String.self, forKey: .primaryGenreName)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
    }
}

// MARK: - Spotify oEmbed Response
struct SpotifyOEmbedResponse: Codable {
    let title: String
    let thumbnail_url: String?
    let html: String?
    let provider_name: String?
    let width: Int?
    let height: Int?
}

// MARK: - Poop Rating Slider
struct PoopRatingSlider: View {
    @Binding var rating: Double
    @State private var sliderOffset: CGFloat = 0
    
    // Poop emoji size increases with rating
    private var poopSize: CGFloat {
        let baseSize: CGFloat = 24
        let maxSize: CGFloat = 40
        let scale = CGFloat(rating) / 10.0
        return baseSize + (maxSize - baseSize) * scale
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rate This Drop")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Custom slider with poop emoji as thumb
                ZStack(alignment: .leading) {
                    // Track background
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Filled track
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: sliderOffset, height: 8)
                        .cornerRadius(4)
                    
                    // Poop emoji thumb
                    Text("💩")
                        .font(.system(size: poopSize))
                        .offset(x: sliderOffset - poopSize/2, y: -poopSize/2)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let width = UIScreen.main.bounds.width - 100 // Approximate slider width
                                    let newOffset = max(0, min(width, value.location.x))
                                    sliderOffset = newOffset
                                    
                                    // Calculate rating based on offset
                                    let percentage = newOffset / width
                                    let newRating = 1 + 9 * percentage
                                    rating = min(10, max(1, newRating))
                                }
                        )
                }
                .frame(height: 40)
                .padding(.horizontal, 10)
                .onAppear {
                    // Initialize slider position based on rating
                    let width = UIScreen.main.bounds.width - 100
                    sliderOffset = width * (CGFloat(rating) - 1) / 9
                }
                
                // Rating display
                Text("\(Int(rating))/10")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Music Link Input
struct MusicLinkInput: View {
    @Binding var musicLink: String
    @Binding var musicData: MusicData?
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎵 What are you listening to while pooping?")
                .font(.headline)
                    .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "music.note.list")
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Paste Apple Music or Spotify link", text: $musicLink)
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: musicLink) { oldValue, newValue in
                            if !newValue.isEmpty && (newValue.contains("music.apple") || newValue.contains("spotify")) {
                                parseMusicLink(newValue)
                            } else if newValue.isEmpty {
                                musicData = nil
                                errorMessage = nil
                            }
                        }
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else if musicLink.isEmpty {
                        Button(action: {
                            UIPasteboard.general.string.map { pasteboardContent in
                                if pasteboardContent.contains("music.apple.com") || pasteboardContent.contains("spotify.com") {
                                    musicLink = pasteboardContent
                                    parseMusicLink(pasteboardContent)
                                }
                            }
                        }) {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    } else {
                        Button(action: {
                            musicLink = ""
                            musicData = nil
                            errorMessage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red.opacity(0.8))
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .padding(.horizontal, 8)
                }
                
                if isLoading && errorMessage == nil {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Fetching song details...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 8)
                }
                
                if let music = musicData {
                    HStack(spacing: 12) {
                        if let coverURL = music.coverArtURL, let url = URL(string: coverURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            ProgressView()
                                                .scaleEffect(0.6)
                                        )
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Image(systemName: "music.note")
                .font(.title2)
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(width: 50, height: 50)
                                        .background(Color.gray.opacity(0.3))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                        } else {
                            Image(systemName: "music.note")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(8)
                        }
            
            VStack(alignment: .leading, spacing: 4) {
                            Text(music.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                    .foregroundColor(.white)
                                .lineLimit(1)
                
                            Text(music.artist)
                                .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                                
                            // Source indicator
                            HStack(spacing: 4) {
                                if music.url.contains("apple.com") {
                                    Image(systemName: "applelogo")
                                        .font(.caption2)
                                } else if music.url.contains("spotify.com") {
                                    Text("Spotify")
                                        .font(.caption2)
                                }
                                Text("Music")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
                        
                        Button(action: {
                            if let url = URL(string: music.url) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func parseMusicLink(_ link: String) {
        isLoading = true
        errorMessage = nil
        
        // Check if it's Apple Music or Spotify
        if link.contains("music.apple.com") {
            parseAppleMusic(link)
        } else if link.contains("spotify.com") || link.contains("spotify.link") {
            parseSpotify(link)
        } else {
            errorMessage = "Please paste a valid Apple Music or Spotify link"
            isLoading = false
        }
    }
    
    private func parseAppleMusic(_ link: String) {
        // Extract song ID from URL - handle multiple Apple Music URL formats
        guard let url = URL(string: link) else {
            errorMessage = "Invalid Apple Music link"
            isLoading = false
            return
        }
        
        print("🎵 Parsing Apple Music link: \(link)")
        
        // Try to extract song ID from URL
        var songId: String?
        var albumId: String?
        
        // Method 1: Check for i= parameter in query (song ID)
        if let components = URLComponents(string: link) {
            print("🔍 Query items: \(components.queryItems?.map { "\($0.name)=\($0.value ?? "nil")" } ?? [])")
            if let iParam = components.queryItems?.first(where: { $0.name == "i" })?.value {
                songId = iParam
                print("✅ Found song ID: \(songId!)")
            }
        }
        
        // Method 2: Extract album ID from path (format: /album/name/1234567890)
        print("📂 Path components: \(url.pathComponents)")
        if url.pathComponents.contains("album") {
            // Get the last numeric component (album ID)
            for component in url.pathComponents.reversed() {
                if component.allSatisfy({ $0.isNumber }) && component.count > 5 {
                    albumId = component
                    print("✅ Found album ID: \(albumId!)")
                    break
                }
            }
        }
        
        // Extract country code from URL (e.g., /in/ for India)
        let countryCode = url.pathComponents.first(where: { $0.count == 2 && $0 != "/" }) ?? "us"
        print("🌍 Country code: \(countryCode)")
        
        // If we have a song ID, use it directly (PRIORITY)
        if let songId = songId {
            print("🎯 Using song ID: \(songId)")
            fetchAppleMusicTrack(songId: songId, country: countryCode)
            return
        }
        
        // If we have an album ID, fetch the album and get tracks
        if let albumId = albumId {
            print("🎯 Using album ID: \(albumId)")
            fetchAppleMusicAlbum(albumId: albumId)
            return
        }
        
        // Method 3: Extract song name from URL path and search
        let pathComponents = url.pathComponents.filter { !$0.isEmpty && $0 != "/" && $0 != "album" && !$0.contains("music.apple.com") }
        
        print("📝 Filtered path components: \(pathComponents)")
        
        // Try to find the song name (usually the component before the album ID)
        var songName = ""
        for component in pathComponents {
            // Skip numeric IDs and country codes
            if component.allSatisfy({ $0.isNumber }) || component.count == 2 {
                continue
            }
            // This is likely the song name or album name
            if !component.isEmpty && component.count > 2 {
                songName = component.replacingOccurrences(of: "-", with: " ").capitalized
                print("🔤 Extracted song name: \(songName)")
                break
            }
        }
        
        if !songName.isEmpty {
            print("🔍 Searching for: \(songName)")
            searchAppleMusic(term: songName, entity: "song")
        } else {
            print("❌ Could not extract any useful info")
            errorMessage = "Could not extract song info from Apple Music link"
            isLoading = false
        }
    }
    
    private func fetchAppleMusicAlbum(albumId: String) {
        Task {
            do {
                let apiURL = URL(string: "https://itunes.apple.com/lookup?id=\(albumId)&entity=song&limit=25")!
                let (data, _) = try await URLSession.shared.data(from: apiURL)
                let response = try JSONDecoder().decode(ITunesResponse.self, from: data)
                
                // Get the first actual song (not the album itself)
                if let track = response.results.first(where: { $0.trackName != "Unknown Track" }) {
                    await MainActor.run {
                        musicData = MusicData(
                            title: track.trackName,
                            artist: track.artistName,
                            url: track.trackViewUrl ?? track.collectionViewUrl ?? "",
                            coverArtURL: track.artworkUrl100.replacingOccurrences(of: "100x100", with: "600x600")
                        )
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Could not find track in album"
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to fetch album details"
                    isLoading = false
                }
            }
        }
    }
    
    private func fetchAppleMusicTrack(songId: String, country: String = "us") {
        Task {
            do {
                // Try with the country from URL first, fallback to US
                var apiURL = URL(string: "https://itunes.apple.com/lookup?id=\(songId)&country=\(country)")!
                print("📡 Fetching from: \(apiURL.absoluteString)")
                var (data, _) = try await URLSession.shared.data(from: apiURL)
                var response = try JSONDecoder().decode(ITunesResponse.self, from: data)
                
                print("📦 Got \(response.resultCount) results from \(country)")
                
                // If no results and we tried a specific country, try US as fallback
                if response.resultCount == 0 && country != "us" {
                    print("🔄 No results in \(country), trying US...")
                    apiURL = URL(string: "https://itunes.apple.com/lookup?id=\(songId)&country=us")!
                    (data, _) = try await URLSession.shared.data(from: apiURL)
                    response = try JSONDecoder().decode(ITunesResponse.self, from: data)
                    print("📦 Got \(response.resultCount) results from US")
                }
                
                // If still no results, try without country parameter
                if response.resultCount == 0 {
                    print("🔄 Trying without country parameter...")
                    apiURL = URL(string: "https://itunes.apple.com/lookup?id=\(songId)")!
                    (data, _) = try await URLSession.shared.data(from: apiURL)
                    response = try JSONDecoder().decode(ITunesResponse.self, from: data)
                    print("📦 Got \(response.resultCount) results without country")
                }
                
                if let track = response.results.first {
                    print("✅ Track found: \(track.trackName) by \(track.artistName)")
                    await MainActor.run {
                        musicData = MusicData(
                            title: track.trackName,
                            artist: track.artistName,
                            url: track.trackViewUrl ?? track.collectionViewUrl ?? "",
                            coverArtURL: track.artworkUrl100.replacingOccurrences(of: "100x100", with: "600x600")
                        )
                        isLoading = false
                    }
                } else {
                    print("❌ No tracks found in any region")
                    await MainActor.run {
                        errorMessage = "Song not available in iTunes API"
                        isLoading = false
                    }
                }
            } catch {
                print("❌ Error: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "Failed to fetch song details: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func searchAppleMusic(term: String, entity: String) {
        Task {
            do {
                let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let apiURL = URL(string: "https://itunes.apple.com/search?term=\(encodedTerm)&entity=\(entity)&limit=1")!
                
                let (data, _) = try await URLSession.shared.data(from: apiURL)
                let response = try JSONDecoder().decode(ITunesResponse.self, from: data)
                
                if let track = response.results.first {
                    await MainActor.run {
                        musicData = MusicData(
                            title: track.trackName,
                            artist: track.artistName,
                            url: track.trackViewUrl ?? track.collectionViewUrl ?? "",
                            coverArtURL: track.artworkUrl100.replacingOccurrences(of: "100x100", with: "600x600")
                        )
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "No matching songs found"
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Search failed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func parseSpotify(_ link: String) {
        // Use our dedicated SpotifyAPIClient
        Task {
            do {
                // Get a client credentials token and fetch track info
                let spotifyClient = SpotifyAPIClient.shared
                let musicInfo = try await spotifyClient.parseSpotifyLink(link)
                
                await MainActor.run {
                    self.musicData = musicInfo
                    self.isLoading = false
                }
            } catch {
                // If the API fails, fall back to our oEmbed approach
                await MainActor.run {
                    print("Spotify API error: \(error.localizedDescription)")
                    // Fall back to oEmbed
                    fallbackSpotifyParsing(link)
                }
            }
        }
    }
    
    // Fallback method if the Spotify API fails
    private func fallbackSpotifyParsing(_ link: String) {
        guard let url = URL(string: link) else {
            errorMessage = "Invalid Spotify link"
            isLoading = false
            return
        }
        
        // Handle different Spotify URL formats using oEmbed
        
        // Try to extract track name from URL for fallback
        let trackName = url.lastPathComponent
            .split(separator: "?")
            .first?
            .replacingOccurrences(of: "-", with: " ")
            .capitalized ?? "Spotify Track"
        
        fetchSpotifyOEmbed(url: link, fallbackTitle: trackName)
    }
    
    private func fetchSpotifyOEmbed(url: String, fallbackTitle: String) {
        Task {
            do {
                let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
                let apiURL = URL(string: "https://open.spotify.com/oembed?url=\(encodedURL)")!
                
                let (data, response) = try await URLSession.shared.data(from: apiURL)
                
                // Check if we got a valid response
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NSError(domain: "SpotifyAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }
                
                let oembedResponse = try JSONDecoder().decode(SpotifyOEmbedResponse.self, from: data)
                
                await MainActor.run {
                    // Parse title and artist from "title" field (format: "Song Name · Artist Name")
                    let components = oembedResponse.title.split(separator: "·").map { $0.trimmingCharacters(in: .whitespaces) }
                    let title = components.first ?? oembedResponse.title
                    let artist = components.count > 1 ? components[1] : "Spotify Artist"
                    
                    musicData = MusicData(
                        title: title,
                        artist: artist,
                        url: url,
                        coverArtURL: oembedResponse.thumbnail_url
                    )
                    isLoading = false
                }
            } catch {
                print("Spotify oEmbed error: \(error.localizedDescription)")
                
                // Last resort fallback
                await MainActor.run {
                    musicData = MusicData(
                        title: fallbackTitle,
                        artist: "Spotify Artist",
                        url: url,
                        coverArtURL: "https://i.scdn.co/image/ab67616d0000b273b5551c9e9bee25baa55ef5a3" // Generic Spotify logo
                    )
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    DropComposerView()
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(CloudKitManager())
        .environmentObject(LocationManager())
}
