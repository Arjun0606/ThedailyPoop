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
    var dateOfBirth: Date // Required for age verification
    var gender: Gender // Required for personalization
    var customGender: String? // Freeform text when gender == .custom
    var avatarURL: URL?
    var streak: Int
    var createdAt: Date
    var lastDropDate: Date?
    var totalDrops: Int
    var maxDropsInDay: Int // Highest number of poops in a single day
    var longestNoPoopStreak: Int // Most days gone without pooping
    var friends: [String] // Array of friend user IDs
    var friendRequests: [String] // Pending friend request IDs
    var lastStreakDate: Date? // Track when streak was last maintained
    var appleUserID: String // Link to Apple ID authentication
    var isActive: Bool // Account status
    var lastSeen: Date? // Last app activity
    
    // Travel tracking for badges
    var countriesVisited: Set<String> // Countries where user has dropped
    var continentsVisited: Set<String> // Continents where user has dropped
    
    init(id: String = UUID().uuidString, 
         username: String,
         dateOfBirth: Date,
         gender: Gender,
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
        self.totalDrops = 0
        self.maxDropsInDay = 0
        self.longestNoPoopStreak = 0
        self.friends = []
        self.friendRequests = []
        self.lastStreakDate = nil
        self.isActive = true
        self.lastSeen = Date()
        self.countriesVisited = []
        self.continentsVisited = []
    }
}

// MARK: - CloudKit Extensions
extension User {
    static let recordType = "User"
    
    init?(from record: CKRecord) {
        guard let username = record["username"] as? String,
              let dateOfBirth = record["dateOfBirth"] as? Date,
              let genderString = record["gender"] as? String,
              let gender = Gender(rawValue: genderString),
              let appleUserID = record["appleUserID"] as? String else { return nil }
        
        self.id = record.recordID.recordName
        self.username = username
        self.dateOfBirth = dateOfBirth
        self.gender = gender
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
        self.totalDrops = record["totalDrops"] as? Int ?? 0
        self.maxDropsInDay = record["maxDropsInDay"] as? Int ?? 0
        self.longestNoPoopStreak = record["longestNoPoopStreak"] as? Int ?? 0
        self.isActive = (record["isActive"] as? Int) == 1
        self.lastSeen = record["lastSeen"] as? Date
        
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
        
        // Decode travel sets from CloudKit
        if let countriesData = record["countriesVisited"] as? Data {
            self.countriesVisited = (try? JSONDecoder().decode(Set<String>.self, from: countriesData)) ?? []
        } else {
            self.countriesVisited = []
        }
        
        if let continentsData = record["continentsVisited"] as? Data {
            self.continentsVisited = (try? JSONDecoder().decode(Set<String>.self, from: continentsData)) ?? []
        } else {
            self.continentsVisited = []
        }
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: User.recordType, recordID: CKRecord.ID(recordName: id))
        record["username"] = username
        record["dateOfBirth"] = dateOfBirth
        record["gender"] = gender.rawValue
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
        record["totalDrops"] = totalDrops
        record["maxDropsInDay"] = maxDropsInDay
        record["longestNoPoopStreak"] = longestNoPoopStreak
        record["isActive"] = isActive ? 1 : 0
        record["lastSeen"] = lastSeen
        record["lastStreakDate"] = lastStreakDate
        
        // Encode friends array for CloudKit
        if let friendsData = try? JSONEncoder().encode(friends) {
            record["friends"] = friendsData
        }
        
        // Encode friend requests array for CloudKit
        if let requestsData = try? JSONEncoder().encode(friendRequests) {
            record["friendRequests"] = requestsData
        }
        
        // Encode travel sets for CloudKit
        if let countriesData = try? JSONEncoder().encode(countriesVisited) {
            record["countriesVisited"] = countriesData
        }
        
        if let continentsData = try? JSONEncoder().encode(continentsVisited) {
            record["continentsVisited"] = continentsData
        }
        
        return record
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

