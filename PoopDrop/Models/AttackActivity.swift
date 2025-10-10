import Foundation
import CloudKit

enum AttackActivityType: String, Codable {
    case sent = "sent"
    case reacted = "reacted"
}

/// Represents a public activity related to Fart Attacks (sent, reacted, etc.)
struct AttackActivity: Identifiable, Codable {
    let id: String
    let type: AttackActivityType
    let senderID: String
    let senderUsername: String
    let targetUserID: String?
    let targetUsername: String?
    let attackID: String?
    let reactionEmoji: String?
    let reactionText: String?
    let timestamp: Date
    
    static let recordType = "AttackActivity"
    
    init(
        id: String = UUID().uuidString,
        type: AttackActivityType,
        senderID: String,
        senderUsername: String,
        targetUserID: String? = nil,
        targetUsername: String? = nil,
        attackID: String? = nil,
        reactionEmoji: String? = nil,
        reactionText: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.senderID = senderID
        self.senderUsername = senderUsername
        self.targetUserID = targetUserID
        self.targetUsername = targetUsername
        self.attackID = attackID
        self.reactionEmoji = reactionEmoji
        self.reactionText = reactionText
        self.timestamp = timestamp
    }
    
    // MARK: - CloudKit
    
    init?(from record: CKRecord) {
        guard
            let typeString = record["type"] as? String,
            let type = AttackActivityType(rawValue: typeString),
            let senderID = record["senderID"] as? String,
            let senderUsername = record["senderUsername"] as? String,
            let timestamp = record["timestamp"] as? Date
        else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.type = type
        self.senderID = senderID
        self.senderUsername = senderUsername
        self.targetUserID = record["targetUserID"] as? String
        self.targetUsername = record["targetUsername"] as? String
        self.attackID = record["attackID"] as? String
        self.reactionEmoji = record["reactionEmoji"] as? String
        self.reactionText = record["reactionText"] as? String
        self.timestamp = timestamp
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["type"] = type.rawValue as CKRecordValue
        record["senderID"] = senderID as CKRecordValue
        record["senderUsername"] = senderUsername as CKRecordValue
        if let targetUserID = targetUserID {
            record["targetUserID"] = targetUserID as CKRecordValue
        }
        if let targetUsername = targetUsername {
            record["targetUsername"] = targetUsername as CKRecordValue
        }
        if let attackID = attackID {
            record["attackID"] = attackID as CKRecordValue
        }
        if let reactionEmoji = reactionEmoji {
            record["reactionEmoji"] = reactionEmoji as CKRecordValue
        }
        if let reactionText = reactionText {
            record["reactionText"] = reactionText as CKRecordValue
        }
        record["timestamp"] = timestamp as CKRecordValue
        return record
    }
}
