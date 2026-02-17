import Foundation

struct ReaderSession: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String?
    let storyHeadline: String?
    let latitude: Double
    let longitude: Double
    let countryCode: String?
    let countryName: String?
    let city: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case storyHeadline = "story_headline"
        case latitude
        case longitude
        case countryCode = "country_code"
        case countryName = "country_name"
        case city
        case createdAt = "created_at"
    }
}
