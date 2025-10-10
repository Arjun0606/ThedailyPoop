import Foundation
import CloudKit

// MARK: - Fart Attack Model
struct FartAttack: Identifiable, Codable {
    let id: String
    let senderID: String
    let senderUsername: String
    let targetUserID: String // Empty string for external shares
    let targetUsername: String
    let timestamp: Date
    let soundFileName: String
    var wasPlayed: Bool
    var playedAt: Date?
    
    // External sharing fields
    let isExternal: Bool // true if sent outside app
    let recipientIdentifier: String? // Hashed phone/email for cooldown tracking
    var clickedAt: Date? // When the link was clicked
    var installedApp: Bool // Whether recipient installed after clicking
    
    init(id: String = UUID().uuidString,
         senderID: String,
         senderUsername: String,
         targetUserID: String,
         targetUsername: String,
         timestamp: Date = Date(),
         soundFileName: String = "fart_long_epidemic",
         wasPlayed: Bool = false,
         playedAt: Date? = nil,
         isExternal: Bool = false,
         recipientIdentifier: String? = nil,
         clickedAt: Date? = nil,
         installedApp: Bool = false) {
        self.id = id
        self.senderID = senderID
        self.senderUsername = senderUsername
        self.targetUserID = targetUserID
        self.targetUsername = targetUsername
        self.timestamp = timestamp
        self.soundFileName = soundFileName
        self.wasPlayed = wasPlayed
        self.playedAt = playedAt
        self.isExternal = isExternal
        self.recipientIdentifier = recipientIdentifier
        self.clickedAt = clickedAt
        self.installedApp = installedApp
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
        self.isExternal = (record["isExternal"] as? Int) == 1
        self.recipientIdentifier = record["recipientIdentifier"] as? String
        self.clickedAt = record["clickedAt"] as? Date
        self.installedApp = (record["installedApp"] as? Int) == 1
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
        record["isExternal"] = isExternal ? 1 : 0
        record["recipientIdentifier"] = recipientIdentifier
        record["clickedAt"] = clickedAt
        record["installedApp"] = installedApp ? 1 : 0
        return record
    }
}

// MARK: - Fart Attack Inventory
struct FartAttackInventory: Codable {
    let userID: String
    var availableAttacks: Int
    var lastUpdated: Date
    
    // Track cooldowns: [friendUserID: lastAttackTimestamp]
    var cooldowns: [String: Date]
    
    // Track external share cooldowns: [recipientHash: lastAttackTimestamp]
    var externalCooldowns: [String: Date]
    
    // Daily limit for external shares (prevent spam)
    var externalSharesToday: Int
    var lastExternalShareDate: Date
    
    init(userID: String,
         availableAttacks: Int = 0,
         lastUpdated: Date = Date(),
         cooldowns: [String: Date] = [:],
         externalCooldowns: [String: Date] = [:],
         externalSharesToday: Int = 0,
         lastExternalShareDate: Date = Date(timeIntervalSince1970: 0)) {
        self.userID = userID
        self.availableAttacks = availableAttacks
        self.lastUpdated = lastUpdated
        self.cooldowns = cooldowns
        self.externalCooldowns = externalCooldowns
        self.externalSharesToday = externalSharesToday
        self.lastExternalShareDate = lastExternalShareDate
    }
    
    // Check if can attack a specific friend (24hr cooldown)
    func canAttack(friendID: String) -> Bool {
        guard let lastAttack = cooldowns[friendID] else {
            return true // Never attacked this friend
        }
        
        let hoursSinceLastAttack = Date().timeIntervalSince(lastAttack) / 3600
        return hoursSinceLastAttack >= 24
    }
    
    // Check if can attack an external recipient (24hr cooldown)
    func canAttackExternal(recipientHash: String) -> Bool {
        guard let lastAttack = externalCooldowns[recipientHash] else {
            return true // Never attacked this recipient
        }
        
        let hoursSinceLastAttack = Date().timeIntervalSince(lastAttack) / 3600
        return hoursSinceLastAttack >= 24
    }
    
    // Check daily limit for external shares (max 20 per day)
    mutating func canShareExternally() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastShareDay = calendar.startOfDay(for: lastExternalShareDate)
        
        // Reset counter if it's a new day
        if today > lastShareDay {
            externalSharesToday = 0
        }
        
        return externalSharesToday < 20 // Max 20 external shares per day
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
    
    // Get time remaining for external recipient
    func externalCooldownRemaining(recipientHash: String) -> TimeInterval? {
        guard let lastAttack = externalCooldowns[recipientHash] else {
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
    
    // Use an attack (in-app friend)
    mutating func useAttack(targetFriendID: String) -> Bool {
        guard availableAttacks > 0, canAttack(friendID: targetFriendID) else {
            return false
        }
        
        availableAttacks -= 1
        cooldowns[targetFriendID] = Date()
        lastUpdated = Date()
        return true
    }
    
    // Use an attack (external recipient)
    mutating func useExternalAttack(recipientHash: String) -> Bool {
        guard availableAttacks > 0, 
              canAttackExternal(recipientHash: recipientHash),
              canShareExternally() else {
            return false
        }
        
        availableAttacks -= 1
        externalCooldowns[recipientHash] = Date()
        
        // Update daily counter
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastShareDay = calendar.startOfDay(for: lastExternalShareDate)
        
        if today > lastShareDay {
            externalSharesToday = 1
        } else {
            externalSharesToday += 1
        }
        
        lastExternalShareDate = Date()
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
        
        // Decode external cooldowns dictionary
        if let externalCooldownsData = record["externalCooldowns"] as? Data {
            self.externalCooldowns = (try? JSONDecoder().decode([String: Date].self, from: externalCooldownsData)) ?? [:]
        } else {
            self.externalCooldowns = [:]
        }
        
        self.externalSharesToday = record["externalSharesToday"] as? Int ?? 0
        self.lastExternalShareDate = record["lastExternalShareDate"] as? Date ?? Date(timeIntervalSince1970: 0)
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
        
        // Encode external cooldowns dictionary
        if let externalCooldownsData = try? JSONEncoder().encode(externalCooldowns) {
            record["externalCooldowns"] = externalCooldownsData
        }
        
        record["externalSharesToday"] = externalSharesToday
        record["lastExternalShareDate"] = lastExternalShareDate
        
        return record
    }
}

// MARK: - Fart Attack Pack Product
struct FartAttackPack {
    static let productID = "com.thedailypoop.fartattack.pack" // Single $1.99 pack
    static let attacksPerPack = 3
    static let name = "Fart Attack Pack"
    static let emoji = "💨"
}

