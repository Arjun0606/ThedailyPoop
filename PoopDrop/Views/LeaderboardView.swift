import SwiftUI
import CloudKit

struct FriendLeaderboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var leaderboardData: [LeaderboardEntry] = []
    @State private var timeframe: Timeframe = .weekly
    @State private var isLoading = true
    
    enum Timeframe: String, CaseIterable {
        case weekly = "This Week"
        case monthly = "This Month"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Timeframe Picker
                    Picker("Timeframe", selection: $timeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: timeframe) { _, _ in
                        loadLeaderboard()
                    }
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    } else if leaderboardData.isEmpty {
                        VStack(spacing: 16) {
                            Text("👥")
                                .font(.system(size: 60))
                            Text("No friends yet!")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Add friends to see the leaderboard")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(Array(leaderboardData.enumerated()), id: \.element.userId) { index, entry in
                                    LeaderboardRow(
                                        rank: index + 1,
                                        entry: entry,
                                        isCurrentUser: entry.userId == authManager.currentUser?.id
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("🏆 Friend Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadLeaderboard()
        }
    }
    
    private func loadLeaderboard() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            guard let currentUser = authManager.currentUser else { return }
            
            do {
                // Fetch friends
                let friends = try await CloudKitManager.shared.fetchFriends(for: currentUser)
                
                // Add current user to the list
                var allUsers = friends
                allUsers.append(currentUser)
                
                // Calculate drops for each user based on timeframe
                var entries: [LeaderboardEntry] = []
                
                for user in allUsers {
                    let userDrops = try await CloudKitManager.shared.fetchUserDrops(for: user)
                    let filteredDrops = filterDropsByTimeframe(userDrops)
                    
                    entries.append(LeaderboardEntry(
                        userId: user.id,
                        username: user.username,
                        dropCount: filteredDrops.count,
                        avatarURL: user.avatarURL,
                        streak: user.streak
                    ))
                }
                
                // Sort by drop count descending
                await MainActor.run {
                    leaderboardData = entries.sorted { $0.dropCount > $1.dropCount }
                }
                
            } catch {
                print("❌ Failed to load leaderboard: \(error)")
            }
        }
    }
    
    private func filterDropsByTimeframe(_ drops: [Drop]) -> [Drop] {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeframe {
        case .weekly:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return drops.filter { $0.timestamp >= weekAgo }
        case .monthly:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return drops.filter { $0.timestamp >= monthAgo }
        case .allTime:
            return drops
        }
    }
}

struct LeaderboardEntry {
    let userId: String
    let username: String
    let dropCount: Int
    let avatarURL: URL?
    let streak: Int
}

struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    @State private var avatar: UIImage?
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank with crown for #1
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)
                
                if rank == 1 {
                    Text("👑")
                        .font(.title3)
                } else {
                    Text("\(rank)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // Avatar
            if let avatar = avatar {
                Image(uiImage: avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.brown.opacity(0.6))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(entry.username.prefix(1)).uppercased())
                            .font(.title3)
                            .foregroundColor(.white)
                    )
            }
            
            // Username & Streak
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.username)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.caption)
                    Text("\(entry.streak)-day streak")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Drop count
            VStack(spacing: 4) {
                Text("\(entry.dropCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("drops")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? Color.blue.opacity(0.2) : Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onAppear {
            loadAvatar()
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return Color.white.opacity(0.3)
        }
    }
    
    private func loadAvatar() {
        guard let url = entry.avatarURL else { return }
        Task {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                await MainActor.run {
                    avatar = image
                }
            }
        }
    }
}

#Preview {
    FriendLeaderboardView()
        .environmentObject(AuthenticationManager())
}