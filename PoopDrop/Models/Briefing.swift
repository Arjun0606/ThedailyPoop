import Foundation

struct Briefing: Identifiable, Codable {
    let id: String
    let publishDate: String
    let headline: String
    let introText: String?
    let storyCount: Int
    let freeStoryCount: Int
    let status: String
    let publishedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case publishDate = "publish_date"
        case headline
        case introText = "intro_text"
        case storyCount = "story_count"
        case freeStoryCount = "free_story_count"
        case status
        case publishedAt = "published_at"
        case createdAt = "created_at"
    }
}
