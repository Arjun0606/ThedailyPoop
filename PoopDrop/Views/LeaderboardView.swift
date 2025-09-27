import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedScope: LeaderboardScope = .global
    @State private var leaderboardData: [LeaderboardEntry] = []
    @State private var isLoading = false
    @State private var userRank: Int?
    
    enum LeaderboardScope: String, CaseIterable {
        case global = "Global"
        case city = "City"
        case friends = "Friends"
        
        var icon: String {
            switch self {
            case .global:
                return "globe"
            case .city:
                return "building.2"
            case .friends:
                return "person.2"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Scope selector
                    ScopeSelectorView(selectedScope: $selectedScope)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Spacer()
                    } else if leaderboardData.isEmpty {
                        EmptyLeaderboardView(scope: selectedScope)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                // Top 3 podium
                                if leaderboardData.count >= 3 {
                                    PodiumView(
                                        first: leaderboardData[0],
                                        second: leaderboardData[1],
                                        third: leaderboardData[2]
                                    )
                                    .padding(.horizontal)
                                    .padding(.top, 20)
                                }
                                
                                // Rest of the leaderboard
                                ForEach(Array(leaderboardData.enumerated()), id: \.element.id) { index, entry in
                                    if index >= 3 {
                                        LeaderboardRowView(
                                            entry: entry,
                                            rank: index + 1,
                                            isCurrentUser: entry.userId == authManager.currentUser?.id
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                                
                                // User's rank if not in top visible
                                if let userRank = userRank, userRank > leaderboardData.count {
                                    UserRankView(rank: userRank)
                                        .padding(.horizontal)
                                        .padding(.top, 20)
                                }
                                
                                Spacer(minLength: 100)
                            }
                        }
                    }
                }
            }
            .navigationTitle("🏆 Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
        .onAppear {
            loadLeaderboard()
        }
        .onChange(of: selectedScope) { _ in
            loadLeaderboard()
        }
    }
    
    private func loadLeaderboard() {
        isLoading = true
        
        // Simulate loading leaderboard data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            generateMockLeaderboardData()
            isLoading = false
        }
    }
    
    private func generateMockLeaderboardData() {
        let mockUsers = [
            ("PoopMaster3000", 147, 23, "San Francisco", true),
            ("ToiletKing", 134, 19, "New York", true),
            ("FlushQueen", 128, 21, "Los Angeles", false),
            ("BrownTownHero", 115, 15, "Chicago", true),
            ("PoopScoop", 98, 12, "Miami", false),
            ("ToiletPaperPro", 87, 18, "Seattle", true),
            ("FlushMaster", 76, 9, "Austin", false),
            ("PoopDropper", 65, 14, "Denver", false),
            ("BathroomBoss", 54, 8, "Portland", true),
            ("ToiletTitan", 43, 11, "Boston", false)
        ]
        
        leaderboardData = mockUsers.enumerated().map { index, user in
            LeaderboardEntry(
                id: UUID().uuidString,
                userId: user.0,
                displayName: user.0,
                totalDrops: user.1,
                streak: user.2,
                city: user.3,
                isPro: user.4,
                rank: index + 1
            )
        }
        
        // Set user rank if current user exists
        if let currentUser = authManager.currentUser {
            userRank = Int.random(in: 15...50) // Mock user rank
        }
    }
}

struct LeaderboardEntry: Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let totalDrops: Int
    let streak: Int
    let city: String
    let isPro: Bool
    let rank: Int
}

struct ScopeSelectorView: View {
    @Binding var selectedScope: LeaderboardView.LeaderboardScope
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardView.LeaderboardScope.allCases, id: \.self) { scope in
                Button(action: {
                    selectedScope = scope
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: scope.icon)
                            .font(.caption)
                        Text(scope.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedScope == scope ? .black : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedScope == scope ? Color.white : Color.clear)
                    )
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PodiumView: View {
    let first: LeaderboardEntry
    let second: LeaderboardEntry
    let third: LeaderboardEntry
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Second place
            PodiumPosition(
                entry: second,
                rank: 2,
                height: 80,
                color: .gray
            )
            
            // First place
            PodiumPosition(
                entry: first,
                rank: 1,
                height: 100,
                color: .yellow
            )
            
            // Third place
            PodiumPosition(
                entry: third,
                rank: 3,
                height: 60,
                color: Color.brown.opacity(0.7)
            )
        }
        .padding(.vertical, 20)
    }
}

struct PodiumPosition: View {
    let entry: LeaderboardEntry
    let rank: Int
    let height: CGFloat
    let color: Color
    
    private var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "🏆"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // User info
            VStack(spacing: 4) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(entry.displayName.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                Text(entry.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("💩")
                        .font(.caption2)
                    Text("\(entry.totalDrops)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                if entry.isPro {
                    Text("PRO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.yellow)
                        .cornerRadius(3)
                }
            }
            
            // Podium base
            VStack(spacing: 0) {
                Text(rankEmoji)
                    .font(.title)
                    .padding(.bottom, 4)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: height)
                    .overlay(
                        Text("#\(rank)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isCurrentUser ? .yellow : .white.opacity(0.8))
                .frame(width: 30, alignment: .leading)
            
            // Profile
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.brown.opacity(0.7), Color.brown],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(entry.displayName.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(entry.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isCurrentUser ? .yellow : .white)
                    
                    if entry.isPro {
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.yellow)
                            .cornerRadius(3)
                    }
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("💩")
                            .font(.caption)
                        Text("\(entry.totalDrops)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if entry.streak > 0 {
                        HStack(spacing: 4) {
                            Text("🔥")
                                .font(.caption)
                            Text("\(entry.streak)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text(entry.city)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? Color.yellow.opacity(0.1) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrentUser ? Color.yellow.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct UserRankView: View {
    let rank: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Your Rank")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text("#\(rank)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading) {
                    Text("Keep dropping to climb higher!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("💩 Drop more poops to improve your rank")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct EmptyLeaderboardView: View {
    let scope: LeaderboardView.LeaderboardScope
    
    var body: some View {
        VStack(spacing: 24) {
            Text("🏆")
                .font(.system(size: 80))
            
            VStack(spacing: 12) {
                Text("No Rankings Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(emptyMessage)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Text("Start dropping poops to see rankings!")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var emptyMessage: String {
        switch scope {
        case .global:
            return "Be the first to make it to the global leaderboard!"
        case .city:
            return "No one in your city has started dropping yet. Be the first!"
        case .friends:
            return "Add friends to see who's the ultimate poop dropper!"
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(CloudKitManager())
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
}
