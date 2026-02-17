import Foundation

struct User: Identifiable, Codable {
    let id: String
    var username: String
    var displayName: String?
    var avatarURL: URL?
    var appleUserID: String
    var totalDrops: Int
    var createdAt: Date

    init(id: String = UUID().uuidString,
         username: String,
         displayName: String? = nil,
         avatarURL: URL? = nil,
         appleUserID: String) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.appleUserID = appleUserID
        self.totalDrops = 0
        self.createdAt = Date()
    }
}

// MARK: - Sample Data
extension User {
    static let sampleUser = User(
        username: "poopmaster",
        displayName: "Poop Master",
        appleUserID: "sample_apple_id"
    )
}
