import Foundation
import CloudKit

@MainActor
class PointsManager: ObservableObject {
    
    @Published var showPointsAnimation = false
    @Published var lastPointsEarned = 0
    @Published var lastPointsReason = ""
    
    private let calendar = Calendar.current
    private let cloudKitManager: CloudKitManager
    
    init(cloudKitManager: CloudKitManager) {
        self.cloudKitManager = cloudKitManager
    }
    
    // MARK: - Point Values (with reactions boost!)
    
    enum PointAction {
        case dropPoop           // +10
        case reactToFriend      // +5 per reaction
        case receiveReaction    // +5 per reaction received (NEW!)
        case sendAttack         // +15
        case receiveAttack      // +20
        case winPoll            // +25
        
        var basePoints: Int {
            switch self {
            case .dropPoop: return 10
            case .reactToFriend: return 5
            case .receiveReaction: return 5  // Each reaction = 5 points!
            case .sendAttack: return 15
            case .receiveAttack: return 20
            case .winPoll: return 25
            }
        }
        
        var displayName: String {
            switch self {
            case .dropPoop: return "💩 Dropped a poop"
            case .reactToFriend: return "😂 Reacted to friend"
            case .receiveReaction: return "🔥 Got a reaction"
            case .sendAttack: return "💨 Sent fart attack"
            case .receiveAttack: return "😱 Got attacked"
            case .winPoll: return "🏆 Won a poll"
            }
        }
    }
    
    // MARK: - Award Points
    
    func awardPoints(to user: inout User, for action: PointAction, multiplier: Int = 1) async {
        // Check if points need daily reset
        await checkAndResetDailyPoints(for: &user)
        
        // Calculate points (with 2X boost if active)
        let basePoints = action.basePoints * multiplier
        let finalPoints = user.pointsBoostActive ? basePoints * 2 : basePoints
        
        // Update user points
        user.dailyPoints += finalPoints
        user.totalLifetimePoints += finalPoints
        
        print("🎯 Awarded \(finalPoints) points for: \(action.displayName)")
        
        // Save to CloudKit
        try? await cloudKitManager.saveUser(user)
        
        // Trigger animation
        lastPointsEarned = finalPoints
        lastPointsReason = action.displayName
        showPointsAnimation = true
        
        // Hide animation after 2 seconds
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        showPointsAnimation = false
    }
    
    // MARK: - Daily Reset Logic
    
    func checkAndResetDailyPoints(for user: inout User) async {
        let now = Date()
        
        // Check if we need to reset (new day)
        if let lastReset = user.dailyPointsResetDate {
            let shouldReset = !calendar.isDate(lastReset, inSameDayAs: now)
            
            if shouldReset {
                print("🔄 Resetting daily points (was: \(user.dailyPoints))")
                user.dailyPoints = 0
                user.dailyPointsResetDate = now
                try? await cloudKitManager.saveUser(user)
            }
        } else {
            // First time - set reset date
            user.dailyPointsResetDate = now
            try? await cloudKitManager.saveUser(user)
        }
        
        // Check if points boost expired
        if user.pointsBoostActive, let expiresAt = user.pointsBoostExpiresAt, now > expiresAt {
            print("⏰ Points boost expired")
            user.pointsBoostActive = false
            user.pointsBoostExpiresAt = nil
            try? await cloudKitManager.saveUser(user)
        }
    }
    
    // MARK: - 2X Points Boost (IAP)
    
    func activate2XBoost(for user: inout User) async {
        let now = Date()
        let expiresAt = calendar.date(byAdding: .hour, value: 24, to: now)!
        
        user.pointsBoostActive = true
        user.pointsBoostExpiresAt = expiresAt
        
        print("🚀 Activated 2X points boost until \(expiresAt)")
        try? await cloudKitManager.saveUser(user)
    }
    
    // MARK: - Leaderboard Fetching
    
    func fetchDailyLeaderboard(for user: User) async -> [DailyLeaderboardEntry] {
        // Get all friends
        let friendIDs = user.friends
        guard !friendIDs.isEmpty else {
            // Just return current user
            return [DailyLeaderboardEntry(user: user, rank: 1)]
        }
        
        // Fetch all friends from CloudKit
        var allUsers: [User] = []
        
        for friendID in friendIDs {
            if let friendUser = try? await cloudKitManager.fetchUser(id: friendID) {
                allUsers.append(friendUser)
            }
        }
        
        // Add current user
        allUsers.append(user)
        
        // Sort by daily points (descending)
        let sorted = allUsers.sorted { $0.dailyPoints > $1.dailyPoints }
        
        // Create leaderboard entries with ranks
        let entries = sorted.enumerated().map { (index, user) in
            DailyLeaderboardEntry(user: user, rank: index + 1)
        }
        
        return entries
    }
}

// MARK: - Daily Leaderboard Entry Model

struct DailyLeaderboardEntry: Identifiable {
    let id = UUID()
    let user: User
    let rank: Int
    
    var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
}

