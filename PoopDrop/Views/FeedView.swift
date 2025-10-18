import SwiftUI

struct FeedView: View {
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var friendsManager = FriendsManager()
    @State private var allDrops: [Drop] = []
    @State private var isRefreshing = false
    @State private var showingFriendsManager = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Feed Content
                    if allDrops.isEmpty && !friendsManager.isLoading {
                        EmptyFeedView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Trending Gossip Card (NEW! The bridge to drama)
                                TrendingGossipCard()
                                    .padding(.top, 8)
                                
                                // Drops feed
                                ForEach(allDrops) { drop in
                                    DropCardView(drop: drop)
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
            .navigationTitle("💩 Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFriendsManager = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                            Text("Friends")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(20)
                    }
                }
            }
        }
        .sheet(isPresented: $showingFriendsManager) {
            NavigationView {
                FriendsView()
            }
        }
        .onAppear {
            loadAllDrops()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("USER_STATS_UPDATED"))) { _ in
            loadAllDrops()
        }
    }
    
    private func loadAllDrops() {
        guard let user = authManager.currentUser else { return }
        
        Task {
            do {
                // Load both friend drops and user's own drops
                let friendDropsList = try await friendsManager.getFriendDrops(for: user)
                let myDropsList = try await cloudKitManager.fetchUserDrops(for: user)
                
                // Combine and sort by timestamp
                let combined = (friendDropsList + myDropsList)
                    .filter { $0.isCurrentlyVisible }
                    .sorted { $0.timestamp > $1.timestamp }
                
                await MainActor.run {
                    self.allDrops = combined
                }
            } catch {
                print("Failed to load drops: \(error)")
            }
        }
    }
    
    
    @MainActor
    private func refreshFeed() async {
        loadAllDrops()
        isRefreshing = false
    }
}

// MARK: - Ghost Attack Mini Banner
struct FartAttackMiniBanner: View {
    @State private var pulsing = false
    
    var body: some View {
        Button(action: {
            NotificationCenter.default.post(name: Notification.Name("SWITCH_TO_ATTACKS_TAB"), object: nil)
        }) {
            HStack(spacing: 10) {
                Text("💨")
                    .font(.title3)
                    .scaleEffect(pulsing ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsing)
                Text("Prank a friend now")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(12)
            .background(Color.orange.opacity(0.25))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.4), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .onAppear { pulsing = true }
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

struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("👥")
                .font(.system(size: 80))
            
            VStack(spacing: 12) {
                Text("No Drops Yet!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Add friends to see their poop drops, or drop your own to get started!")
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
                    TipRow(icon: "💩", text: "Track your daily drops and compete with friends")
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

// MARK: - Gossip Promo Card
struct GossipPromoCard: View {
    @State private var isDismissed = false
    
    var body: some View {
        if !isDismissed {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("☕")
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What are your friends saying?")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Check out the Gossip tab →")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: { withAnimation { isDismissed = true }}) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "eye.slash.fill")
                        .foregroundColor(.yellow)
                    Text("Anonymous posts")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Image(systemName: "lock.open.fill")
                        .foregroundColor(.yellow)
                    Text("$1.99 to reveal")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.4), lineWidth: 1)
            )
        }
    }
}

#Preview {
    FeedView()
        .environmentObject(CloudKitManager())
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
}
