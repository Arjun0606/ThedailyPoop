import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    // Subscription removed
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @State private var showingSettings = false
    // Pro removed
    @State private var showingSubscriptionManagement = false
    
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
                            StatsSection(user: user)
                            
                            // Pro removed
                            
                            // Achievements section
                            AchievementsSection(user: user)
                            
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Stats")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Top row stats
            HStack(spacing: 16) {
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
            }
            
            // Second row stats
            HStack(spacing: 16) {
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
            }
            
            // Friends-only app: remove global/city ranks
        }
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

struct ProUpsellSection: View {
    let onUpgrade: () -> Void
    
    var body: some View {
        Button(action: onUpgrade) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("🚀")
                                .font(.title2)
                            
                            Text("Upgrade to Pro")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text("Unlock all premium features and become the ultimate poop dropper!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("$3.99")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        
                        Text("per month")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                HStack(spacing: 8) {
                    Text("📝 200 words")
                    Text("🎨 All skins")
                    Text("😀 All emojis")
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.4), lineWidth: 1)
            )
            .cornerRadius(16)
        }
    }
}

struct AchievementsSection: View {
    let user: User
    
    private let achievements = [
        Achievement(id: "first_drop", title: "First Drop", description: "Dropped your first poop", icon: "💩", isUnlocked: true),
        Achievement(id: "streak_7", title: "Week Warrior", description: "7-day streak", icon: "🔥", isUnlocked: true),
        Achievement(id: "drops_50", title: "Half Century", description: "50 total drops", icon: "🏆", isUnlocked: false),
        Achievement(id: "pro_user", title: "Pro Dropper", description: "Upgraded to Pro", icon: "👑", isUnlocked: false)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
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
    }
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
            Button("Delete", role: .destructive) {
                Task {
                    guard let user = authManager.currentUser else { return }
                    try? await CloudKitManager.shared.deleteAccount(for: user)
                    await MainActor.run {
                        authManager.signOut()
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This will permanently delete your account and data.")
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

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(CloudKitManager())
}
