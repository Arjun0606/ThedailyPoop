import SwiftUI
import CoreLocation

struct DropComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var friendsManager: FriendsManager
    
    @State private var caption: String = ""
    @State private var selectedSkinId: String? = nil
    @State private var isDropping = false
    @State private var showingProUpsell = false
    @State private var showingLocationError = false
    @State private var currentLocation: CLLocation?
    @State private var isNoPoop = false // Toggle for "no poop" option
    
    private let freeCharLimit = 50
    private let proWordLimit = 200
    
    // Available skins
    private let freeSkins = ["💩"] // Default poop
    private let proSkins = ["🌈💩", "✨💩", "👑💩", "🔥💩", "❄️💩", "🎃💩", "🌮💩"]
    
    var userIsPro: Bool {
        subscriptionManager.isProSubscriber
    }
    
    var availableSkins: [String] {
        userIsPro ? freeSkins + proSkins : freeSkins
    }
    
    var captionLimitText: String {
        if userIsPro {
            return "\(caption.wordCount)/\(proWordLimit) words"
        } else {
            return "\(caption.count)/\(freeCharLimit) chars"
        }
    }
    
    var isAtLimit: Bool {
        if userIsPro {
            return caption.wordCount >= proWordLimit
        } else {
            return caption.count >= freeCharLimit
        }
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
                        
                        // Skin selector (only for regular poops)
                        if !isNoPoop {
                            SkinSelectorView(
                                selectedSkinId: $selectedSkinId,
                                availableSkins: availableSkins,
                                userIsPro: userIsPro,
                                onProSkinTapped: {
                                    showingProUpsell = true
                                }
                            )
                        }
                        
                        // Caption input
                        CaptionInputView(
                            caption: $caption,
                            userIsPro: userIsPro,
                            freeCharLimit: freeCharLimit,
                            proWordLimit: proWordLimit,
                            limitText: captionLimitText,
                            isAtLimit: isAtLimit,
                            onLimitReached: {
                                if !userIsPro {
                                    showingProUpsell = true
                                }
                            }
                        )
                        
                        // Pro features teaser for free users
                        if !userIsPro {
                            ProFeaturesTeaser {
                                showingProUpsell = true
                            }
                        }
                        
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
        .sheet(isPresented: $showingProUpsell) {
            ProUpsellView()
        }
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
        
        let drop = Drop(
            userID: user.id,
            username: user.username,
            location: isNoPoop ? nil : currentLocation?.coordinate,
            skinId: isNoPoop ? nil : selectedSkinId,
            caption: finalCaption.isEmpty ? nil : finalCaption,
            isNoPoop: isNoPoop,
            isSponsored: false
        )
        
        Task {
            do {
                try await cloudKitManager.saveDrop(drop)
                
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
                
                // Check for badge eligibility
                let badgeManager = BadgeManager()
                let userDrops = try await cloudKitManager.fetchUserDrops(for: user)
                await badgeManager.checkBadgeEligibility(for: user, drops: userDrops)
                
                await MainActor.run {
                    isDropping = false
                    dismiss()
                }
                
                // Update user's streak and total drops
                await updateUserStats()
                
            } catch {
                await MainActor.run {
                    isDropping = false
                    // Show error
                }
            }
        }
    }
    
    private func updateUserStats() async {
        guard var user = authManager.currentUser else { return }
        
        // Update total drops
        user.totalDrops += 1
        
        // Calculate drops today for max tracking
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        do {
            let userDrops = try await cloudKitManager.fetchUserDrops(for: user)
            let todayDrops = userDrops.filter { 
                calendar.isDate($0.timestamp, inSameDayAs: today) && !$0.isNoPoop
            }.count + 1 // +1 for current drop
            
            // Update max drops in day
            if todayDrops > user.maxDropsInDay {
                user.maxDropsInDay = todayDrops
            }
            
            // Calculate longest no-poop streak
            calculateLongestNoPoopStreak(userDrops: userDrops, user: &user)
            
        } catch {
            print("Failed to fetch user drops for stats: \(error)")
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
        
        do {
            try await cloudKitManager.saveUser(user)
            await MainActor.run {
                authManager.currentUser = user
            }
        } catch {
            print("Failed to update user stats: \(error)")
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

struct ProUpsellView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Text("👑")
                                .font(.system(size: 80))
                            
                            Text("Upgrade to Poop Drop Pro")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Unlock premium features and become the ultimate poop dropper!")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Features list
                        VStack(spacing: 16) {
                            ProFeatureRow(icon: "📝", title: "200-Word Captions", description: "Express yourself with longer, detailed captions")
                            ProFeatureRow(icon: "🎨", title: "Premium Poop Skins", description: "Rainbow, disco, gold, and seasonal skins")
                            ProFeatureRow(icon: "😀", title: "All Emoji Reactions", description: "React with any emoji, plus custom packs")
                            ProFeatureRow(icon: "🎵", title: "Sound Effects", description: "Fart packs, flush sounds, and more")
                            ProFeatureRow(icon: "🗺️", title: "Exclusive Map Themes", description: "Dark luxury, cosmic galaxy themes")
                            ProFeatureRow(icon: "✨", title: "Animations", description: "Bounce, sparkle, flush animations")
                            ProFeatureRow(icon: "🏆", title: "Profile Flex", description: "Poop crown, golden toilet badge")
                        }
                        
                        // Pricing
                        if let product = subscriptionManager.availableProducts.first {
                            VStack(spacing: 16) {
                                Text("Only \(product.displayPrice)/month")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.yellow)
                                
                                Button(action: {
                                    Task {
                                        try? await subscriptionManager.purchase(product)
                                        dismiss()
                                    }
                                }) {
                                    Text("Start Pro Subscription")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.yellow)
                                        .cornerRadius(12)
                                }
                                .disabled(subscriptionManager.isLoading)
                                
                                if subscriptionManager.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        
                        // Fine print
                        Text("Cancel anytime. Subscription automatically renews.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
}

#Preview {
    DropComposerView()
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(CloudKitManager())
        .environmentObject(LocationManager())
}
