import SwiftUI
import CloudKit

struct WeeklyLeaderboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var friendsManager: FriendsManager
    
    @State private var leaderboard: [LeaderboardEntry] = []
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
                                    LeaderboardRow(
                                        rank: index + 1,
                                        entry: entry,
                                        isCurrentUser: entry.userID == authManager.currentUser?.id
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            // CTA to buy more attacks
                            VStack(spacing: 12) {
                                Text("Climb the ranks faster")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                NavigationLink(destination: FartAttackShopView()) {
                                    HStack {
                                        Image(systemName: "cart.fill")
                                        Text("Get More Attacks")
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.yellow)
                                    .cornerRadius(12)
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
    
    private func loadLeaderboard() async {
        guard let currentUserID = authManager.currentUser?.id else { return }
        
        isLoading = true
        
        do {
            // Get list of friend IDs + current user
            var userIDs = friendsManager.friends.map { $0.id }
            userIDs.append(currentUserID)
            
            // Query AttackActivity for "sent" events in the last 7 days
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let predicate = NSPredicate(format: "type == %@ AND senderID IN %@ AND timestamp >= %@", 
                                       "sent", userIDs, weekAgo as NSDate)
            let query = CKQuery(recordType: "AttackActivity", predicate: predicate)
            
            let container = CKContainer.default()
            let database = container.publicCloudDatabase
            let results = try await database.records(matching: query, resultsLimit: 500)
            
            // Count attacks per user
            var attackCounts: [String: (username: String, count: Int)] = [:]
            
            for (_, result) in results.matchResults {
                if case .success(let record) = result,
                   let senderID = record["senderID"] as? String,
                   let senderUsername = record["senderUsername"] as? String {
                    
                    if let existing = attackCounts[senderID] {
                        attackCounts[senderID] = (senderUsername, existing.count + 1)
                    } else {
                        attackCounts[senderID] = (senderUsername, 1)
                    }
                }
            }
            
            // Convert to leaderboard entries and sort
            let entries = attackCounts.map { userID, data in
                LeaderboardEntry(
                    userID: userID,
                    username: data.username,
                    attacksSent: data.count
                )
            }.sorted { $0.attacksSent > $1.attacksSent }
            
            // Find current user's rank
            if let userRank = entries.firstIndex(where: { $0.userID == currentUserID }) {
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

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let userID: String
    let username: String
    let attacksSent: Int
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
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
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(FriendsManager.shared)
}

