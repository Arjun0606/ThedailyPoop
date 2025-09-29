import Foundation
import CloudKit

struct PoopNotification: Identifiable, Codable {
    let id: String
    let recipientID: String // Who receives the notification
    let senderID: String // Who triggered the notification
    let dropID: String? // Related drop (for poop notifications)
    let type: NotificationType // Type of notification
    let title: String // Notification title
    let body: String // Notification body text
    let soundFile: String? // Random bathroom sound file name
    let isRead: Bool // Read status
    let timestamp: Date // When notification was created
    let deliveredAt: Date? // When notification was sent
    
    enum NotificationType: String, Codable, CaseIterable {
        case poopDrop = "poop_drop"
        case friendRequest = "friend_request"
        case friendAccepted = "friend_accepted"
        case streakBreak = "streak_break"
        case badgeEarned = "badge_earned"
        case reaction = "reaction"
    }
    
    init(id: String = UUID().uuidString,
         recipientID: String,
         senderID: String,
         dropID: String? = nil,
         type: NotificationType,
         title: String,
         body: String,
         soundFile: String? = nil,
         isRead: Bool = false) {
        self.id = id
        self.recipientID = recipientID
        self.senderID = senderID
        self.dropID = dropID
        self.type = type
        self.title = title
        self.body = body
        self.soundFile = soundFile
        self.isRead = isRead
        self.timestamp = Date()
        self.deliveredAt = nil
    }
    
    // Helper method to get random bathroom sound
    static func randomBathroomSound() -> String {
        let sounds = [
            "fart_short.wav",
            "fart_long.wav",
            "flush.wav",
            "splash.wav",
            "bubble_fart.wav",
            "squeaky_fart.wav",
            "plop.wav"
        ]
        return sounds.randomElement() ?? "fart_short.wav"
    }
}

// MARK: - CloudKit Extensions
extension PoopNotification {
    static let recordType = "Notification"
    
    init?(from record: CKRecord) {
        guard let recipientID = record["recipientID"] as? String,
              let senderID = record["senderID"] as? String,
              let typeString = record["type"] as? String,
              let type = NotificationType(rawValue: typeString),
              let title = record["title"] as? String,
              let body = record["body"] as? String else { return nil }
        
        self.id = record.recordID.recordName
        self.recipientID = recipientID
        self.senderID = senderID
        self.dropID = record["dropID"] as? String
        self.type = type
        self.title = title
        self.body = body
        self.soundFile = record["soundFile"] as? String
        self.isRead = (record["isRead"] as? Int) == 1
        self.timestamp = record["timestamp"] as? Date ?? Date()
        self.deliveredAt = record["deliveredAt"] as? Date
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: PoopNotification.recordType, recordID: CKRecord.ID(recordName: id))
        record["recipientID"] = recipientID
        record["senderID"] = senderID
        record["dropID"] = dropID
        record["type"] = type.rawValue
        record["title"] = title
        record["body"] = body
        record["soundFile"] = soundFile
        record["isRead"] = isRead ? 1 : 0
        record["timestamp"] = timestamp
        record["deliveredAt"] = deliveredAt
        
        return record
    }
}

// MARK: - Sample Data
extension PoopNotification {
    static let samplePoopNotification = PoopNotification(
        recipientID: "user456",
        senderID: "user123",
        dropID: "drop789",
        type: .poopDrop,
        title: "Fresh Drop Alert! 💩",
        body: "poopmaster just dropped a poop in San Francisco!",
        soundFile: "fart_short.wav"
    )
    
    static let sampleFriendRequest = PoopNotification(
        recipientID: "user456",
        senderID: "user123",
        type: .friendRequest,
        title: "New Friend Request! 👥",
        body: "poopmaster wants to be your poop buddy!",
        soundFile: "bubble_fart.wav"
    )
}
