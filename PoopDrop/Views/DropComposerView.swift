import SwiftUI
import CoreLocation

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
            Text("Poop Drop needs location access to drop poops. Please enable location access in Settings.")
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

// MARK: - Poop Rating Slider
struct PoopRatingSlider: View {
    @Binding var rating: Double
    
    var ratingDescription: String {
        switch Int(rating) {
        case 1: return "Regret Incarnate"
        case 2: return "Houston, We Have a Problem"
        case 3: return "Meh, Could Be Worse"
        case 4: return "Just Another Day"
        case 5: return "Not Bad, Not Bad"
        case 6: return "Chef's Kiss"
        case 7: return "Heavenly Relief"
        case 8: return "Absolute Euphoria"
        case 9: return "Life-Changing Experience"
        case 10: return "Transcendent Bliss"
        default: return "Not Bad, Not Bad"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rate This Drop")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                HStack {
                    Text("💩")
                        .font(.title)
                    Slider(value: $rating, in: 1...10, step: 1)
                        .accentColor(.orange)
                    Text("\(Int(rating))/10")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .frame(width: 60)
                }
                
                Text(ratingDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange.opacity(0.9))
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
            Text("🎵 Listening To (Optional)")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Paste Apple Music or Spotify link", text: $musicLink)
                        .foregroundColor(.white)
                        .onChange(of: musicLink) { oldValue, newValue in
                            if !newValue.isEmpty {
                                parseMusicLink(newValue)
                            } else {
                                musicData = nil
                                errorMessage = nil
                            }
                        }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                }
                
                if let music = musicData {
                    HStack(spacing: 12) {
                        if let coverURL = music.coverArtURL, let url = URL(string: coverURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                        } else {
                            Image(systemName: "music.note")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 50, height: 50)
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
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
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
        // Extract song ID from URL
        // Format: https://music.apple.com/us/album/song-name/album-id?i=song-id
        guard let url = URL(string: link) else {
            errorMessage = "Invalid Apple Music link"
            isLoading = false
            return
        }
        
        // For now, we'll extract basic info from the URL path
        // In production, you'd use Apple Music API
        let pathComponents = url.pathComponents
        if pathComponents.count >= 3 {
            let songName = pathComponents[3].replacingOccurrences(of: "-", with: " ").capitalized
            musicData = MusicData(
                title: songName,
                artist: "Apple Music",
                url: link,
                coverArtURL: nil
            )
        } else {
            musicData = MusicData(
                title: "Apple Music Track",
                artist: "Unknown Artist",
                url: link,
                coverArtURL: nil
            )
        }
        
        isLoading = false
    }
    
    private func parseSpotify(_ link: String) {
        // Extract track ID from URL
        // Format: https://open.spotify.com/track/track-id or https://spotify.link/xxxxx
        guard let url = URL(string: link) else {
            errorMessage = "Invalid Spotify link"
            isLoading = false
            return
        }
        
        // For now, we'll extract basic info from the URL
        // In production, you'd use Spotify API
        if url.pathComponents.contains("track") {
            let trackIndex = url.pathComponents.firstIndex(of: "track") ?? 0
            if trackIndex + 1 < url.pathComponents.count {
                let trackName = url.pathComponents[trackIndex + 1].replacingOccurrences(of: "-", with: " ").capitalized
                musicData = MusicData(
                    title: trackName,
                    artist: "Spotify",
                    url: link,
                    coverArtURL: nil
                )
            }
        } else {
            musicData = MusicData(
                title: "Spotify Track",
                artist: "Unknown Artist",
                url: link,
                coverArtURL: nil
            )
        }
        
        isLoading = false
    }
}

#Preview {
    DropComposerView()
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(CloudKitManager())
        .environmentObject(LocationManager())
}
