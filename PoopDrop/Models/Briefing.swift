import Foundation

struct Briefing: Identifiable, Codable {
    let id: String
    let publishDate: String
    let dropType: String
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
        case dropType = "drop_type"
        case headline
        case introText = "intro_text"
        case storyCount = "story_count"
        case freeStoryCount = "free_story_count"
        case status
        case publishedAt = "published_at"
        case createdAt = "created_at"
    }

    var dropLabel: String {
        switch dropType {
        case "daily": return "TODAY'S BRIEFING"
        case "morning": return "MORNING DROP"
        case "midday": return "MIDDAY DROP"
        case "evening": return "EVENING WRAP"
        default: return "BRIEFING"
        }
    }

    var dropEmoji: String {
        switch dropType {
        case "daily": return "💩"
        case "morning": return "☀️"
        case "midday": return "🔥"
        case "evening": return "🌙"
        default: return "💩"
        }
    }
}

struct BriefingDrop: Identifiable, Codable {
    var id: String { briefing.id }
    let briefing: Briefing
    let stories: [Story]
}
