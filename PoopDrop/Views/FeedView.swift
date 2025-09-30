import SwiftUI

struct FeedView: View {
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var friendsManager = FriendsManager()
    @StateObject private var adManager = AdManager.shared
    @State private var selectedFeedType: FeedType = .friends
    @State private var friendDrops: [Drop] = []
    @State private var myDrops: [Drop] = []
    @State private var isRefreshing = false
    
    enum FeedType {
        case friends
        case my
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented Picker for Friends Feed / My Feed
                    Picker("Feed Type", selection: $selectedFeedType) {
                        Text("Friends").tag(FeedType.friends)
                        Text("My Feed").tag(FeedType.my)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .onChange(of: selectedFeedType) { newType in
                        if newType == .my {
                            loadMyDrops()
                        } else {
                            loadInitialFriendDrops()
                        }
                    }
                    
                    // Feed Content
                    if currentDrops.isEmpty && !friendsManager.isLoading {
                        if selectedFeedType == .friends {
                            EmptyFriendsDropsView()
                        } else {
                            EmptyMyDropsView()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Drops feed with native ads
                                ForEach(Array(currentDrops.enumerated()), id: \.element.id) { index, drop in
                                    DropCardView(drop: drop)
                                        .onAppear {
                                            // Load more drops when approaching end
                                            if drop.id == currentDrops.last?.id {
                                                if selectedFeedType == .friends {
                                                    loadMoreFriendDrops()
                                                }
                                            }
                                        }
                                    
                                    // Insert native ad every 2 drops
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
            }
            .navigationTitle("💩 Feed")
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
                        
                        // Pro removed
                    }
                }
            }
        }
        .onAppear {
            loadInitialFriendDrops()
            loadMyDrops()
            
            adManager.loadNativeAd()
            adManager.loadInterstitialAd() // Preload interstitial
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("USER_STATS_UPDATED"))) { _ in
            // Refresh my drops when user creates a new drop
            if selectedFeedType == .my {
                loadMyDrops()
            }
        }
    }
    
    // Computed property to get current drops based on selected feed type
    private var currentDrops: [Drop] {
        selectedFeedType == .friends ? friendDrops : myDrops
    }
    
    private func loadMyDrops() {
        guard let user = authManager.currentUser else { return }
        
        Task {
            do {
                let drops = try await cloudKitManager.fetchUserDrops(for: user)
                await MainActor.run {
                    self.myDrops = drops.filter { $0.isCurrentlyVisible }
                }
            } catch {
                print("Failed to load my drops: \(error)")
            }
        }
    }
    
    private func loadInitialFriendDrops() {
        guard let user = authManager.currentUser else { return }
        
        Task {
            do {
                let drops = try await friendsManager.getFriendDrops(for: user)
                await MainActor.run {
                    // Filter out user's own drops from Friends Feed
                    self.friendDrops = drops.filter { $0.userID != user.id }
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
                    // Filter out user's own drops from Friends Feed
                    self.friendDrops = drops.filter { $0.userID != user.id }
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
        
        if selectedFeedType == .my {
            do {
                let drops = try await cloudKitManager.fetchUserDrops(for: user)
                myDrops = drops.filter { $0.isCurrentlyVisible }
            } catch {
                print("Failed to refresh my drops: \(error)")
            }
        } else {
            do {
                let drops = try await friendsManager.getFriendDrops(for: user)
                // Filter out user's own drops from Friends Feed
                friendDrops = drops.filter { $0.userID != user.id }
            } catch {
                print("Failed to refresh friend feed: \(error)")
            }
        }
        
        isRefreshing = false
    }
}

// MARK: - Empty State Views
struct EmptyMyDropsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("💩")
                .font(.system(size: 80))
            
            VStack(spacing: 12) {
                Text("No Drops Yet!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Tap the 💩 button to drop your first poop!")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyFriendsDropsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("👥")
                .font(.system(size: 80))
            
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
