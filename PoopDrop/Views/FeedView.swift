import SwiftUI

struct FeedView: View {
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var isRefreshing = false
    @State private var showingProUpsell = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                if cloudKitManager.drops.isEmpty && !cloudKitManager.isLoading {
                    EmptyFeedView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Pro user welcome message
                            if subscriptionManager.isProSubscriber {
                                ProWelcomeCard()
                            }
                            
                            // Drops feed
                            ForEach(cloudKitManager.drops) { drop in
                                DropCardView(drop: drop)
                                    .onAppear {
                                        // Load more drops when approaching end
                                        if drop.id == cloudKitManager.drops.last?.id {
                                            loadMoreDrops()
                                        }
                                    }
                            }
                            
                            // Loading indicator
                            if cloudKitManager.isLoading {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .padding()
                            }
                            
                            // Pro upsell card for free users
                            if !subscriptionManager.isProSubscriber && !cloudKitManager.drops.isEmpty {
                                ProUpsellCard {
                                    showingProUpsell = true
                                }
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
            .navigationTitle("💩 Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Streak indicator
                        if let user = authManager.currentUser, user.streak > 0 {
                            HStack(spacing: 4) {
                                Text("🔥")
                                    .font(.caption)
                                Text("\(user.streak)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
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
            loadInitialDrops()
        }
        .sheet(isPresented: $showingProUpsell) {
            ProUpsellView()
        }
    }
    
    private func loadInitialDrops() {
        guard cloudKitManager.drops.isEmpty else { return }
        
        Task {
            do {
                try await cloudKitManager.fetchDrops()
            } catch {
                print("Failed to load drops: \(error)")
            }
        }
    }
    
    private func loadMoreDrops() {
        // Implement pagination if needed
        Task {
            do {
                try await cloudKitManager.fetchDrops(limit: 20)
            } catch {
                print("Failed to load more drops: \(error)")
            }
        }
    }
    
    @MainActor
    private func refreshFeed() async {
        isRefreshing = true
        
        do {
            try await cloudKitManager.fetchDrops()
        } catch {
            print("Failed to refresh feed: \(error)")
        }
        
        isRefreshing = false
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
