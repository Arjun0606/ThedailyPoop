import Foundation
import CloudKit

// MARK: - Gossip Post Model
struct GossipPost: Identifiable, Codable {
    let id: String
    let posterID: String // Hidden from users (anonymous)
    let posterUsername: String // Hidden from users
    let text: String // The gossip content
    let mentionedUserIDs: [String] // People mentioned (@username)
    let mentionedUsernames: [String] // For display
    var mentionedDropIDs: [String] // Drops referenced in gossip (for cross-tab integration)
    let createdAt: Date
    let expiresAt: Date // 24 hours from creation
    var isAnonymous: Bool = true
    var reactions: [String: Int] // [emoji: count] e.g. ["😂": 5, "😱": 3]
    var viewCount: Int
    var replyCount: Int
    var revealedBy: [String] = [] // User IDs who have revealed this gossip
    var screenshotBy: [String] = [] // User IDs who have screenshotted this gossip
    var screenshotUsernames: [String] = [] // Usernames for display (e.g. "@arjun, @mike")
    var screenshotTimestamps: [String: Date] = [:] // [userID: timestamp] for 24h expiry
    var photoURL: String? // NEW: CloudKit photo asset URL (optional)
    
    init(id: String = UUID().uuidString,
         posterID: String,
         posterUsername: String,
         text: String,
         mentionedUserIDs: [String] = [],
         mentionedUsernames: [String] = [],
         mentionedDropIDs: [String] = [],
         createdAt: Date = Date(),
         expiresAt: Date = Date().addingTimeInterval(86400), // 24 hours
         isAnonymous: Bool = true,
         reactions: [String: Int] = [:],
         viewCount: Int = 0,
         replyCount: Int = 0,
         revealedBy: [String] = [],
         screenshotBy: [String] = [],
         screenshotUsernames: [String] = [],
         screenshotTimestamps: [String: Date] = [:],
         photoURL: String? = nil) {
        self.id = id
        self.posterID = posterID
        self.posterUsername = posterUsername
        self.text = text
        self.mentionedUserIDs = mentionedUserIDs
        self.mentionedUsernames = mentionedUsernames
        self.mentionedDropIDs = mentionedDropIDs
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isAnonymous = isAnonymous
        self.reactions = reactions
        self.viewCount = viewCount
        self.replyCount = replyCount
        self.revealedBy = revealedBy
        self.screenshotBy = screenshotBy
        self.screenshotUsernames = screenshotUsernames
        self.screenshotTimestamps = screenshotTimestamps
        self.photoURL = photoURL
    }
    
    // MARK: - Screenshot Expiry Helper
    
    /// Get usernames of screenshots taken within last 24 hours
    func activeScreenshotUsernames() -> [String] {
        let cutoff = Date().addingTimeInterval(-86400) // 24 hours ago
        var active: [String] = []
        
        for (index, userID) in screenshotBy.enumerated() {
            if let timestamp = screenshotTimestamps[userID], timestamp > cutoff {
                if index < screenshotUsernames.count {
                    active.append(screenshotUsernames[index])
                }
            }
        }
        
        return active
    }
}

// MARK: - CloudKit Extensions
extension GossipPost {
    static let recordType = "GossipPost"
    
    init?(from record: CKRecord) {
        guard let posterID = record["posterID"] as? String,
              let posterUsername = record["posterUsername"] as? String,
              let text = record["text"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let expiresAt = record["expiresAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.posterID = posterID
        self.posterUsername = posterUsername
        self.text = text
        self.mentionedUserIDs = record["mentionedUserIDs"] as? [String] ?? []
        self.mentionedUsernames = record["mentionedUsernames"] as? [String] ?? []
        self.mentionedDropIDs = record["mentionedDropIDs"] as? [String] ?? []
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isAnonymous = (record["isAnonymous"] as? Int) == 1
        self.viewCount = record["viewCount"] as? Int ?? 0
        self.replyCount = record["replyCount"] as? Int ?? 0
        self.revealedBy = record["revealedBy"] as? [String] ?? []
        self.screenshotBy = record["screenshotBy"] as? [String] ?? []
        self.screenshotUsernames = record["screenshotUsernames"] as? [String] ?? []
        
        // Decode reactions dictionary
        if let reactionsData = record["reactions"] as? Data,
           let reactions = try? JSONDecoder().decode([String: Int].self, from: reactionsData) {
            self.reactions = reactions
        } else {
            self.reactions = [:]
        }
        
        // Decode screenshot timestamps dictionary
        if let timestampsData = record["screenshotTimestamps"] as? Data,
           let timestamps = try? JSONDecoder().decode([String: Date].self, from: timestampsData) {
            self.screenshotTimestamps = timestamps
        } else {
            self.screenshotTimestamps = [:]
        }
        
        // NEW: Load photo URL
        self.photoURL = record["photoURL"] as? String
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: GossipPost.recordType, recordID: CKRecord.ID(recordName: id))
        record["posterID"] = posterID
        record["posterUsername"] = posterUsername
        record["text"] = text
        record["mentionedUserIDs"] = mentionedUserIDs
        record["mentionedUsernames"] = mentionedUsernames
        
        // Only save mentionedDropIDs if not empty (prevents CloudKit error)
        if !mentionedDropIDs.isEmpty {
            record["mentionedDropIDs"] = mentionedDropIDs
        }
        
        record["createdAt"] = createdAt
        record["expiresAt"] = expiresAt
        record["isAnonymous"] = isAnonymous ? 1 : 0
        record["viewCount"] = viewCount
        record["replyCount"] = replyCount
        
        // Only save revealedBy if not empty (prevents CloudKit error)
        if !revealedBy.isEmpty {
            record["revealedBy"] = revealedBy
        }
        
        // Only save screenshot data if not empty (prevents CloudKit error)
        if !screenshotBy.isEmpty {
            record["screenshotBy"] = screenshotBy
            record["screenshotUsernames"] = screenshotUsernames
            
            // Encode screenshot timestamps dictionary
            if let timestampsData = try? JSONEncoder().encode(screenshotTimestamps) {
                record["screenshotTimestamps"] = timestampsData
            }
        }
        
        // Encode reactions dictionary
        if let reactionsData = try? JSONEncoder().encode(reactions) {
            record["reactions"] = reactionsData
        }
        
        // NEW: Save photo URL if present
        if let photoURL = photoURL {
            record["photoURL"] = photoURL
        }
        
        return record
    }
}

// MARK: - Gossip Reply Model (Reddit-style threaded)
struct GossipReply: Identifiable, Codable {
    let id: String
    let originalGossipID: String
    let parentReplyID: String? // nil for top-level, set for nested replies
    let replyText: String
    let replierID: String // Hidden if anonymous
    let replierUsername: String // Hidden if anonymous
    let isAnonymous: Bool
    let createdAt: Date
    var nestedReplies: [GossipReply] = [] // For UI hierarchical display
    
    init(id: String = UUID().uuidString,
         originalGossipID: String,
         parentReplyID: String? = nil,
         replyText: String,
         replierID: String,
         replierUsername: String,
         isAnonymous: Bool = true,
         createdAt: Date = Date(),
         nestedReplies: [GossipReply] = []) {
        self.id = id
        self.originalGossipID = originalGossipID
        self.parentReplyID = parentReplyID
        self.replyText = replyText
        self.replierID = replierID
        self.replierUsername = replierUsername
        self.isAnonymous = isAnonymous
        self.createdAt = createdAt
        self.nestedReplies = nestedReplies
    }
}

// MARK: - CloudKit Extensions
extension GossipReply {
    static let recordType = "GossipReply"
    
    init?(from record: CKRecord) {
        guard let originalGossipID = record["originalGossipID"] as? String,
              let replyText = record["replyText"] as? String,
              let replierID = record["replierID"] as? String,
              let replierUsername = record["replierUsername"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.originalGossipID = originalGossipID
        self.parentReplyID = record["parentReplyID"] as? String // Optional for nested replies
        self.replyText = replyText
        self.replierID = replierID
        self.replierUsername = replierUsername
        self.isAnonymous = (record["isAnonymous"] as? Int) == 1
        self.createdAt = createdAt
        self.nestedReplies = [] // Will be populated by GossipManager
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: GossipReply.recordType, recordID: CKRecord.ID(recordName: id))
        record["originalGossipID"] = originalGossipID
        if let parentID = parentReplyID {
            record["parentReplyID"] = parentID
        }
        record["replyText"] = replyText
        record["replierID"] = replierID
        record["replierUsername"] = replierUsername
        record["isAnonymous"] = isAnonymous ? 1 : 0
        record["createdAt"] = createdAt
        return record
    }
}

// MARK: - Gossip Reveal Purchase
struct GossipReveal: Identifiable, Codable {
    let id: String
    let gossipID: String
    let revealedToUserID: String // Who paid to see
    let revealedPosterID: String // The actual poster
    let revealedPosterUsername: String
    let paidAmount: Double // $1.99
    let revealedAt: Date
    
    init(id: String = UUID().uuidString,
         gossipID: String,
         revealedToUserID: String,
         revealedPosterID: String,
         revealedPosterUsername: String,
         paidAmount: Double = 1.99,
         revealedAt: Date = Date()) {
        self.id = id
        self.gossipID = gossipID
        self.revealedToUserID = revealedToUserID
        self.revealedPosterID = revealedPosterID
        self.revealedPosterUsername = revealedPosterUsername
        self.paidAmount = paidAmount
        self.revealedAt = revealedAt
    }
}

// MARK: - CloudKit Extensions
extension GossipReveal {
    static let recordType = "GossipReveal"
    
    init?(from record: CKRecord) {
        guard let gossipID = record["gossipID"] as? String,
              let revealedToUserID = record["revealedToUserID"] as? String,
              let revealedPosterID = record["revealedPosterID"] as? String,
              let revealedPosterUsername = record["revealedPosterUsername"] as? String,
              let paidAmount = record["paidAmount"] as? Double,
              let revealedAt = record["revealedAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.gossipID = gossipID
        self.revealedToUserID = revealedToUserID
        self.revealedPosterID = revealedPosterID
        self.revealedPosterUsername = revealedPosterUsername
        self.paidAmount = paidAmount
        self.revealedAt = revealedAt
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: GossipReveal.recordType, recordID: CKRecord.ID(recordName: id))
        record["gossipID"] = gossipID
        record["revealedToUserID"] = revealedToUserID
        record["revealedPosterID"] = revealedPosterID
        record["revealedPosterUsername"] = revealedPosterUsername
        record["paidAmount"] = paidAmount
        record["revealedAt"] = revealedAt
        return record
    }
}

// MARK: - Helper Extensions
extension Date {
    func timeAgoString() -> String {
        let interval = Date().timeIntervalSince(self)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

