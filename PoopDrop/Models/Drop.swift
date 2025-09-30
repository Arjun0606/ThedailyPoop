import Foundation
import CloudKit
import CoreLocation

struct Drop: Identifiable, Codable {
    let id: String
    let userID: String // Changed from creatorId to match CloudKit schema
    let username: String // Changed from creatorName to match CloudKit schema
    let timestamp: Date // Changed from createdAt to match CloudKit schema
    let location: CLLocationCoordinate2D?  // Changed from coordinate to match CloudKit schema
    let city: String? // City name from reverse geocoding
    let country: String? // Country for badges
    let continent: String? // Continent for badges
    let skinId: String? // nil = default 💩
    let caption: String?
    let isNoPoop: Bool // true for "no poop" streak maintenance
    let isSponsored: Bool // Sponsored content flag
    var sponsorCampaignID: String? // optional for sponsored drops
    var reactions: [String: Int] // Emoji reactions (emoji -> count)
    var reactionCount: Int // Total reactions
    var commentCount: Int // Total comments
    var expiresAt: Date // When this drop expires from map
    let isVisible: Bool // Soft delete capability
    
    // Computed property for display emoji
    var displayEmoji: String {
        if isNoPoop {
            return "😵‍💫" // Constipated/no poop emoji
        }
        return skinId ?? "💩"
    }
    
    // Check if drop is still visible on map
    var isCurrentlyVisible: Bool {
        Date() < expiresAt && isVisible
    }
    
    // Get clustering key for same location drops
    var clusterKey: String? {
        guard let coord = location else { return nil }
        // Round to ~50m precision for clustering
        let lat = Int(coord.latitude * 2000) // ~50m precision
        let lon = Int(coord.longitude * 2000)
        return "\(lat)_\(lon)"
    }
    
    // Legacy coordinate property for backward compatibility
    var coordinate: CLLocationCoordinate2D? {
        return location
    }
    
    init(id: String = UUID().uuidString,
         userID: String,
         username: String,
         location: CLLocationCoordinate2D? = nil,
         city: String? = nil,
         country: String? = nil,
         continent: String? = nil,
         skinId: String? = nil,
         caption: String? = nil,
         sponsorCampaignID: String? = nil,
         isNoPoop: Bool = false,
         isSponsored: Bool = false) {
        self.id = id
        self.userID = userID
        self.username = username
        self.timestamp = Date()
        self.location = location
        self.city = city
        self.country = country
        self.continent = continent
        self.skinId = skinId
        self.caption = caption
        self.sponsorCampaignID = sponsorCampaignID
        self.isNoPoop = isNoPoop
        self.isSponsored = isSponsored
        self.reactions = [:] // Empty reactions dict initially
        self.reactionCount = 0
        self.commentCount = 0
        self.isVisible = true
        
        // Set expiration to 3 days for all users (simplified model)
        let calendar = Calendar.current
        self.expiresAt = calendar.date(byAdding: .day, value: 3, to: Date()) ?? Date().addingTimeInterval(3 * 24 * 60 * 60)
    }
}

// MARK: - CloudKit Extensions
extension Drop {
    static let recordType = "Drop"
    
    init?(from record: CKRecord) {
        guard let userID = record["userID"] as? String,
              let username = record["username"] as? String else { return nil }
        
        self.id = record.recordID.recordName
        self.userID = userID
        self.username = username
        self.timestamp = record["timestamp"] as? Date ?? Date()
        
        // Location is optional for "no poop" entries
        if let locationValue = record["location"] as? CLLocation {
            self.location = locationValue.coordinate
        } else {
            self.location = nil
        }
        
        self.city = record["city"] as? String
        self.country = record["country"] as? String
        self.continent = record["continent"] as? String
        self.skinId = record["skinId"] as? String
        self.caption = record["caption"] as? String
        self.sponsorCampaignID = record["sponsorCampaignID"] as? String
        self.isNoPoop = (record["isNoPoop"] as? Int) == 1
        self.isSponsored = (record["isSponsored"] as? Int) == 1
        
        // Decode reactions dictionary from CloudKit
        if let reactionsData = record["reactions"] as? Data {
            self.reactions = (try? JSONDecoder().decode([String: Int].self, from: reactionsData)) ?? [:]
        } else {
            self.reactions = [:]
        }
        
        self.reactionCount = record["reactionCount"] as? Int ?? reactions.values.reduce(0, +)
        self.commentCount = record["commentCount"] as? Int ?? 0
        self.expiresAt = record["expiresAt"] as? Date ?? Date().addingTimeInterval(3 * 24 * 60 * 60)
        self.isVisible = (record["isVisible"] as? Int) == 1
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Drop.recordType, recordID: CKRecord.ID(recordName: id))
        record["userID"] = userID
        record["username"] = username
        record["timestamp"] = timestamp
        record["isNoPoop"] = isNoPoop ? 1 : 0
        record["isSponsored"] = isSponsored ? 1 : 0
        record["isVisible"] = isVisible ? 1 : 0
        
        // Only set location for actual poop drops
        if let locationValue = location {
            record["location"] = CLLocation(latitude: locationValue.latitude, longitude: locationValue.longitude)
        }
        
        record["city"] = city
        record["country"] = country
        record["continent"] = continent
        record["skinId"] = skinId
        record["caption"] = caption
        record["sponsorCampaignID"] = sponsorCampaignID
        
        // Encode reactions dictionary for CloudKit
        if let reactionsData = try? JSONEncoder().encode(reactions) {
            record["reactions"] = reactionsData
        }
        
        record["reactionCount"] = reactionCount
        record["commentCount"] = commentCount
        record["expiresAt"] = expiresAt
        
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
        continent: "North America",
        caption: "Best poop of the day! 💩✨"
    )
    
    static let sampleNoTheDailyPoop = Drop(
        userID: "user456",
        username: "constipated_carl",
        city: "New York",
        country: "United States",
        continent: "North America",
        caption: "No poop today... keeping the streak alive! 😵‍💫",
        isNoPoop: true
    )
    
    static let sponsoredDrop = Drop(
        userID: "tacobell_official",
        username: "tacobell",
        location: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
        city: "San Francisco",
        country: "United States",
        continent: "North America",
        caption: "Spicy Tuesday Special! 🌮💩🔥",
        sponsorCampaignID: "tacobell_spicy_tuesday",
        isSponsored: true
    )
}