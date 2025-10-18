import SwiftUI

/// A beautiful promo card that shows the hottest gossip of the day
/// Drives users from Feed tab → Gossip tab
/// The bridge between the Poop world and the Drama world
struct TrendingGossipCard: View {
    @StateObject private var gossipManager = GossipManager.shared
    @State private var trendingGossip: GossipPost?
    @State private var isLoading = true
    
    var body: some View {
        if let gossip = trendingGossip {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Trending Gossip")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.orange)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                
                // Gossip preview (truncated)
                Text(gossip.text)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .padding(.vertical, 4)
                
                // Social proof bar
                HStack(spacing: 16) {
                    // Reveal count (FOMO driver)
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.caption)
                        Text("\(gossip.revealedBy.count) revealed")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.purple)
                    
                    // Reaction count
                    if gossip.reactions.values.reduce(0, +) > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                            Text("\(gossip.reactions.values.reduce(0, +))")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(.pink)
                    }
                    
                    // Reply count
                    if gossip.replyCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.fill")
                                .font(.caption)
                            Text("\(gossip.replyCount)")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                
                // CTA
                Text("Tap to see what's going on 👀")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.15),
                        Color.purple.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
            .onTapGesture {
                // Switch to Gossip tab
                NotificationCenter.default.post(
                    name: Notification.Name("SWITCH_TO_GOSSIP_TAB"),
                    object: nil,
                    userInfo: ["gossipID": gossip.id]
                )
            }
        } else if isLoading {
            // Loading placeholder
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Loading trending gossip...")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.orange)
                    Spacer()
                }
                
                ProgressView()
                    .tint(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
        // If no gossip, don't show card at all
        // (clean, not cluttered)
        .task {
            await loadTrendingGossip()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadTrendingGossip() async {
        isLoading = true
        
        // Strategy: Find gossip with most reveals in last 24 hours
        let allGossip = await gossipManager.loadTodaysGossip()
        
        // Sort by reveal count (highest first)
        let sorted = allGossip.sorted { g1, g2 in
            g1.revealedBy.count > g2.revealedBy.count
        }
        
        // Pick the top one with at least 3 reveals (for social proof)
        trendingGossip = sorted.first(where: { $0.revealedBy.count >= 3 })
        
        isLoading = false
    }
}

// MARK: - Alternative: Compact Version

/// A more compact trending gossip card for constrained spaces
struct CompactTrendingGossipCard: View {
    @StateObject private var gossipManager = GossipManager.shared
    @State private var revealCount: Int = 0
    
    var body: some View {
        if revealCount > 0 {
            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("🔥 Trending Gossip")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                    Text("\(revealCount) people revealed the tea")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange, lineWidth: 1)
            )
            .onTapGesture {
                NotificationCenter.default.post(
                    name: Notification.Name("SWITCH_TO_GOSSIP_TAB"),
                    object: nil
                )
            }
        }
        .task {
            // Count total reveals across all gossip today
            let allGossip = await gossipManager.loadTodaysGossip()
            revealCount = allGossip.reduce(0) { $0 + $1.revealedBy.count }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Full version
        TrendingGossipCard()
            .padding()
        
        // Compact version
        CompactTrendingGossipCard()
            .padding()
    }
    .background(Color.black)
}

