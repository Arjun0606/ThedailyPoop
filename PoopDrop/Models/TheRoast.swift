import Foundation

struct RoastPrompt: Identifiable, Codable {
    let id: String
    let publishDate: String
    let storyHeadline: String
    let storySummary: String
    var userEntry: RoastEntry?
    var topEntries: [RoastEntry]?
}

struct RoastEntry: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let text: String
    let aiScore: Int?
    let upvotes: Int
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", username, text
        case aiScore = "ai_score", upvotes
        case createdAt = "created_at"
    }
}

struct RoastSubmitResponse: Codable {
    let entry: RoastEntry
    let aiScore: Int
    let aiFeedback: String
}
