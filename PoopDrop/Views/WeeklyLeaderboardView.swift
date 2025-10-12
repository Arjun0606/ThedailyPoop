import SwiftUI
import CloudKit

struct WeeklyLeaderboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var friendsManager: FriendsManager
    
    @State private var leaderboard: [WeeklyLeaderboardEntry] = []
    @State private var isLoading = false
    @State private var currentUserRank: Int?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading && leaderboard.isEmpty {
                    ProgressView("Loading rankings...")
                        .tint(.white)
                } else if leaderboard.isEmpty {
                    VStack(spacing: 16) {
                        Text("🏆")
                            .font(.system(size: 80))
                        Text("No activity this week")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Send attacks to climb the ranks!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header
                            VStack(spacing: 8) {
                                Text("🏆")
                                    .font(.system(size: 60))
                                Text("Top Pranksters")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.white)
                                Text("This Week")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                    .tracking(2)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 30)
                            
                            // Competitive messaging banner
                            if let rank = currentUserRank, rank > 1 {
                                competitiveMessageBanner(rank: rank)
                                    .padding(.horizontal)
                                    .padding(.bottom, 16)
                            }
                            
                            // Your rank (if not in top 10)
                            if let rank = currentUserRank, rank > 10 {
                                HStack {
                                    Text("#\(rank)")
                                        .font(.title2.bold())
                                        .foregroundColor(.yellow)
                                        .frame(width: 50)
                                    
                                    Text("You")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if let entry = leaderboard.first(where: { $0.userID == authManager.currentUser?.id }) {
                                        Text("\(entry.attacksSent) attacks")
                                            .font(.headline)
                                            .foregroundColor(.orange)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.yellow.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                                        )
                                )
                                .padding(.horizontal)
                                .padding(.bottom, 16)
                            }
                            
                            // Top 10
                            VStack(spacing: 8) {
                                ForEach(Array(leaderboard.prefix(10).enumerated()), id: \.element.id) { index, entry in
                                    WeeklyLeaderboardRow(
                                        rank: index + 1,
                                        entry: entry,
                                        isCurrentUser: entry.userID == authManager.currentUser?.id
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            // CTA to buy more attacks
                            VStack(spacing: 16) {
                                // Social proof
                                HStack(spacing: 4) {
                                    Text("⚡️")
                                    Text("Top pranksters buy attack packs")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Text("Dominate the Leaderboard")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                
                                NavigationLink(destination: FartAttackShopView()) {
                                    VStack(spacing: 8) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "bolt.fill")
                                            Text("Get 3 Attacks for $1.99")
                                                .fontWeight(.bold)
                                        }
                                        .font(.headline)
                                        
                                        Text("🔥 Instantly climb the ranks")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [Color.yellow, Color.orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .shadow(color: Color.yellow.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 30)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                // Dismiss
            })
        }
        .task {
            await loadLeaderboard()
        }
    }
    
    // MARK: - Competitive Messaging
    
    @ViewBuilder
    private func competitiveMessageBanner(rank: Int) -> some View {
        if let currentEntry = leaderboard.first(where: { $0.userID == authManager.currentUser?.id }),
           rank > 1,
           let nextPersonUp = leaderboard.first(where: { leaderboard.firstIndex(where: { $0.userID == $0.userID }) == rank - 2 }) {
            
            let attacksNeeded = nextPersonUp.attacksSent - currentEntry.attacksSent + 1
            
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("🔥")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You're #\(rank)!")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        if attacksNeeded <= 5 {
                            Text("Send \(attacksNeeded) more attack\(attacksNeeded == 1 ? "" : "s") to beat \(nextPersonUp.username)!")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        } else {
                            Text("\(nextPersonUp.username) is ahead by \(attacksNeeded) attacks")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                }
                
                // Inline CTA if close to next rank
                if attacksNeeded <= 5 {
                    NavigationLink(destination: FartAttackShopView()) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                            Text("Get 3 Attacks Now")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.5), lineWidth: 2)
                    )
            )
        }
    }
    
    private func loadLeaderboard() async {
        guard let currentUser = authManager.currentUser else { return }
        
        isLoading = true
        
        do {
            // Fetch all friends from CloudKit
            let friends = try await CloudKitManager.shared.fetchFriends(for: currentUser)
            
            // Create entries from friends + current user
            var allUsers = friends
            allUsers.append(currentUser)
            
            let entries = allUsers.map { user in
                WeeklyLeaderboardEntry(
                    userID: user.id,
                    username: user.username,
                    attacksSent: user.attacksSent
                )
            }.sorted { $0.attacksSent > $1.attacksSent }
            
            // Find current user's rank
            if let userRank = entries.firstIndex(where: { $0.userID == currentUser.id }) {
                await MainActor.run {
                    self.currentUserRank = userRank + 1
                }
            }
            
            await MainActor.run {
                self.leaderboard = entries
                self.isLoading = false
            }
        } catch {
            print("Error loading leaderboard: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Weekly Leaderboard Entry

struct WeeklyLeaderboardEntry: Identifiable {
    let id = UUID()
    let userID: String
    let username: String
    let attacksSent: Int
}

// MARK: - Weekly Leaderboard Row

struct WeeklyLeaderboardRow: View {
    let rank: Int
    let entry: WeeklyLeaderboardEntry
    let isCurrentUser: Bool
    
    var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text(rankEmoji)
                .font(.title2.bold())
                .foregroundColor(rankColor)
                .frame(width: 50)
            
            // Username
            Text(entry.username)
                .font(isCurrentUser ? .headline.bold() : .headline)
                .foregroundColor(isCurrentUser ? .yellow : .white)
            
            Spacer()
            
            // Attack count
            HStack(spacing: 4) {
                Text("\(entry.attacksSent)")
                    .font(.title3.bold())
                    .foregroundColor(.orange)
                Text("attacks")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? Color.yellow.opacity(0.15) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrentUser ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
    }
}

#Preview {
    WeeklyLeaderboardView()
        .environmentObject(AuthenticationManager())
        .environmentObject(FriendsManager())
}

