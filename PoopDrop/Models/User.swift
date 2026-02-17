import Foundation
import CloudKit

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case custom = "Custom"
}

struct User: Identifiable, Codable {
    let id: String
    var username: String
    var dateOfBirth: Date?
    var gender: Gender?
    var customGender: String?
    var avatarURL: URL?
    var createdAt: Date
    var lastDropDate: Date?
    var lastRealDropDate: Date?
    var lastPoopDate: Date?
    var totalDrops: Int
    var maxDropsInDay: Int
    var friends: [String]
    var friendRequests: [String]
    var appleUserID: String
    var isActive: Bool
    var lastSeen: Date?

    // Social / Fart Attack Stats
    var attacksSent: Int
    var attacksReceived: Int

    // Streak (simple daily activity streak)
    var streakCount: Int
    var streakLastActive: Date?

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
        self.streakCount = 0
        self.streakLastActive = nil
    }
}

// MARK: - CloudKit Extensions (will be replaced with Supabase)
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
        self.streakCount = record["streakCount"] as? Int ?? 0
        self.streakLastActive = record["streakLastActive"] as? Date
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: User.recordType, recordID: CKRecord.ID(recordName: id))
        record["username"] = username
        if let dob = dateOfBirth { record["dateOfBirth"] = dob }
        if let gender = gender { record["gender"] = gender.rawValue }
        if let customGender = customGender { record["customGender"] = customGender }
        record["appleUserID"] = appleUserID
        if let localURL = avatarURL, FileManager.default.fileExists(atPath: localURL.path) {
            let asset = CKAsset(fileURL: localURL)
            record["avatar"] = asset
        }
        record["createdAt"] = createdAt
        if let date = lastDropDate { record["lastDropDate"] = date }
        if let date = lastRealDropDate { record["lastRealDropDate"] = date }
        if let date = lastPoopDate { record["lastPoopDate"] = date }
        record["totalDrops"] = totalDrops
        record["maxDropsInDay"] = maxDropsInDay
        if !friends.isEmpty { record["friends"] = friends }
        if !friendRequests.isEmpty { record["friendRequests"] = friendRequests }
        if let date = lastSeen { record["lastSeen"] = date }
        record["isActive"] = isActive ? 1 : 0
        if attacksSent > 0 { record["attacksSent"] = attacksSent }
        if attacksReceived > 0 { record["attacksReceived"] = attacksReceived }
        record["streakCount"] = streakCount
        if let date = streakLastActive { record["streakLastActive"] = date }
        return record
    }

    private enum CodingKeys: String, CodingKey {
        case id, username, dateOfBirth, gender, customGender, avatarURL, createdAt,
             lastDropDate, lastRealDropDate, lastPoopDate, totalDrops, maxDropsInDay,
             friends, friendRequests, appleUserID, isActive, lastSeen,
             attacksSent, attacksReceived, streakCount, streakLastActive
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
