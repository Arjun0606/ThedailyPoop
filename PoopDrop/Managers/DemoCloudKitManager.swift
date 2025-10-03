import Foundation
import CloudKit
import CoreLocation

/// Demo CloudKit Manager - Returns pre-loaded demo data instead of fetching from CloudKit
/// This is NOT a subclass - it's a wrapper that matches CloudKitManager's interface
@MainActor
class DemoCloudKitManager: ObservableObject {
    @Published var drops: [Drop] = []
    @Published var users: [User] = []
    @Published var sponsorCampaigns: [SponsorCampaign] = []
    @Published var isAvailable = true // Always available in demo mode
    
    init() {
        // Immediately load demo drops
        self.drops = DemoModeManager.shared.demoDrops
        print("🎭 [DEMO MODE] DemoCloudKitManager initialized with \(self.drops.count) drops")
    }
    
    // Fetch methods that return demo data
    func fetchDrops(limit: Int = 50) async throws -> [Drop] {
        print("🎭 [DEMO MODE] fetchDrops called - returning \(DemoModeManager.shared.demoDrops.count) demo drops")
        self.drops = DemoModeManager.shared.demoDrops
        return DemoModeManager.shared.demoDrops
    }
    
    func fetchUserDrops(for user: User) async throws -> [Drop] {
        print("🎭 [DEMO MODE] fetchUserDrops called for user: \(user.username)")
        let userDrops = DemoModeManager.shared.demoDrops.filter { $0.userID == user.id }
        return userDrops
    }
    
    func fetchNearbyDrops(coordinate: CLLocationCoordinate2D, radius: Double = 1000) async throws -> [Drop] {
        print("🎭 [DEMO MODE] fetchNearbyDrops called - returning all demo drops")
        self.drops = DemoModeManager.shared.demoDrops
        return DemoModeManager.shared.demoDrops
    }
    
    func createDrop(_ drop: Drop) async throws -> Drop {
        print("🎭 [DEMO MODE] createDrop called - adding to demo data")
        // Add to demo drops
        DemoModeManager.shared.demoDrops.insert(drop, at: 0)
        self.drops = DemoModeManager.shared.demoDrops
        return drop
    }
    
    func saveUser(_ user: User) async throws {
        print("🎭 [DEMO MODE] saveUser called - updating demo user")
        DemoModeManager.shared.demoUser = user
    }
    
    func fetchUserByAppleUserID(_ appleUserID: String) async throws -> User? {
        print("🎭 [DEMO MODE] fetchUserByAppleUserID called - returning demo user")
        return DemoModeManager.shared.demoUser
    }
    
    func searchUsers(username: String) async throws -> [User] {
        print("🎭 [DEMO MODE] searchUsers called for '\(username)'")
        return DemoModeManager.shared.demoFriends.filter { $0.username.contains(username) }
    }
    
    func addReaction(to dropID: String, emoji: String) async throws {
        print("🎭 [DEMO MODE] addReaction called: \(emoji) to drop \(dropID)")
        if let index = DemoModeManager.shared.demoDrops.firstIndex(where: { $0.id == dropID }) {
            var drop = DemoModeManager.shared.demoDrops[index]
            drop.reactions[emoji, default: 0] += 1
            drop.reactionCount += 1
            DemoModeManager.shared.demoDrops[index] = drop
            self.drops = DemoModeManager.shared.demoDrops
        }
    }
    
    func removeReaction(from dropID: String, emoji: String) async throws {
        print("🎭 [DEMO MODE] removeReaction called: \(emoji) from drop \(dropID)")
        if let index = DemoModeManager.shared.demoDrops.firstIndex(where: { $0.id == dropID }) {
            var drop = DemoModeManager.shared.demoDrops[index]
            if let count = drop.reactions[emoji], count > 0 {
                drop.reactions[emoji] = count - 1
                drop.reactionCount -= 1
                if drop.reactions[emoji] == 0 {
                    drop.reactions.removeValue(forKey: emoji)
                }
                DemoModeManager.shared.demoDrops[index] = drop
                self.drops = DemoModeManager.shared.demoDrops
            }
        }
    }
    
    // Stub methods that other parts of the app might call
    func sendFriendRequest(to userID: String) async throws {
        print("🎭 [DEMO MODE] sendFriendRequest called (no-op)")
    }
    
    func acceptFriendRequest(from userID: String) async throws {
        print("🎭 [DEMO MODE] acceptFriendRequest called (no-op)")
    }
    
    func getFriendRequests() async throws -> [User] {
        print("🎭 [DEMO MODE] getFriendRequests called - returning empty")
        return []
    }
    
    func getFriends() async throws -> [User] {
        print("🎭 [DEMO MODE] getFriends called - returning demo friends")
        return DemoModeManager.shared.demoFriends
    }
    
    func deleteAccount() async throws {
        print("🎭 [DEMO MODE] deleteAccount called (no-op)")
    }
}
