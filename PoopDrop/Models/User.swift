import Foundation
import CloudKit

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case custom = "Custom"
}

struct User: Identifiable, Codable {
    let id: String
    var username: String // Unique username - serves as both display name and username
    var dateOfBirth: Date? // Optional - for user preference
    var gender: Gender? // Optional - for user preference
    var customGender: String? // Freeform text when gender == .custom
    var avatarURL: URL?
    var streak: Int
    var createdAt: Date
    var lastDropDate: Date?
    var lastRealDropDate: Date? // Last actual poop (excludes no-poop entries)
    var totalDrops: Int
    var maxDropsInDay: Int // Highest number of poops in a single day
    var longestNoPoopStreak: Int // Most days gone without pooping
    var friends: [String] // Array of friend user IDs
    var friendRequests: [String] // Pending friend request IDs
    var lastStreakLogDate: Date? // Last date a poop was logged for the streak
    var longestStreak: Int // All-time best streak
    var appleUserID: String // Link to Apple ID authentication
    var isActive: Bool // Account status
    var lastSeen: Date? // Last app activity
    
    // Streak rewards
    var awardedStreakMilestones: Set<Int> // e.g., [7,30,100]
    
    // Social / Fart Attack Stats
    var attacksSent: Int
    var attacksReceived: Int

    // Travel tracking for badges
    var countriesVisited: Set<String> // Countries where user has dropped
    var continentsVisited: Set<String> // Continents where user has dropped
    
    init(id: String = UUID().uuidString, 
         username: String,
         dateOfBirth: Date? = nil,
         gender: Gender? = nil,
         appleUserID: String,
         customGender: String? = nil,
         avatarURL: URL? = nil, 
         streak: Int = 0) {
        self.id = id
        self.username = username
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.appleUserID = appleUserID
        self.customGender = customGender
        self.avatarURL = avatarURL
        self.streak = streak
        self.createdAt = Date()
        self.lastDropDate = nil
        self.lastRealDropDate = nil
        self.totalDrops = 0
        self.maxDropsInDay = 0
        self.longestNoPoopStreak = 0
        self.friends = []
        self.friendRequests = []
        self.lastStreakLogDate = nil
        self.longestStreak = 0
        self.isActive = true
        self.lastSeen = Date()
        self.awardedStreakMilestones = []
        self.attacksSent = 0
        self.attacksReceived = 0
        self.countriesVisited = []
        self.continentsVisited = []
    }
}

// MARK: - CloudKit Extensions
extension User {
    static let recordType = "User"
    
    init?(from record: CKRecord) {
        guard let username = record["username"] as? String,
              let appleUserID = record["appleUserID"] as? String else { return nil }
        
        self.id = record.recordID.recordName
        self.username = username
        self.dateOfBirth = record["dateOfBirth"] as? Date
        if let genderString = record["gender"] as? String {
            self.gender = Gender(rawValue: genderString)
        } else {
            self.gender = nil
        }
        self.appleUserID = appleUserID
        if let custom = record["customGender"] as? String { self.customGender = custom } else { self.customGender = nil }
        if let asset = record["avatar"] as? CKAsset, let url = asset.fileURL {
            self.avatarURL = url
        } else if let avatarURLString = record["avatarURL"] as? String {
            self.avatarURL = URL(string: avatarURLString)
        } else {
            self.avatarURL = nil
        }
        self.streak = record["streak"] as? Int ?? 0
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.lastDropDate = record["lastDropDate"] as? Date
        self.lastRealDropDate = record["lastRealDropDate"] as? Date
        self.totalDrops = record["totalDrops"] as? Int ?? 0
        self.maxDropsInDay = record["maxDropsInDay"] as? Int ?? 0
        self.longestNoPoopStreak = record["longestNoPoopStreak"] as? Int ?? 0
        self.friends = record["friends"] as? [String] ?? []
        self.friendRequests = record["friendRequests"] as? [String] ?? []
        self.lastStreakLogDate = record["lastStreakLogDate"] as? Date
        self.longestStreak = record["longestStreak"] as? Int ?? 0
        self.isActive = (record["isActive"] as? Int ?? 1) == 1
        self.lastSeen = record["lastSeen"] as? Date ?? Date()
        self.awardedStreakMilestones = Set(record["awardedStreakMilestones"] as? [Int] ?? [])
        
        self.attacksSent = record["attacksSent"] as? Int ?? 0
        self.attacksReceived = record["attacksReceived"] as? Int ?? 0

        // Decode travel sets from CloudKit
        if let countriesData = record["countriesVisited"] as? [String] {
            self.countriesVisited = Set(countriesData)
        } else {
            self.countriesVisited = []
        }
        
        if let continentsData = record["continentsVisited"] as? [String] {
            self.continentsVisited = Set(continentsData)
        } else {
            self.continentsVisited = []
        }
        if let milestonesData = record["awardedStreakMilestones"] as? Data {
            self.awardedStreakMilestones = (try? JSONDecoder().decode(Set<Int>.self, from: milestonesData)) ?? []
        } else {
            self.awardedStreakMilestones = []
        }
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: User.recordType, recordID: CKRecord.ID(recordName: id))
        record["username"] = username
        if let dob = dateOfBirth {
            record["dateOfBirth"] = dob
        }
        if let gender = gender {
            record["gender"] = gender.rawValue
        }
        record["appleUserID"] = appleUserID
        record["customGender"] = customGender
        // Store avatar as CKAsset when available
        if let localURL = avatarURL, FileManager.default.fileExists(atPath: localURL.path) {
            let asset = CKAsset(fileURL: localURL)
            record["avatar"] = asset
        }
        record["streak"] = streak
        record["createdAt"] = createdAt
        record["lastDropDate"] = lastDropDate
        record["lastRealDropDate"] = lastRealDropDate
        record["totalDrops"] = totalDrops
        record["maxDropsInDay"] = maxDropsInDay
        record["longestNoPoopStreak"] = longestNoPoopStreak
        record["friends"] = friends
        record["friendRequests"] = friendRequests
        record["lastStreakLogDate"] = lastStreakLogDate
        record["longestStreak"] = longestStreak
        record["isActive"] = isActive ? 1 : 0
        record["lastSeen"] = lastSeen
        record["awardedStreakMilestones"] = Array(awardedStreakMilestones)
        
        record["attacksSent"] = attacksSent
        record["attacksReceived"] = attacksReceived

        // Save sets as arrays
        record["countriesVisited"] = Array(countriesVisited)
        record["continentsVisited"] = Array(continentsVisited)
        
        return record
    }
    
    // Remove old streak date property
    private enum CodingKeys: String, CodingKey {
        case id, username, dateOfBirth, gender, customGender, avatarURL, streak, createdAt,
             lastDropDate, lastRealDropDate, totalDrops, maxDropsInDay, longestNoPoopStreak,
             friends, friendRequests, lastStreakLogDate, longestStreak, appleUserID, isActive, lastSeen,
             awardedStreakMilestones,
             attacksSent, attacksReceived,
             countriesVisited, continentsVisited
    }
}

// MARK: - Sample Data
extension User {
    static let sampleUser = User(
        username: "poopmaster",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
        gender: .male,
        appleUserID: "sample_apple_id",
        streak: 7
    )
}

