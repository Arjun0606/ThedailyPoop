import Foundation

struct User: Identifiable, Codable {
    let id: String
    var username: String
    var displayName: String?
    var avatarURL: URL?
    var appleUserID: String
    var isPremium: Bool
    var streakCount: Int
    var gameStreak: Int
    var highestWordScore: Int
    var createdAt: Date

    init(id: String = UUID().uuidString,
         username: String,
         displayName: String? = nil,
         avatarURL: URL? = nil,
         appleUserID: String,
         isPremium: Bool = false,
         streakCount: Int = 0,
         gameStreak: Int = 0,
         highestWordScore: Int = 0) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.appleUserID = appleUserID
        self.isPremium = isPremium
        self.streakCount = streakCount
        self.gameStreak = gameStreak
        self.highestWordScore = highestWordScore
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
