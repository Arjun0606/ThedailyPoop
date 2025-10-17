import SwiftUI

struct DailyLeaderboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var pointsManager: PointsManager
    @State private var leaderboard: [DailyLeaderboardEntry] = []
    @State private var isLoading = true
    @State private var showingShop = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Leaderboard
                    if isLoading {
                        ProgressView()
                            .tint(.orange)
                            .scaleEffect(1.5)
                            .padding(.top, 100)
                    } else if leaderboard.isEmpty {
                        emptyView
                    } else {
                        leaderboardList
                    }
                    
                    // Points Guide
                    pointsGuideView
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
        }
        .navigationTitle("Daily Rankings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadLeaderboard()
        }
        .refreshable {
            await loadLeaderboard()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("🏆")
                .font(.system(size: 60))
            
            Text("Today's Rankings")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Resets at midnight")
                .font(.caption)
                .foregroundColor(.gray)
            
            if let user = authManager.currentUser {
                // Current user's rank
                if let myEntry = leaderboard.first(where: { $0.user.id == user.id }) {
                    HStack(spacing: 12) {
                        Text(myEntry.rankEmoji)
                            .font(.title)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("You're #\(myEntry.rank)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(user.dailyPoints) points today")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        // 2X Boost indicator
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple.opacity(0.5), lineWidth: 2)
                    )
                }
            }
        }
    }
    
    // MARK: - Leaderboard List
    
    private var leaderboardList: some View {
        VStack(spacing: 12) {
            ForEach(leaderboard) { entry in
                DailyLeaderboardRow(entry: entry, currentUserID: authManager.currentUser?.id ?? "")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Text("👻")
                .font(.system(size: 80))
            
            Text("Add friends to compete!")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Earn points by dropping, attacking, and getting reactions")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Points Guide
    
    private var pointsGuideView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💎 How to Earn Points")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                PointRow(emoji: "💩", action: "Drop a poop", points: 10)
                PointRow(emoji: "😂", action: "React to friend's drop", points: 5)
                PointRow(emoji: "🔥", action: "Get a reaction", points: 5)
                PointRow(emoji: "💨", action: "Send fart attack", points: 15)
                PointRow(emoji: "😱", action: "Get attacked", points: 20)
                PointRow(emoji: "🏆", action: "Win a poll", points: 25)
            }
            
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Load Leaderboard
    
    private func loadLeaderboard() async {
        guard let user = authManager.currentUser else { return }
        
        isLoading = true
        leaderboard = await pointsManager.fetchDailyLeaderboard(for: user)
        isLoading = false
        
        print("📊 Loaded leaderboard with \(leaderboard.count) entries")
    }
}

// MARK: - Leaderboard Row

struct DailyLeaderboardRow: View {
    let entry: DailyLeaderboardEntry
    let currentUserID: String
    
    var isCurrentUser: Bool {
        entry.user.id == currentUserID
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text(entry.rankEmoji)
                .font(.title)
                .frame(width: 50)
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.user.username)
                    .font(.headline)
                    .foregroundColor(isCurrentUser ? .orange : .white)
                
                HStack(spacing: 8) {
                    Text("\(entry.user.dailyPoints) pts")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                }
            }
            
            Spacer()
            
            // Attack streak
            if entry.user.attacksSent > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("💨 \(entry.user.attacksSent)")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? Color.orange.opacity(0.2) : Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Point Row

struct PointRow: View {
    let emoji: String
    let action: String
    let points: Int
    
    var body: some View {
        HStack {
            Text(emoji)
                .font(.title3)
            
            Text(action)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text("+\(points)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
    }
}

// MARK: - Preview

struct DailyLeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DailyLeaderboardView()
                .environmentObject(AuthenticationManager())
                .environmentObject(PointsManager(cloudKitManager: CloudKitManager()))
        }
        .preferredColorScheme(.dark)
    }
}

