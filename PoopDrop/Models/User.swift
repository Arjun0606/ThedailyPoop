import Foundation
import CloudKit

struct User: Identifiable, Codable {
    let id: String
    var displayName: String
    var avatarURL: URL?
    var isPro: Bool
    var streak: Int
    var city: String?
    var createdAt: Date
    var lastDropDate: Date?
    var totalDrops: Int
    var maxDropsInDay: Int // Highest number of poops in a single day
    var longestNoPoopStreak: Int // Most days gone without pooping
    var friends: [String] // Array of friend user IDs
    var friendRequests: [String] // Pending friend request IDs
    var lastStreakDate: Date? // Track when streak was last maintained
    
    init(id: String = UUID().uuidString, 
         displayName: String, 
         avatarURL: URL? = nil, 
         isPro: Bool = false, 
         streak: Int = 0, 
         city: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.isPro = isPro
        self.streak = streak
        self.city = city
        self.createdAt = Date()
        self.lastDropDate = nil
        self.totalDrops = 0
        self.maxDropsInDay = 0
        self.longestNoPoopStreak = 0
        self.friends = []
        self.friendRequests = []
        self.lastStreakDate = nil
    }
}

// MARK: - CloudKit Extensions
extension User {
    static let recordType = "User"
    
    init?(from record: CKRecord) {
        guard let displayName = record["displayName"] as? String else { return nil }
        
        self.id = record.recordID.recordName
        self.displayName = displayName
        self.avatarURL = record["avatarURL"] as? URL
        self.isPro = record["isPro"] as? Bool ?? false
        self.streak = record["streak"] as? Int ?? 0
        self.city = record["city"] as? String
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.lastDropDate = record["lastDropDate"] as? Date
        self.totalDrops = record["totalDrops"] as? Int ?? 0
        self.maxDropsInDay = record["maxDropsInDay"] as? Int ?? 0
        self.longestNoPoopStreak = record["longestNoPoopStreak"] as? Int ?? 0
        
        // Decode friends array from CloudKit
        if let friendsData = record["friends"] as? Data {
            self.friends = (try? JSONDecoder().decode([String].self, from: friendsData)) ?? []
        } else {
            self.friends = []
        }
        
        // Decode friend requests array from CloudKit
        if let requestsData = record["friendRequests"] as? Data {
            self.friendRequests = (try? JSONDecoder().decode([String].self, from: requestsData)) ?? []
        } else {
            self.friendRequests = []
        }
        
        self.lastStreakDate = record["lastStreakDate"] as? Date
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: User.recordType, recordID: CKRecord.ID(recordName: id))
        record["displayName"] = displayName
        record["avatarURL"] = avatarURL
        record["isPro"] = isPro
        record["streak"] = streak
        record["city"] = city
        record["createdAt"] = createdAt
        record["lastDropDate"] = lastDropDate
        record["totalDrops"] = totalDrops
        record["maxDropsInDay"] = maxDropsInDay
        record["longestNoPoopStreak"] = longestNoPoopStreak
        record["lastStreakDate"] = lastStreakDate
        
        // Encode friends array for CloudKit
        if let friendsData = try? JSONEncoder().encode(friends) {
            record["friends"] = friendsData
        }
        
        // Encode friend requests array for CloudKit
        if let requestsData = try? JSONEncoder().encode(friendRequests) {
            record["friendRequests"] = requestsData
        }
        
        return record
    }
}

// MARK: - Sample Data
extension User {
    static let sampleUser = User(
        displayName: "Poop Master",
        isPro: true,
        streak: 7,
        city: "San Francisco"
    )
}
        
        self.lastStreakDate = record["lastStreakDate"] as? Date
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: User.recordType, recordID: CKRecord.ID(recordName: id))
        record["displayName"] = displayName
        record["avatarURL"] = avatarURL
        record["isPro"] = isPro
        record["streak"] = streak
        record["city"] = city
        record["createdAt"] = createdAt
        record["lastDropDate"] = lastDropDate
        record["totalDrops"] = totalDrops
        record["maxDropsInDay"] = maxDropsInDay
        record["longestNoPoopStreak"] = longestNoPoopStreak
        record["lastStreakDate"] = lastStreakDate
        
        // Encode friends array for CloudKit
        if let friendsData = try? JSONEncoder().encode(friends) {
            record["friends"] = friendsData
        }
        
        // Encode friend requests array for CloudKit
        if let requestsData = try? JSONEncoder().encode(friendRequests) {
            record["friendRequests"] = requestsData
        }
        
        return record
    }
}

// MARK: - Sample Data
extension User {
    static let sampleUser = User(
        displayName: "Poop Master",
        isPro: true,
        streak: 7,
        city: "San Francisco"
    )
}
import CloudKit

struct User: Identifiable, Codable {
    let id: String
    var displayName: String
    var avatarURL: URL?
    var isPro: Bool
    var streak: Int
    var city: String?
    var createdAt: Date
    var lastDropDate: Date?
    var totalDrops: Int
    
    init(id: String = UUID().uuidString, 
         displayName: String, 
         avatarURL: URL? = nil, 
         isPro: Bool = false, 
         streak: Int = 0, 
         city: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.isPro = isPro
        self.streak = streak
        self.city = city
        self.createdAt = Date()
        self.lastDropDate = nil
        self.totalDrops = 0
    }
}

// MARK: - CloudKit Extensions
extension User {
    static let recordType = "User"
    
    init?(from record: CKRecord) {
        guard let displayName = record["displayName"] as? String else { return nil }
        
        self.id = record.recordID.recordName
        self.displayName = displayName
        self.avatarURL = record["avatarURL"] as? URL
        self.isPro = record["isPro"] as? Bool ?? false
        self.streak = record["streak"] as? Int ?? 0
        self.city = record["city"] as? String
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.lastDropDate = record["lastDropDate"] as? Date
        self.totalDrops = record["totalDrops"] as? Int ?? 0
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: User.recordType, recordID: CKRecord.ID(recordName: id))
        record["displayName"] = displayName
        record["avatarURL"] = avatarURL
        record["isPro"] = isPro
        record["streak"] = streak
        record["city"] = city
        record["createdAt"] = createdAt
        record["lastDropDate"] = lastDropDate
        record["totalDrops"] = totalDrops
        return record
    }
}

// MARK: - Sample Data
extension User {
    static let sampleUser = User(
        displayName: "Poop Master",
        isPro: true,
        streak: 7,
        city: "San Francisco"
    )
}
