import Foundation
import CloudKit
import CoreLocation

/// Demo CloudKit Manager - Overrides CloudKitManager for demo mode
/// Returns pre-loaded demo data instead of fetching from CloudKit
@MainActor
class DemoCloudKitManager: CloudKitManager {
    
    override init() {
        super.init()
        // Immediately load demo drops
        self.drops = DemoModeManager.shared.demoDrops
    }
    
    // Override all fetch methods to return demo data
    override func fetchDrops(limit: Int = 100) async throws -> [Drop] {
        print("🎭 [DEMO MODE] Returning \(DemoModeManager.shared.demoDrops.count) demo drops instead of fetching from CloudKit")
        self.drops = DemoModeManager.shared.demoDrops
        return DemoModeManager.shared.demoDrops
    }
    
    override func fetchUserDrops(userID: String, limit: Int = 50) async throws -> [Drop] {
        print("🎭 [DEMO MODE] Returning user drops for \(userID)")
        let userDrops = DemoModeManager.shared.demoDrops.filter { $0.userID == userID }
        return userDrops
    }
    
    func fetchUserDrops(for user: User) async throws -> [Drop] {
        return try await fetchUserDrops(userID: user.id, limit: 50)
    }
    
    override func fetchNearbyDrops(coordinate: CLLocationCoordinate2D, radiusKm: Double = 50) async throws -> [Drop] {
        print("🎭 [DEMO MODE] Returning all demo drops as 'nearby' drops")
        self.drops = DemoModeManager.shared.demoDrops
        return DemoModeManager.shared.demoDrops
    }
    
    override func createDrop(_ drop: Drop) async throws -> Drop {
        print("🎭 [DEMO MODE] Adding new drop to demo data")
        // Add to demo drops
        DemoModeManager.shared.demoDrops.insert(drop, at: 0)
        self.drops = DemoModeManager.shared.demoDrops
        return drop
    }
    
    override func saveUser(_ user: User) async throws {
        print("🎭 [DEMO MODE] Updating demo user")
        DemoModeManager.shared.demoUser = user
    }
    
    override func fetchUserByAppleUserID(_ appleUserID: String) async throws -> User? {
        print("🎭 [DEMO MODE] Returning demo user")
        return DemoModeManager.shared.demoUser
    }
    
    override func searchUsers(username: String) async throws -> [User] {
        print("🎭 [DEMO MODE] Searching demo friends for '\(username)'")
        return DemoModeManager.shared.demoFriends.filter { $0.username.contains(username) }
    }
    
    override func addReaction(to dropID: String, emoji: String) async throws {
        print("🎭 [DEMO MODE] Adding reaction \(emoji) to drop \(dropID)")
        if let index = DemoModeManager.shared.demoDrops.firstIndex(where: { $0.id == dropID }) {
            var drop = DemoModeManager.shared.demoDrops[index]
            drop.reactions[emoji, default: 0] += 1
            drop.reactionCount += 1
            DemoModeManager.shared.demoDrops[index] = drop
            self.drops = DemoModeManager.shared.demoDrops
        }
    }
    
    override func removeReaction(from dropID: String, emoji: String) async throws {
        print("🎭 [DEMO MODE] Removing reaction \(emoji) from drop \(dropID)")
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
}

