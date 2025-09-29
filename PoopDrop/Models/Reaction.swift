import Foundation
import CloudKit

struct Reaction: Identifiable, Codable {
    let id: String
    let dropID: String // Link to specific Drop record
    let userID: String // Who reacted
    let username: String // Denormalized for faster UI display
    let reactionType: ReactionType // "emoji" or "text"
    let emoji: String? // Emoji reaction (all iOS emojis available)
    let textContent: String? // Text reaction (200 words max)
    let timestamp: Date // When reaction was created
    let isVisible: Bool // Moderation capability
    
    enum ReactionType: String, Codable, CaseIterable {
        case emoji = "emoji"
        case text = "text"
    }
    
    init(id: String = UUID().uuidString,
         dropID: String,
         userID: String,
         username: String,
         reactionType: ReactionType,
         emoji: String? = nil,
         textContent: String? = nil,
         isVisible: Bool = true) {
        self.id = id
        self.dropID = dropID
        self.userID = userID
        self.username = username
        self.reactionType = reactionType
        self.emoji = emoji
        self.textContent = textContent
        self.timestamp = Date()
        self.isVisible = isVisible
    }
}

// MARK: - CloudKit Extensions
extension Reaction {
    static let recordType = "Reaction"
    
    init?(from record: CKRecord) {
        guard let dropID = record["dropID"] as? String,
              let userID = record["userID"] as? String,
              let username = record["username"] as? String,
              let reactionTypeString = record["reactionType"] as? String,
              let reactionType = ReactionType(rawValue: reactionTypeString) else { return nil }
        
        self.id = record.recordID.recordName
        self.dropID = dropID
        self.userID = userID
        self.username = username
        self.reactionType = reactionType
        self.emoji = record["emoji"] as? String
        self.textContent = record["textContent"] as? String
        self.timestamp = record["timestamp"] as? Date ?? Date()
        self.isVisible = (record["isVisible"] as? Int) == 1
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Reaction.recordType, recordID: CKRecord.ID(recordName: id))
        record["dropID"] = dropID
        record["userID"] = userID
        record["username"] = username
        record["reactionType"] = reactionType.rawValue
        record["emoji"] = emoji
        record["textContent"] = textContent
        record["timestamp"] = timestamp
        record["isVisible"] = isVisible ? 1 : 0
        
        return record
    }
}

// MARK: - Sample Data
extension Reaction {
    static let sampleEmojiReaction = Reaction(
        dropID: "drop123",
        userID: "user456",
        username: "emoji_lover",
        reactionType: .emoji,
        emoji: "😂"
    )
    
    static let sampleTextReaction = Reaction(
        dropID: "drop123",
        userID: "user789",
        username: "comment_master",
        reactionType: .text,
        textContent: "That's the funniest poop story I've ever heard! 😂💩"
    )
}
