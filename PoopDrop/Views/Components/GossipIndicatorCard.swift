import SwiftUI

/// A floating gossip indicator that appears on the Map tab
/// Shows how many new gossip posts mention visible users
/// Drives users from Map → Gossip tab
struct GossipIndicatorCard: View {
    @StateObject private var gossipManager = GossipManager.shared
    @State private var gossipCount: Int = 0
    @State private var mentionedUsernames: [String] = []
    @State private var isDismissed = false
    
    var body: some View {
        if gossipCount > 0 && !isDismissed {
            VStack(alignment: .trailing, spacing: 4) {
                // Dismiss button
                Button(action: { withAnimation { isDismissed = true } }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                
                // Main card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundColor(.yellow)
                        Text("\(gossipCount) new gossip")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                    }
                    
                    if !mentionedUsernames.isEmpty {
                        Text("about \(formattedUsernames)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Tap to see")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.yellow, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .shadow(color: Color.yellow.opacity(0.4), radius: 8, x: 0, y: 4)
                .onTapGesture {
                    // Switch to Gossip tab
                    NotificationCenter.default.post(
                        name: Notification.Name("SWITCH_TO_GOSSIP_TAB"),
                        object: nil
                    )
                }
            }
            .padding(.trailing, 16)
            .padding(.top, 16)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }
    
    // MARK: - Helpers
    
    private var formattedUsernames: String {
        if mentionedUsernames.isEmpty {
            return "your friends"
        } else if mentionedUsernames.count == 1 {
            return "@\(mentionedUsernames[0])"
        } else if mentionedUsernames.count == 2 {
            return "@\(mentionedUsernames[0]) & @\(mentionedUsernames[1])"
        } else {
            return "@\(mentionedUsernames[0]), @\(mentionedUsernames[1]) + \(mentionedUsernames.count - 2) more"
        }
    }
    
    // MARK: - Data Loading
    
    func loadGossipCount(for friends: [User]) async {
        let allGossip = await gossipManager.loadTodaysGossip()
        let friendUsernames = Set(friends.map { $0.username })
        
        // Count gossip that mentions any of the user's friends
        var relevantGossip: [GossipPost] = []
        var mentioned: Set<String> = []
        
        for gossip in allGossip {
            let mentionedFriends = gossip.mentionedUsernames.filter { friendUsernames.contains($0) }
            if !mentionedFriends.isEmpty {
                relevantGossip.append(gossip)
                mentioned.formUnion(mentionedFriends)
            }
        }
        
        gossipCount = relevantGossip.count
        mentionedUsernames = Array(mentioned).prefix(3).map { String($0) }
        
        print("📊 Gossip indicator: \(gossipCount) posts mentioning \(mentionedUsernames.count) friends")
    }
}

// MARK: - Compact Version

/// A minimal gossip badge for the map
struct GossipBadge: View {
    let count: Int
    
    var body: some View {
        if count > 0 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption2)
                Text("\(count)")
                    .font(.caption2.weight(.bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            HStack {
                Spacer()
                GossipIndicatorCard()
            }
            Spacer()
        }
    }
}

