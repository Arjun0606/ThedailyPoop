import SwiftUI

struct FeedView: View {
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var authManager: AuthenticationManager
    // Subscription removed
    @StateObject private var friendsManager = FriendsManager()
    @StateObject private var adManager = AdManager.shared
    @State private var friendDrops: [Drop] = []
    @State private var isRefreshing = false
                        // Pro removed
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                if friendDrops.isEmpty && !friendsManager.isLoading {
                    EmptyFriendsDropsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                        // Pro removed
                            
                            // Friends' drops feed with native ads
                            ForEach(Array(friendDrops.enumerated()), id: \.element.id) { index, drop in
                                DropCardView(drop: drop)
                                    .onAppear {
                                        // Load more drops when approaching end
                                        if drop.id == friendDrops.last?.id {
                                            loadMoreFriendDrops()
                                        }
                                    }
                                
                                // Insert native ad every 5th drop (simplified - no Pro users)
                                if (index + 1) % 2 == 0,
                                   let nativeAd = adManager.nativeAd {
                                    NativeAdCardView(adViewModel: nativeAd)
                                        .transition(.opacity)
                                        .onAppear {
                                            // Load a new ad for the next placement
                                            adManager.loadNativeAd()
                                        }
                                }
                            }
                            
                            // Loading indicator
                            if friendsManager.isLoading {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .padding()
                            }
                            
                            // Pro removed
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100) // Space for FAB
                    }
                    .refreshable {
                        await refreshFeed()
                    }
                }
            }
            .navigationTitle("💩 Friends Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Streak indicator
                        if let user = authManager.currentUser {
                            StreakView(user: user, fontSize: .caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        // Pro badge
                        if subscriptionManager.isProSubscriber {
                            Text("PRO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadInitialFriendDrops()
            
            // Load initial ad for free users
            if !subscriptionManager.isProSubscriber {
                adManager.loadNativeAd()
                adManager.loadInterstitialAd() // Preload interstitial
            }
        }
        // Pro removed
    }
    
    private func loadInitialFriendDrops() {
        guard let user = authManager.currentUser else { return }
        
        Task {
            do {
                let drops = try await friendsManager.getFriendDrops(for: user)
                await MainActor.run {
                    self.friendDrops = drops
                }
            } catch {
                print("Failed to load friend drops: \(error)")
            }
        }
    }
    
    private func loadMoreFriendDrops() {
        // Implement pagination if needed
        guard let user = authManager.currentUser else { return }
        
        Task {
            do {
                let drops = try await friendsManager.getFriendDrops(for: user)
                await MainActor.run {
                    self.friendDrops = drops
                }
            } catch {
                print("Failed to load more friend drops: \(error)")
            }
        }
    }
    
    @MainActor
    private func refreshFeed() async {
        guard let user = authManager.currentUser else { return }
        
        isRefreshing = true
        
        do {
            let drops = try await friendsManager.getFriendDrops(for: user)
            friendDrops = drops
        } catch {
            print("Failed to refresh friend feed: \(error)")
        }
        
        isRefreshing = false
    }
}

struct EmptyFriendsDropsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("👥")
                .font(.system(size: 80))
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: true)
            
            VStack(spacing: 12) {
                Text("No Friend Drops Yet!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Add friends to see their poop drops! When your friends drop poops (or have no poop days), they'll appear here.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 16) {
                Text("Get started:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    TipRow(icon: "👥", text: "Go to Friends tab to add friends")
                    TipRow(icon: "💩", text: "Drop your own poop to get started")
                    TipRow(icon: "📱", text: "Friends get notified when you drop")
                    TipRow(icon: "🔥", text: "Keep streaks alive with 'No Poop' option")
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 32)
        }
    }
}

struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("💩")
                .font(.system(size: 80))
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: true)
            
            VStack(spacing: 12) {
                Text("No Drops Yet!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Be the first to drop a poop in your area! Tap the 💩 button to get started.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 16) {
                Text("Tips for your first drop:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    TipRow(icon: "📍", text: "Make sure location is enabled")
                    TipRow(icon: "✍️", text: "Add a fun caption (up to 50 characters)")
                    TipRow(icon: "🎨", text: "Choose your poop style")
                    TipRow(icon: "🚀", text: "Upgrade to Pro for more features!")
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 32)
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

struct ProWelcomeCard: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("👑")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back, Pro!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Enjoying unlimited features")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                ProFeatureBadge(icon: "📝", text: "200 words")
                ProFeatureBadge(icon: "🎨", text: "All skins")
                ProFeatureBadge(icon: "😀", text: "All emojis")
                ProFeatureBadge(icon: "🎵", text: "Sounds")
                
                Spacer()
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

struct ProFeatureBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title3)
            
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ProUpsellCard: View {
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
                        
                        Text("Unlock premium features and become the ultimate poop dropper!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Text("$3.99/mo")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                
                HStack(spacing: 12) {
                    FeatureHighlight(text: "200-word captions")
                    FeatureHighlight(text: "Premium skins")
                    FeatureHighlight(text: "All emojis")
                    
                    Spacer()
                }
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

struct FeatureHighlight: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.2))
            .cornerRadius(6)
    }
}

#Preview {
    FeedView()
        .environmentObject(CloudKitManager())
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
}
