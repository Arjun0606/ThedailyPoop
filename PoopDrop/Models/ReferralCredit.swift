import Foundation
import CloudKit

/// Represents a referral credit awarded when someone installs via an external link
struct ReferralCredit: Identifiable, Codable {
    let id: String
    let referrerID: String // User who sent the external attack
    let recipientID: String // User who clicked and installed
    let claimed: Bool
    let rewardCount: Int // Number of attacks to award (default: 1)
    let timestamp: Date
    
    static let recordType = "ReferralCredit"
    
    init(
        id: String = UUID().uuidString,
        referrerID: String,
        recipientID: String,
        claimed: Bool = false,
        rewardCount: Int = 1,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.referrerID = referrerID
        self.recipientID = recipientID
        self.claimed = claimed
        self.rewardCount = rewardCount
        self.timestamp = timestamp
    }
    
    // MARK: - CloudKit
    
    init?(from record: CKRecord) {
        guard
            let referrerID = record["referrerID"] as? String,
            let recipientID = record["recipientID"] as? String,
            let claimed = record["claimed"] as? Int,
            let timestamp = record["timestamp"] as? Date
        else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.referrerID = referrerID
        self.recipientID = recipientID
        self.claimed = claimed == 1
        self.rewardCount = record["rewardCount"] as? Int ?? 1
        self.timestamp = timestamp
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: CKRecord.ID(recordName: id))
        record["referrerID"] = referrerID as CKRecordValue
        record["recipientID"] = recipientID as CKRecordValue
        record["claimed"] = (claimed ? 1 : 0) as CKRecordValue
        record["rewardCount"] = rewardCount as CKRecordValue
        record["timestamp"] = timestamp as CKRecordValue
        return record
    }
}
