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
    var createdAt: Date
    var lastDropDate: Date?
    var lastRealDropDate: Date? // Last actual poop (excludes no-poop entries)
    var lastPoopDate: Date? // For new constipation tracking system
    var totalDrops: Int
    var maxDropsInDay: Int // Highest number of poops in a single day
    var friends: [String] // Array of friend user IDs
    var friendRequests: [String] // Pending friend request IDs
    var appleUserID: String // Link to Apple ID authentication
    var isActive: Bool // Account status
    var lastSeen: Date? // Last app activity
    
    // Social / Fart Attack Stats
    var attacksSent: Int
    var attacksReceived: Int
    
    // Points System for Daily Leaderboard
    var dailyPoints: Int // Resets at midnight
    var dailyPointsResetDate: Date? // Track when points were last reset
    var totalLifetimePoints: Int // Never resets (for all-time stats)
    var pointsBoostActive: Bool // 2X points multiplier active
    var pointsBoostExpiresAt: Date? // When 2X boost ends

    // Travel tracking for badges
    var countriesVisited: Set<String> // Countries where user has dropped
    var continentsVisited: Set<String> // Continents where user has dropped
    
    init(id: String = UUID().uuidString, 
         username: String,
         dateOfBirth: Date? = nil,
         gender: Gender? = nil,
         appleUserID: String,
         customGender: String? = nil,
         avatarURL: URL? = nil) {
        self.id = id
        self.username = username
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.appleUserID = appleUserID
        self.customGender = customGender
        self.avatarURL = avatarURL
        self.createdAt = Date()
        self.lastDropDate = nil
        self.lastRealDropDate = nil
        self.lastPoopDate = nil
        self.totalDrops = 0
        self.maxDropsInDay = 0
        self.friends = []
        self.friendRequests = []
        self.isActive = true
        self.lastSeen = Date()
        self.attacksSent = 0
        self.attacksReceived = 0
        self.dailyPoints = 0
        self.dailyPointsResetDate = Date()
        self.totalLifetimePoints = 0
        self.pointsBoostActive = false
        self.pointsBoostExpiresAt = nil
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
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.lastDropDate = record["lastDropDate"] as? Date
        self.lastRealDropDate = record["lastRealDropDate"] as? Date
        self.lastPoopDate = record["lastPoopDate"] as? Date
        self.totalDrops = record["totalDrops"] as? Int ?? 0
        self.maxDropsInDay = record["maxDropsInDay"] as? Int ?? 0
        self.friends = record["friends"] as? [String] ?? []
        self.friendRequests = record["friendRequests"] as? [String] ?? []
        self.isActive = (record["isActive"] as? Int ?? 1) == 1
        self.lastSeen = record["lastSeen"] as? Date ?? Date()
        
        self.attacksSent = record["attacksSent"] as? Int ?? 0
        self.attacksReceived = record["attacksReceived"] as? Int ?? 0
        
        // Points System
        self.dailyPoints = record["dailyPoints"] as? Int ?? 0
        self.dailyPointsResetDate = record["dailyPointsResetDate"] as? Date
        self.totalLifetimePoints = record["totalLifetimePoints"] as? Int ?? 0
        self.pointsBoostActive = (record["pointsBoostActive"] as? Int ?? 0) == 1
        self.pointsBoostExpiresAt = record["pointsBoostExpiresAt"] as? Date

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
        if let customGender = customGender {
            record["customGender"] = customGender
        }
        record["appleUserID"] = appleUserID
        // Store avatar as CKAsset when available
        if let localURL = avatarURL, FileManager.default.fileExists(atPath: localURL.path) {
            let asset = CKAsset(fileURL: localURL)
            record["avatar"] = asset
        }
        record["createdAt"] = createdAt
        
        // Only save optional Date fields if they exist (prevents CloudKit error on new users)
        if let date = lastDropDate {
            record["lastDropDate"] = date
        }
        if let date = lastRealDropDate {
            record["lastRealDropDate"] = date
        }
        if let date = lastPoopDate {
            record["lastPoopDate"] = date
        }
        
        record["totalDrops"] = totalDrops
        record["maxDropsInDay"] = maxDropsInDay
        
        // Only save arrays if not empty (CloudKit doesn't allow empty lists for new fields)
        if !friends.isEmpty {
            record["friends"] = friends
        }
        if !friendRequests.isEmpty {
            record["friendRequests"] = friendRequests
        }
        
        // Only save optional Date fields if they exist
        if let date = lastSeen {
            record["lastSeen"] = date
        }
        
        record["isActive"] = isActive ? 1 : 0
        
        // Only save attack stats if > 0 (CloudKit doesn't allow new fields on existing users)
        if attacksSent > 0 {
            record["attacksSent"] = attacksSent
        }
        if attacksReceived > 0 {
            record["attacksReceived"] = attacksReceived
        }
        
        // Points System (only save if values exist to avoid CloudKit errors on new users)
        if dailyPoints > 0 {
            record["dailyPoints"] = dailyPoints
        }
        // CRITICAL: Only save dailyPointsResetDate if dailyPoints exist (prevents CloudKit error on new users)
        if dailyPoints > 0, let resetDate = dailyPointsResetDate {
            record["dailyPointsResetDate"] = resetDate
        }
        if totalLifetimePoints > 0 {
            record["totalLifetimePoints"] = totalLifetimePoints
        }
        if pointsBoostActive {
            record["pointsBoostActive"] = 1
            if let expiresAt = pointsBoostExpiresAt {
                record["pointsBoostExpiresAt"] = expiresAt
            }
        }

        // Save sets as arrays (only if not empty - CloudKit doesn't allow empty lists for new fields)
        if !countriesVisited.isEmpty {
            record["countriesVisited"] = Array(countriesVisited)
        }
        if !continentsVisited.isEmpty {
            record["continentsVisited"] = Array(continentsVisited)
        }
        
        return record
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, username, dateOfBirth, gender, customGender, avatarURL, createdAt,
             lastDropDate, lastRealDropDate, lastPoopDate, totalDrops, maxDropsInDay,
             friends, friendRequests, appleUserID, isActive, lastSeen,
             attacksSent, attacksReceived,
             dailyPoints, dailyPointsResetDate, totalLifetimePoints, pointsBoostActive, pointsBoostExpiresAt,
             countriesVisited, continentsVisited
    }
}

// MARK: - Sample Data
extension User {
    static let sampleUser = User(
        username: "poopmaster",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
        gender: .male,
        appleUserID: "sample_apple_id"
    )
}

