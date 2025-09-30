import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    // Subscription removed
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @State private var showingSettings = false
    // Pro removed
    @State private var showingSubscriptionManagement = false
    @State private var refreshTrigger = false
    
    var user: User? {
        authManager.currentUser
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let user = user {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile header
                            ProfileHeaderView(user: user)
                            
                            // Stats section (friends-only; remove global/city ranks)
                            StatsSection(user: user, refreshTrigger: refreshTrigger)
                            
                            // Pro removed
                            
                            // Achievements section
                            AchievementsSection(user: user, refreshTrigger: refreshTrigger)
                            
                            // Settings section
                            SettingsSection(
                                onSettingsTap: {
                                    showingSettings = true
                                },
                                onSubscriptionTap: {},
                                onSignOut: {
                                    authManager.signOut()
                                }
                            )
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                } else {
                    // Loading state
                    ProgressView()
                        .scaleEffect(1.2)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("USER_STATS_UPDATED"))) { _ in
            print("📊 Profile refreshing stats after drop")
            // Force refresh by toggling a state variable
            refreshTrigger.toggle()
        }
        // Pro removed
        // Pro upsell removed - simplified ad-supported model
        // .sheet(isPresented: $showingProUpsell) {
        //     ProUpsellView()
        // }
        // Subscription removed
    }
}

struct ProfileHeaderView: View {
    let user: User
    // Subscription removed
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile picture (avatar if available; otherwise initial)
            if let url = user.avatarURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                    .onTapGesture {
                        // Full-screen preview
                        presentImageFullScreen(image)
                    }
            } else {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brown.opacity(0.7), Color.brown],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    Text(String(user.username.prefix(1)).uppercased())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                }
            }
            
            // User info
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(user.username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Pro removed
                }
                
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    Text("Location Private")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                }
                
                Text("Member since \(formatDate(user.createdAt))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func presentImageFullScreen(_ image: UIImage) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let vc = UIViewController()
        vc.view.backgroundColor = .black
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = vc.view.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.addSubview(imageView)
        let close = UIButton(type: .close)
        close.tintColor = .white
        close.frame = CGRect(x: 20, y: 50, width: 44, height: 44)
        close.addAction(UIAction { _ in vc.dismiss(animated: true) }, for: .touchUpInside)
        vc.view.addSubview(close)
        root.present(vc, animated: true)
    }
}

struct StatsSection: View {
    let user: User
    let refreshTrigger: Bool
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
            Text("Your Stats")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
                Spacer()
                
                Button(action: {
                    showingShareSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                        Text("Share")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
            }
            
            // Horizontal scrollable grid of ALL stats
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                StatCard(
                    icon: "💩",
                    title: "Total Drops",
                    value: "\(user.totalDrops)",
                    color: .brown
                )
                
                StatCard(
                    icon: "🔥",
                    title: "Current Streak",
                    value: "\(user.streak)",
                    color: .orange
                )
            
                StatCard(
                    icon: "📈",
                    title: "Max Dumps/Day",
                    value: "\(user.maxDropsInDay)",
                    color: .green
                )
                
                StatCard(
                    icon: "😵‍💫",
                    title: "Longest No-Poop",
                    value: "\(user.longestNoPoopStreak) days",
                    color: .purple
                )
            
                StatCard(
                        icon: "🌍",
                        title: "Countries",
                        value: "\(user.countriesVisited.count)",
                        color: .blue
                )
                
                StatCard(
                        icon: "🌎",
                        title: "Continents",
                        value: "\(user.continentsVisited.count)",
                        color: .indigo
                    )
                    
                    StatCard(
                        icon: "👥",
                        title: "Friends",
                        value: "\(user.friends.count)",
                        color: .pink
                    )
                    
                    StatCard(
                        icon: "📅",
                        title: "Member Since",
                        value: memberDays,
                        color: .cyan
                    )
                }
                .padding(.horizontal, 4)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareStatsView(user: user)
        }
    }
    
    private var memberDays: String {
        let days = Calendar.current.dateComponents([.day], from: user.createdAt, to: Date()).day ?? 0
        return "\(days) days"
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title2)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
}

struct ProStatusSection: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("👑 Pro Status")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("ACTIVE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(6)
            }
            
            VStack(spacing: 12) {
                ProFeatureItem(icon: "📝", text: "200-word captions")
                ProFeatureItem(icon: "🎨", text: "Premium poop skins")
                ProFeatureItem(icon: "😀", text: "All emoji reactions")
                ProFeatureItem(icon: "🎵", text: "Sound effects")
                ProFeatureItem(icon: "🗺️", text: "Exclusive map themes")
                ProFeatureItem(icon: "✨", text: "Animations & effects")
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

struct ProFeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.body)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.subheadline)
        }
    }
}


struct AchievementsSection: View {
    let user: User
    let refreshTrigger: Bool
    
    private var achievements: [Achievement] {
        // Compute from real user stats; no dummy unlocks
        [
            // Basic Progress Badges
            Achievement(id: "first_drop", title: "First Drop", description: "Dropped your first poop", icon: "💩", isUnlocked: user.totalDrops >= 1),
            Achievement(id: "drops_10", title: "Getting Warm", description: "10 total drops", icon: "🥉", isUnlocked: user.totalDrops >= 10),
            Achievement(id: "drops_50", title: "Half Century", description: "50 total drops", icon: "🏆", isUnlocked: user.totalDrops >= 50),
            Achievement(id: "drops_100", title: "Centurion", description: "100 total drops", icon: "👑", isUnlocked: user.totalDrops >= 100),
            Achievement(id: "drops_500", title: "Poop Legend", description: "500 total drops", icon: "🌟", isUnlocked: user.totalDrops >= 500),
            
            // Streak Badges
            Achievement(id: "streak_3", title: "Getting Regular", description: "3-day streak", icon: "📅", isUnlocked: user.streak >= 3),
            Achievement(id: "streak_7", title: "Week Warrior", description: "7-day streak", icon: "🔥", isUnlocked: user.streak >= 7),
            Achievement(id: "streak_30", title: "Monthly Master", description: "30-day streak", icon: "🗓️", isUnlocked: user.streak >= 30),
            Achievement(id: "streak_100", title: "Unstoppable", description: "100-day streak", icon: "⚡", isUnlocked: user.streak >= 100),
            
            // Travel Badges
            Achievement(id: "countries_2", title: "Border Crosser", description: "Pooped in 2 countries", icon: "🌍", isUnlocked: user.countriesVisited.count >= 2),
            Achievement(id: "countries_5", title: "Jet Setter", description: "Pooped in 5 countries", icon: "✈️", isUnlocked: user.countriesVisited.count >= 5),
            Achievement(id: "countries_10", title: "Globe Trotter", description: "Pooped in 10 countries", icon: "🌎", isUnlocked: user.countriesVisited.count >= 10),
            Achievement(id: "continents_2", title: "Continental", description: "Pooped on 2 continents", icon: "🌏", isUnlocked: user.continentsVisited.count >= 2),
            Achievement(id: "continents_5", title: "World Pooper", description: "Pooped on 5+ continents", icon: "🌐", isUnlocked: user.continentsVisited.count >= 5),
            
            // Timing Badges
            Achievement(id: "early_bird", title: "Early Bird", description: "Dropped before 6 AM", icon: "🌅", isUnlocked: false),
            Achievement(id: "night_owl", title: "Night Owl", description: "Dropped after midnight", icon: "🦉", isUnlocked: false),
            Achievement(id: "lunch_break", title: "Lunch Break", description: "Dropped during lunch (12-2 PM)", icon: "🍽️", isUnlocked: false),
            
            // Daily Performance Badges
            Achievement(id: "daily_3", title: "Triple Threat", description: "3 drops in one day", icon: "🎯", isUnlocked: user.maxDropsInDay >= 3),
            Achievement(id: "daily_5", title: "Power User", description: "5 drops in one day", icon: "💪", isUnlocked: user.maxDropsInDay >= 5),
            
            // Constipation/No-Poop Badges
            Achievement(id: "no_poop_3", title: "Desert Days", description: "3 days no poop", icon: "😵‍💫", isUnlocked: user.longestNoPoopStreak >= 3),
            Achievement(id: "no_poop_7", title: "Constipation Station", description: "7 days no poop", icon: "🚂", isUnlocked: user.longestNoPoopStreak >= 7),
            
            // Social Badges (need to implement friend interactions)
            Achievement(id: "friends_5", title: "Social Pooper", description: "Added 5 friends", icon: "👥", isUnlocked: user.friends.count >= 5),
            Achievement(id: "friends_20", title: "Popular Pooper", description: "Added 20 friends", icon: "🎉", isUnlocked: user.friends.count >= 20),
            
            // Special/Fun Badges
            Achievement(id: "weekend_warrior", title: "Weekend Warrior", description: "Dropped on weekend", icon: "🏖️", isUnlocked: false),
            Achievement(id: "holiday_pooper", title: "Holiday Pooper", description: "Dropped on a holiday", icon: "🎄", isUnlocked: false),
            Achievement(id: "birthday_drop", title: "Birthday Drop", description: "Dropped on your birthday", icon: "🎂", isUnlocked: false)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                            .frame(width: 220)
                    }
                }
            }
        }
    }
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
}

struct AchievementCard: View {
    let achievement: Achievement
    @State private var showingShare = false
    
    private var shareText: String {
        "I just unlocked ‘\(achievement.title)’ on PoopDrop! 💩 #PoopDrop"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(achievement.icon)
                .font(.title2)
                .opacity(achievement.isUnlocked ? 1.0 : 0.3)
            
            Text(achievement.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.5))
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.isUnlocked ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(achievement.isUnlocked ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
                )
        )
        .contextMenu {
            if achievement.isUnlocked {
                Button("Share") { showingShare = true }
            }
        }
        .sheet(isPresented: $showingShare) {
            ActivityViewController(activityItems: [shareText])
        }
    }
}

// UIKit share sheet wrapper
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SettingsSection: View {
    let onSettingsTap: () -> Void
    let onSubscriptionTap: () -> Void
    let onSignOut: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SettingsRow(
                icon: "gearshape.fill",
                title: "Settings",
                action: onSettingsTap
            )
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Subscription removed
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            SettingsRow(
                icon: "rectangle.portrait.and.arrow.right",
                title: "Sign Out",
                action: onSignOut,
                isDestructive: true
            )
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    let isDestructive: Bool
    
    init(icon: String, title: String, action: @escaping () -> Void, isDestructive: Bool = false) {
        self.icon = icon
        self.title = title
        self.action = action
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(isDestructive ? .red : .white.opacity(0.8))
                    .font(.body)
                    .frame(width: 20)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(isDestructive ? .red : .white)
                
                Spacer()
                
                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.caption)
                }
            }
            .padding()
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var confirmingDelete = false
    @State private var streakReminderEnabled = UserDefaults.standard.bool(forKey: "streakReminderEnabled")
    @State private var reminderTime = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                List {
                    Section(header: Text("Notifications").foregroundColor(.white)) {
                        Button("Open System Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }.foregroundColor(.white)
                    }
                    
                    Section(header: Text("Streak Reminders").foregroundColor(.white)) {
                        Toggle("Daily Reminder", isOn: $streakReminderEnabled)
                            .foregroundColor(.white)
                            .onChange(of: streakReminderEnabled) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "streakReminderEnabled")
                                Task {
                                    if newValue, let user = authManager.currentUser {
                                        let calendar = Calendar.current
                                        let hour = calendar.component(.hour, from: reminderTime)
                                        let minute = calendar.component(.minute, from: reminderTime)
                                        await NotificationManager.shared.scheduleDailyStreakReminder(for: user, hour: hour, minute: minute)
                                    } else if let user = authManager.currentUser {
                                        await NotificationManager.shared.cancelDailyStreakReminder(for: user)
                                    }
                                }
                            }
                        
                        if streakReminderEnabled {
                            DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .foregroundColor(.white)
                                .onChange(of: reminderTime) { _, newValue in
                                    Task {
                                        if let user = authManager.currentUser {
                                            let calendar = Calendar.current
                                            let hour = calendar.component(.hour, from: newValue)
                                            let minute = calendar.component(.minute, from: newValue)
                                            await NotificationManager.shared.scheduleDailyStreakReminder(for: user, hour: hour, minute: minute)
                                        }
                                    }
                                }
                        }
                    }
                    Section(header: Text("Profile").foregroundColor(.white)) {
                        NavigationLink("Edit Profile") {
                            EditProfileView()
                        }
                        .foregroundColor(.white)
                    }
                    Section(header: Text("Legal").foregroundColor(.white)) {
                        Button("Terms of Service") {
                            if let url = URL(string: "https://poopdrop.app/terms") { UIApplication.shared.open(url) }
                        }.foregroundColor(.white)
                        Button("Privacy Policy") {
                            if let url = URL(string: "https://poopdrop.app/privacy") { UIApplication.shared.open(url) }
                        }.foregroundColor(.white)
                    }
                    Section {
                        Button(role: .destructive) {
                            confirmingDelete = true
                        } label: {
                            Text("Delete Account")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
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
        .alert("Delete Account?", isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Forever", role: .destructive) {
                Task {
                    guard let user = authManager.currentUser else { return }
                    
                    print("🗑️ Starting account deletion for user: \(user.username)")
                    
                    do {
                        // Delete all CloudKit data
                        try await CloudKitManager.shared.deleteAccount(for: user)
                        print("✅ CloudKit data deleted successfully")
                    } catch {
                        print("⚠️ CloudKit deletion failed: \(error), but continuing with local cleanup")
                    }
                    
                    await MainActor.run {
                        // Clear all local data and sign out
                        authManager.signOut()
                        dismiss()
                        print("✅ Account deletion completed")
                    }
                }
            }
        } message: {
            Text("This will permanently delete your account, drops, reactions, and all data. This cannot be undone.")
        }
    }
}

// MARK: - Edit Profile
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var username: String = ""
    @State private var checking = false
    @State private var available: Bool = true
    @State private var showingEditor = false
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        Form {
            Section(header: Text("Username")) {
                HStack {
                    TextField("username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: username) { _ in debounceCheck() }
                    if checking { ProgressView() }
                    Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(available ? .green : .red)
                }
            }
            Section(header: Text("Profile Photo")) {
                HStack {
                    if let img = selectedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                    Button("Change Photo") { showingEditor = true }
                }
            }
            Section {
                Button("Save") { Task { await saveProfile() } }
                    .disabled(!available || username.isEmpty)
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear { if let u = authManager.currentUser { username = u.username } }
        .sheet(isPresented: $showingEditor) {
            ProfilePictureEditor(selectedImage: $selectedImage, isPresented: $showingEditor) { _ in }
        }
    }
    
    private func debounceCheck() {
        checking = true
        available = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            Task { await checkUsername() }
        }
    }
    
    private func checkUsername() async {
        do {
            let ok = try await CloudKitManager.shared.isUsernameAvailable(username)
            await MainActor.run { available = ok; checking = false }
        } catch {
            await MainActor.run { available = false; checking = false }
        }
    }
    
    private func saveProfile() async {
        guard var user = authManager.currentUser else { return }
        user.username = username
        if let img = selectedImage, let data = img.pngData() {
            let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("avatar_\(UUID().uuidString).png")
            try? data.write(to: tmp)
            user.avatarURL = tmp
        }
        do {
            try await CloudKitManager.shared.saveUser(user)
            await MainActor.run {
                authManager.currentUser = user
                dismiss()
            }
        } catch { }
    }
}

struct SubscriptionManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if subscriptionManager.isProSubscriber {
                            // Active subscription
                            VStack(spacing: 16) {
                                Text("👑")
                                    .font(.system(size: 60))
                                
                                Text("Pro Subscription Active")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("You have access to all premium features")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(16)
                            
                            Button("Restore Purchases") {
                                Task {
                                    await subscriptionManager.restorePurchases()
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            
                        } else {
                            // No active subscription
                            VStack(spacing: 16) {
                                Text("💩")
                                    .font(.system(size: 60))
                                
                                Text("Free Plan")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Upgrade to Pro to unlock all features")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Subscription")
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

// MARK: - Share Stats View
struct ShareStatsView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if let image = shareImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(20)
                            .padding()
                    } else {
                        // Preview of what will be shared
                        ShareStatsCard(user: user)
                            .padding()
                    }
                    
                    Button(action: {
                        shareStats()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share to Socials")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Share Your Stats")
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
        .onAppear {
            generateShareImage()
        }
    }
    
    private func generateShareImage() {
        let cardView = ShareStatsCard(user: user)
        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 3.0
        shareImage = renderer.uiImage
    }
    
    private func shareStats() {
        guard let image = shareImage else { return }
        
        let text = "I've dropped 💩 \(user.totalDrops) times in \(user.countriesVisited.count) countries on PoopDrop! 🔥\nJoin me: https://poopdrop.app"
        
        let activityVC = UIActivityViewController(activityItems: [text, image], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = root.view
            root.present(activityVC, animated: true)
        }
    }
}

struct ShareStatsCard: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("💩")
                    .font(.system(size: 60))
                
                Text("PoopDrop")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Stats Grid
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ShareStatItem(icon: "💩", value: "\(user.totalDrops)", label: "Total Drops")
                    ShareStatItem(icon: "🔥", value: "\(user.streak)", label: "Day Streak")
                }
                
                HStack(spacing: 16) {
                    ShareStatItem(icon: "🌍", value: "\(user.countriesVisited.count)", label: "Countries")
                    ShareStatItem(icon: "📈", value: "\(user.maxDropsInDay)", label: "Max/Day")
                }
            }
            
            // Footer
            VStack(spacing: 8) {
                Text("Join me on PoopDrop!")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("poopdrop.app")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
            }
        }
        .padding(32)
        .frame(width: 400, height: 500)
        .background(
            LinearGradient(
                colors: [Color.brown.opacity(0.8), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
    }
}

struct ShareStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.largeTitle)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(CloudKitManager())
}
