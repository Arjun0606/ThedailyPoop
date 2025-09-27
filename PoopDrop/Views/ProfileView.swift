import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @State private var showingSettings = false
    @State private var showingProUpsell = false
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
                            
                            // Stats section
                            StatsSection(user: user)
                            
                            // Pro status section
                            if subscriptionManager.isProSubscriber {
                                ProStatusSection()
                            } else {
                                ProUpsellSection {
                                    showingProUpsell = true
                                }
                            }
                            
                            // Achievements section
                            AchievementsSection(user: user)
                            
                            // Settings section
                            SettingsSection(
                                onSettingsTap: {
                                    showingSettings = true
                                },
                                onSubscriptionTap: {
                                    showingSubscriptionManagement = true
                                },
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
        .sheet(isPresented: $showingProUpsell) {
            ProUpsellView()
        }
        .sheet(isPresented: $showingSubscriptionManagement) {
            SubscriptionManagementView()
        }
    }
}

struct ProfileHeaderView: View {
    let user: User
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile picture
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
                
                Text(String(user.displayName.prefix(1)).uppercased())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Pro crown overlay
                if subscriptionManager.isProSubscriber {
                    VStack {
                        Text("👑")
                            .font(.title2)
                            .offset(y: -45)
                        Spacer()
                    }
                }
            }
            
            // User info
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(user.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if subscriptionManager.isProSubscriber {
                        Text("PRO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.yellow)
                            .cornerRadius(6)
                    }
                }
                
                if let city = user.city {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(city)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
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
}

struct StatsSection: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Stats")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
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
            
            HStack(spacing: 16) {
                StatCard(
                    icon: "🏆",
                    title: "Global Rank",
                    value: "#\(Int.random(in: 15...100))",
                    color: .yellow
                )
                
                StatCard(
                    icon: "📍",
                    title: "City Rank",
                    value: "#\(Int.random(in: 1...20))",
                    color: .blue
                )
            }
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
            
            SettingsRow(
                icon: "creditcard.fill",
                title: "Subscription",
                action: onSubscriptionTap
            )
            
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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Settings coming soon!")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Notification preferences, privacy settings, and more will be available here.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                }
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
