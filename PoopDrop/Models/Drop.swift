import Foundation
import CloudKit
import CoreLocation

struct Drop: Identifiable, Codable {
    let id: String
    let userID: String
    let username: String
    let timestamp: Date
    let location: CLLocationCoordinate2D?
    let city: String?
    let country: String?
    let skinId: String? // nil = default 💩
    let caption: String?
    let isNoPoop: Bool
    var reactions: [String: Int]
    var reactionCount: Int
    var commentCount: Int
    var expiresAt: Date
    let isVisible: Bool

    // Poop rating and music
    var rating: Int?
    var musicTitle: String?
    var musicArtist: String?
    var musicURL: String?
    var musicCoverArt: String?

    // @Mention support for cross-tab integration
    var mentionedUserIDs: [String] = []
    var mentionedUsernames: [String] = []

    var displayEmoji: String {
        if isNoPoop { return "😵‍💫" }
        return skinId ?? "💩"
    }

    var isCurrentlyVisible: Bool {
        Date() < expiresAt && isVisible
    }

    var clusterKey: String? {
        guard let coord = location else { return nil }
        let lat = Int(coord.latitude * 2000)
        let lon = Int(coord.longitude * 2000)
        return "\(lat)_\(lon)"
    }

    var coordinate: CLLocationCoordinate2D? { location }

    // Compatibility shim for sponsor references (always false now)
    var isSponsored: Bool { false }

    init(id: String = UUID().uuidString,
         userID: String,
         username: String,
         location: CLLocationCoordinate2D? = nil,
         city: String? = nil,
         country: String? = nil,
         skinId: String? = nil,
         caption: String? = nil,
         isNoPoop: Bool = false,
         rating: Int? = nil,
         musicTitle: String? = nil,
         musicArtist: String? = nil,
         musicURL: String? = nil,
         musicCoverArt: String? = nil,
         mentionedUserIDs: [String] = [],
         mentionedUsernames: [String] = []) {
        self.id = id
        self.userID = userID
        self.username = username
        self.timestamp = Date()
        self.location = location
        self.city = city
        self.country = country
        self.skinId = skinId
        self.caption = caption
        self.isNoPoop = isNoPoop
        self.reactions = [:]
        self.reactionCount = 0
        self.commentCount = 0
        self.isVisible = true
        self.rating = rating
        self.musicTitle = musicTitle
        self.musicArtist = musicArtist
        self.musicURL = musicURL
        self.musicCoverArt = musicCoverArt
        self.mentionedUserIDs = mentionedUserIDs
        self.mentionedUsernames = mentionedUsernames
        let calendar = Calendar.current
        self.expiresAt = calendar.date(byAdding: .day, value: 3, to: Date()) ?? Date().addingTimeInterval(3 * 24 * 60 * 60)
    }
}

// MARK: - CloudKit Extensions (will be replaced with Supabase)
extension Drop {
    static let recordType = "Drop"

    init?(from record: CKRecord) {
        guard let userID = record["userID"] as? String,
              let username = record["username"] as? String else { return nil }

        self.id = record.recordID.recordName
        self.userID = userID
        self.username = username
        self.timestamp = record["timestamp"] as? Date ?? Date()

        if let locationValue = record["location"] as? CLLocation {
            self.location = locationValue.coordinate
        } else {
            self.location = nil
        }

        self.city = record["city"] as? String
        self.country = record["country"] as? String
        self.skinId = record["skinId"] as? String
        self.caption = record["caption"] as? String
        self.isNoPoop = (record["isNoPoop"] as? Int) == 1

        if let reactionsData = record["reactions"] as? Data {
            self.reactions = (try? JSONDecoder().decode([String: Int].self, from: reactionsData)) ?? [:]
        } else {
            self.reactions = [:]
        }

        self.reactionCount = record["reactionCount"] as? Int ?? reactions.values.reduce(0, +)
        self.commentCount = record["commentCount"] as? Int ?? 0
        self.expiresAt = record["expiresAt"] as? Date ?? Date().addingTimeInterval(3 * 24 * 60 * 60)
        self.isVisible = (record["isVisible"] as? Int) == 1
        self.rating = record["rating"] as? Int
        self.musicTitle = record["musicTitle"] as? String
        self.musicArtist = record["musicArtist"] as? String
        self.musicURL = record["musicURL"] as? String
        self.musicCoverArt = record["musicCoverArt"] as? String
        self.mentionedUserIDs = record["mentionedUserIDs"] as? [String] ?? []
        self.mentionedUsernames = record["mentionedUsernames"] as? [String] ?? []
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Drop.recordType, recordID: CKRecord.ID(recordName: id))
        record["userID"] = userID
        record["username"] = username
        record["timestamp"] = timestamp
        record["isNoPoop"] = isNoPoop ? 1 : 0
        record["isVisible"] = isVisible ? 1 : 0

        if let locationValue = location {
            record["location"] = CLLocation(latitude: locationValue.latitude, longitude: locationValue.longitude)
        }

        record["city"] = city
        record["country"] = country
        record["skinId"] = skinId
        record["caption"] = caption

        if let reactionsData = try? JSONEncoder().encode(reactions) {
            record["reactions"] = reactionsData
        }

        record["reactionCount"] = reactionCount
        record["commentCount"] = commentCount
        record["expiresAt"] = expiresAt
        record["rating"] = rating
        record["musicTitle"] = musicTitle
        record["musicArtist"] = musicArtist
        record["musicURL"] = musicURL
        record["musicCoverArt"] = musicCoverArt

        if !mentionedUserIDs.isEmpty {
            record["mentionedUserIDs"] = mentionedUserIDs
            record["mentionedUsernames"] = mentionedUsernames
        }

        return record
    }
}

// MARK: - Codable Implementation for CLLocationCoordinate2D
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }

    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// MARK: - Sample Data
extension Drop {
    static let sampleDrop = Drop(
        userID: "user123",
        username: "poopmaster",
        location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        city: "San Francisco",
        country: "United States",
        caption: "Best poop of the day! 💩✨"
    )
}
