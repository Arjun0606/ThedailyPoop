import Foundation
import CloudKit

struct Friendship: Identifiable, Codable {
    let id: String
    let requesterID: String // Who sent the friend request
    let recipientID: String // Who received the friend request
    let status: FriendshipStatus // Current status of the relationship
    let createdAt: Date // When request was sent
    let acceptedAt: Date? // When friendship was established
    
    enum FriendshipStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case accepted = "accepted"
        case blocked = "blocked"
        case declined = "declined"
    }
    
    init(id: String = UUID().uuidString,
         requesterID: String,
         recipientID: String,
         status: FriendshipStatus = .pending) {
        self.id = id
        self.requesterID = requesterID
        self.recipientID = recipientID
        self.status = status
        self.createdAt = Date()
        self.acceptedAt = status == .accepted ? Date() : nil
    }
    
    // Helper methods
    func involves(userID: String) -> Bool {
        return requesterID == userID || recipientID == userID
    }
    
    func otherUser(thanUserID userID: String) -> String? {
        if requesterID == userID {
            return recipientID
        } else if recipientID == userID {
            return requesterID
        }
        return nil
    }
    
    func isRequester(userID: String) -> Bool {
        return requesterID == userID
    }
    
    func isRecipient(userID: String) -> Bool {
        return recipientID == userID
    }
}

// MARK: - CloudKit Extensions
extension Friendship {
    static let recordType = "Friendship"
    
    init?(from record: CKRecord) {
        guard let requesterID = record["requesterID"] as? String,
              let recipientID = record["recipientID"] as? String,
              let statusString = record["status"] as? String,
              let status = FriendshipStatus(rawValue: statusString) else { return nil }
        
        self.id = record.recordID.recordName
        self.requesterID = requesterID
        self.recipientID = recipientID
        self.status = status
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.acceptedAt = record["acceptedAt"] as? Date
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Friendship.recordType, recordID: CKRecord.ID(recordName: id))
        record["requesterID"] = requesterID
        record["recipientID"] = recipientID
        record["status"] = status.rawValue
        record["createdAt"] = createdAt
        record["acceptedAt"] = acceptedAt
        
        return record
    }
}

// MARK: - Sample Data
extension Friendship {
    static let samplePendingFriendship = Friendship(
        requesterID: "user123",
        recipientID: "user456",
        status: .pending
    )
    
    static let sampleAcceptedFriendship = Friendship(
        requesterID: "user123",
        recipientID: "user789",
        status: .accepted
    )
}
