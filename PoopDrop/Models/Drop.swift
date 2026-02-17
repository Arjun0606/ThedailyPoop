import Foundation
import CoreLocation

struct Drop: Identifiable, Codable {
    let id: String
    let userID: String
    let username: String
    let timestamp: Date
    let location: CLLocationCoordinate2D?
    let locationName: String?
    let caption: String?
    var reactions: [String: Int]
    var groupID: String?

    var displayEmoji: String { "💩" }

    var coordinate: CLLocationCoordinate2D? { location }

    var clusterKey: String? {
        guard let coord = location else { return nil }
        let lat = Int(coord.latitude * 2000)
        let lon = Int(coord.longitude * 2000)
        return "\(lat)_\(lon)"
    }

    init(id: String = UUID().uuidString,
         userID: String,
         username: String,
         location: CLLocationCoordinate2D? = nil,
         locationName: String? = nil,
         caption: String? = nil,
         groupID: String? = nil) {
        self.id = id
        self.userID = userID
        self.username = username
        self.timestamp = Date()
        self.location = location
        self.locationName = locationName
        self.caption = caption
        self.reactions = [:]
        self.groupID = groupID
    }
}

// MARK: - Codable for CLLocationCoordinate2D
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
        locationName: "Starbucks, Market St",
        caption: "Best poop of the day!"
    )
}
