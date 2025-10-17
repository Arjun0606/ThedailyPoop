import Foundation
import CloudKit

// MARK: - Fart Attack Model
struct FartAttack: Identifiable, Codable {
    let id: String
    let senderID: String
    let senderUsername: String
    let targetUserID: String
    let targetUsername: String
    let timestamp: Date
    let soundFileName: String
    var wasPlayed: Bool
    var playedAt: Date?
    
    // Ghost Mode (anonymous attacks)
    var isGhost: Bool
    var ghostGuesses: [String] // IDs of users the target guessed
    var ghostRevealed: Bool // If target purchased full reveal
    var ghostHintPurchased: Bool // If target purchased narrow-down hint
    
    init(id: String = UUID().uuidString,
         senderID: String,
         senderUsername: String,
         targetUserID: String,
         targetUsername: String,
         timestamp: Date = Date(),
         soundFileName: String = "fart_long_epidemic",
         wasPlayed: Bool = false,
         playedAt: Date? = nil,
         isGhost: Bool = false,
         ghostGuesses: [String] = [],
         ghostRevealed: Bool = false,
         ghostHintPurchased: Bool = false) {
        self.id = id
        self.senderID = senderID
        self.senderUsername = senderUsername
        self.targetUserID = targetUserID
        self.targetUsername = targetUsername
        self.timestamp = timestamp
        self.soundFileName = soundFileName
        self.wasPlayed = wasPlayed
        self.playedAt = playedAt
        self.isGhost = isGhost
        self.ghostGuesses = ghostGuesses
        self.ghostRevealed = ghostRevealed
        self.ghostHintPurchased = ghostHintPurchased
    }
}

// MARK: - CloudKit Extensions
extension FartAttack {
    static let recordType = "FartAttack"
    
    init?(from record: CKRecord) {
        guard let senderID = record["senderID"] as? String,
              let senderUsername = record["senderUsername"] as? String,
              let targetUserID = record["targetUserID"] as? String,
              let targetUsername = record["targetUsername"] as? String,
              let timestamp = record["timestamp"] as? Date,
              let soundFileName = record["soundFileName"] as? String else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.senderID = senderID
        self.senderUsername = senderUsername
        self.targetUserID = targetUserID
        self.targetUsername = targetUsername
        self.timestamp = timestamp
        self.soundFileName = soundFileName
        self.wasPlayed = (record["wasPlayed"] as? Int) == 1
        self.playedAt = record["playedAt"] as? Date
        
        // Ghost Mode fields
        self.isGhost = (record["isGhost"] as? Int) == 1
        self.ghostGuesses = record["ghostGuesses"] as? [String] ?? []
        self.ghostRevealed = (record["ghostRevealed"] as? Int) == 1
        self.ghostHintPurchased = (record["ghostHintPurchased"] as? Int) == 1
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: FartAttack.recordType, recordID: CKRecord.ID(recordName: id))
        record["senderID"] = senderID
        record["senderUsername"] = senderUsername
        record["targetUserID"] = targetUserID
        record["targetUsername"] = targetUsername
        record["timestamp"] = timestamp
        record["soundFileName"] = soundFileName
        record["wasPlayed"] = wasPlayed ? 1 : 0
        record["playedAt"] = playedAt
        
        // Ghost Mode fields
        record["isGhost"] = isGhost ? 1 : 0
        record["ghostGuesses"] = ghostGuesses
        record["ghostRevealed"] = ghostRevealed ? 1 : 0
        record["ghostHintPurchased"] = ghostHintPurchased ? 1 : 0
        
        return record
    }
}

// MARK: - Fart Attack Inventory
struct FartAttackInventory: Codable {
    let userID: String
    var availableAttacks: Int // All attacks are ghost attacks now!
    var lastUpdated: Date
    
    // Track cooldowns: [friendUserID: lastAttackTimestamp]
    var cooldowns: [String: Date]
    
    init(userID: String,
         availableAttacks: Int = 0,
         lastUpdated: Date = Date(),
         cooldowns: [String: Date] = [:]) {
        self.userID = userID
        self.availableAttacks = availableAttacks
        self.lastUpdated = lastUpdated
        self.cooldowns = cooldowns
    }
    
    // Check if can attack a specific friend (24hr cooldown)
    func canAttack(friendID: String) -> Bool {
        guard let lastAttack = cooldowns[friendID] else {
            return true // Never attacked this friend
        }
        
        let hoursSinceLastAttack = Date().timeIntervalSince(lastAttack) / 3600
        return hoursSinceLastAttack >= 24
    }
    
    // Get time remaining until can attack again
    func cooldownRemaining(friendID: String) -> TimeInterval? {
        guard let lastAttack = cooldowns[friendID] else {
            return nil // No cooldown
        }
        
        let elapsed = Date().timeIntervalSince(lastAttack)
        let remaining = (24 * 3600) - elapsed
        return remaining > 0 ? remaining : nil
    }
    
    // Add attacks from purchase
    mutating func addAttacks(_ count: Int) {
        availableAttacks += count
        lastUpdated = Date()
    }
    
    // Use an attack on a friend (all attacks are ghost now)
    mutating func useAttack(targetFriendID: String) -> Bool {
        // Check cooldown
        guard canAttack(friendID: targetFriendID) else {
            return false
        }
        
        // Check inventory
        guard availableAttacks > 0 else { return false }
        availableAttacks -= 1
        
        cooldowns[targetFriendID] = Date()
        lastUpdated = Date()
        return true
    }
}

// MARK: - CloudKit Extensions for Inventory
extension FartAttackInventory {
    static let recordType = "FartAttackInventory"
    
    init?(from record: CKRecord) {
        guard let userID = record["userID"] as? String else { return nil }
        
        self.userID = userID
        self.availableAttacks = record["availableAttacks"] as? Int ?? 0
        self.lastUpdated = record["lastUpdated"] as? Date ?? Date()
        
        // Decode cooldowns dictionary
        if let cooldownsData = record["cooldowns"] as? Data {
            self.cooldowns = (try? JSONDecoder().decode([String: Date].self, from: cooldownsData)) ?? [:]
        } else {
            self.cooldowns = [:]
        }
    }
    
    func toCKRecord() -> CKRecord {
        // Use "inventory_" prefix to avoid conflict with User records
        let record = CKRecord(recordType: FartAttackInventory.recordType, recordID: CKRecord.ID(recordName: "inventory_\(userID)"))
        record["userID"] = userID
        record["availableAttacks"] = availableAttacks
        record["lastUpdated"] = lastUpdated
        
        // Encode cooldowns dictionary
        if let cooldownsData = try? JSONEncoder().encode(cooldowns) {
            record["cooldowns"] = cooldownsData
        }
        
        return record
    }
}

// MARK: - IAP Product IDs
struct IAPProducts {
    // ONLY ONE IAP: Gossip Reveal ($1.99)
    static let gossipReveal = "com.thedailypoop.pollreveal" // $1.99 (keeping same ID from poll reveal)
    
    // All product IDs (1 total - MAXIMUM SIMPLIFICATION!)
    static let allProducts = [
        gossipReveal
    ]
}
