import Foundation
import CloudKit
import CoreLocation

struct Drop: Identifiable, Codable {
    let id: String
    let creatorId: String
    let creatorName: String
    let createdAt: Date
    let coordinate: CLLocationCoordinate2D?  // Optional for "no poop" entries
    let skinId: String? // nil = default 💩
    let caption: String?
    var reactions: [String: Int] // emoji -> count
    var sponsorCampaignId: String? // optional for sponsored drops
    let isNoPoop: Bool // true for "no poop" streak maintenance
    let isProUser: Bool // Track if creator was Pro when dropping
    var expiresAt: Date // When this drop expires from map
    var isSponsored: Bool { sponsorCampaignId != nil }
    
    // Computed property for display emoji
    var displayEmoji: String {
        if isNoPoop {
            return "😵‍💫" // Constipated/no poop emoji
        }
        return skinId ?? "💩"
    }
    
    // Check if drop is still visible on map
    var isVisible: Bool {
        Date() < expiresAt
    }
    
    // Get clustering key for same location drops
    var clusterKey: String? {
        guard let coord = coordinate else { return nil }
        // Round to ~50m precision for clustering
        let lat = Int(coord.latitude * 2000) // ~50m precision
        let lon = Int(coord.longitude * 2000)
        return "\(lat)_\(lon)"
    }
    
    init(id: String = UUID().uuidString,
         creatorId: String,
         creatorName: String,
         coordinate: CLLocationCoordinate2D? = nil,
         skinId: String? = nil,
         caption: String? = nil,
         sponsorCampaignId: String? = nil,
         isNoPoop: Bool = false,
         isProUser: Bool = false) {
        self.id = id
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.createdAt = Date()
        self.coordinate = coordinate
        self.skinId = skinId
        self.caption = caption
        self.reactions = [:]
        self.sponsorCampaignId = sponsorCampaignId
        self.isNoPoop = isNoPoop
        self.isProUser = isProUser
        
        // Set expiration based on Pro status
        let calendar = Calendar.current
        if isProUser {
            // Pro users: 1 month
            self.expiresAt = calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date().addingTimeInterval(30 * 24 * 60 * 60)
        } else {
            // Free users: 3 days
            self.expiresAt = calendar.date(byAdding: .day, value: 3, to: Date()) ?? Date().addingTimeInterval(3 * 24 * 60 * 60)
        }
    }
}

// MARK: - CloudKit Extensions
extension Drop {
    static let recordType = "Drop"
    
    init?(from record: CKRecord) {
        guard let creatorId = record["creatorId"] as? String,
              let creatorName = record["creatorName"] as? String else { return nil }
        
        self.id = record.recordID.recordName
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.createdAt = record["createdAt"] as? Date ?? Date()
        
        // Location is optional for "no poop" entries
        if let location = record["location"] as? CLLocation {
            self.coordinate = location.coordinate
        } else {
            self.coordinate = nil
        }
        
        self.skinId = record["skinId"] as? String
        self.caption = record["caption"] as? String
        self.sponsorCampaignId = record["sponsorCampaignId"] as? String
        self.isNoPoop = record["isNoPoop"] as? Bool ?? false
        self.isProUser = record["isProUser"] as? Bool ?? false
        self.expiresAt = record["expiresAt"] as? Date ?? Date().addingTimeInterval(3 * 24 * 60 * 60)
        
        // Decode reactions from CloudKit
        if let reactionsData = record["reactions"] as? Data {
            self.reactions = (try? JSONDecoder().decode([String: Int].self, from: reactionsData)) ?? [:]
        } else {
            self.reactions = [:]
        }
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Drop.recordType, recordID: CKRecord.ID(recordName: id))
        record["creatorId"] = creatorId
        record["creatorName"] = creatorName
        record["createdAt"] = createdAt
        record["isNoPoop"] = isNoPoop
        
        // Only set location for actual poop drops
        if let coordinate = coordinate {
            record["location"] = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        
        record["skinId"] = skinId
        record["caption"] = caption
        record["sponsorCampaignId"] = sponsorCampaignId
        record["isProUser"] = isProUser
        record["expiresAt"] = expiresAt
        
        // Encode reactions for CloudKit
        if let reactionsData = try? JSONEncoder().encode(reactions) {
            record["reactions"] = reactionsData
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
        creatorId: "user123",
        creatorName: "Poop Master",
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        caption: "Best poop of the day! 💩✨"
    )
    
    static let sampleNoPoopDrop = Drop(
        creatorId: "user456",
        creatorName: "Constipated Carl",
        caption: "No poop today... keeping the streak alive! 😵‍💫",
        isNoPoop: true
    )
    
    static let sponsoredDrop = Drop(
        creatorId: "tacobell",
        creatorName: "Taco Bell",
        coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
        caption: "Spicy Tuesday Special! 🌮💩🔥",
        sponsorCampaignId: "tacobell_spicy_tuesday"
    )
}
            record["location"] = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        
        record["skinId"] = skinId
        record["caption"] = caption
        record["sponsorCampaignId"] = sponsorCampaignId
        record["isProUser"] = isProUser
        record["expiresAt"] = expiresAt
        
        // Encode reactions for CloudKit
        if let reactionsData = try? JSONEncoder().encode(reactions) {
            record["reactions"] = reactionsData
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
        creatorId: "user123",
        creatorName: "Poop Master",
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        caption: "Best poop of the day! 💩✨"
    )
    
    static let sampleNoPoopDrop = Drop(
        creatorId: "user456",
        creatorName: "Constipated Carl",
        caption: "No poop today... keeping the streak alive! 😵‍💫",
        isNoPoop: true
    )
    
    static let sponsoredDrop = Drop(
        creatorId: "tacobell",
        creatorName: "Taco Bell",
        coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
        caption: "Spicy Tuesday Special! 🌮💩🔥",
        sponsorCampaignId: "tacobell_spicy_tuesday"
    )
}
import CloudKit
import CoreLocation

struct Drop: Identifiable, Codable {
    let id: String
    let creatorId: String
    let creatorName: String
    let createdAt: Date
    let coordinate: CLLocationCoordinate2D
    let skinId: String? // nil = default 💩
    let caption: String?
    var reactions: [String: Int] // emoji -> count
    var sponsorCampaignId: String? // optional for sponsored drops
    var isSponsored: Bool { sponsorCampaignId != nil }
    
    init(id: String = UUID().uuidString,
         creatorId: String,
         creatorName: String,
         coordinate: CLLocationCoordinate2D,
         skinId: String? = nil,
         caption: String? = nil,
         sponsorCampaignId: String? = nil) {
        self.id = id
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.createdAt = Date()
        self.coordinate = coordinate
        self.skinId = skinId
        self.caption = caption
        self.reactions = [:]
        self.sponsorCampaignId = sponsorCampaignId
    }
}

// MARK: - CloudKit Extensions
extension Drop {
    static let recordType = "Drop"
    
    init?(from record: CKRecord) {
        guard let creatorId = record["creatorId"] as? String,
              let creatorName = record["creatorName"] as? String,
              let location = record["location"] as? CLLocation else { return nil }
        
        self.id = record.recordID.recordName
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.coordinate = location.coordinate
        self.skinId = record["skinId"] as? String
        self.caption = record["caption"] as? String
        self.sponsorCampaignId = record["sponsorCampaignId"] as? String
        
        // Decode reactions from CloudKit
        if let reactionsData = record["reactions"] as? Data {
            self.reactions = (try? JSONDecoder().decode([String: Int].self, from: reactionsData)) ?? [:]
        } else {
            self.reactions = [:]
        }
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Drop.recordType, recordID: CKRecord.ID(recordName: id))
        record["creatorId"] = creatorId
        record["creatorName"] = creatorName
        record["createdAt"] = createdAt
        record["location"] = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        record["skinId"] = skinId
        record["caption"] = caption
        record["sponsorCampaignId"] = sponsorCampaignId
        
        // Encode reactions for CloudKit
        if let reactionsData = try? JSONEncoder().encode(reactions) {
            record["reactions"] = reactionsData
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
        creatorId: "user123",
        creatorName: "Poop Master",
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        caption: "Best poop of the day! 💩✨"
    )
    
    static let sponsoredDrop = Drop(
        creatorId: "tacobell",
        creatorName: "Taco Bell",
        coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
        caption: "Spicy Tuesday Special! 🌮💩🔥",
        sponsorCampaignId: "tacobell_spicy_tuesday"
    )
}
