import Foundation

struct Story: Identifiable, Codable {
    let id: String
    let briefingId: String
    let sortOrder: Int
    let isFree: Bool
    let category: String
    let headline: String
    let body: String
    let tldr: String?
    let sourceUrl: String?
    let sourceName: String?
    let emoji: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case briefingId = "briefing_id"
        case sortOrder = "sort_order"
        case isFree = "is_free"
        case category
        case headline
        case body
        case tldr
        case sourceUrl = "source_url"
        case sourceName = "source_name"
        case emoji
        case createdAt = "created_at"
    }

    var categoryLabel: String {
        switch category {
        case "business": return "Business"
        case "tech": return "Tech"
        case "culture": return "Culture"
        default: return category.capitalized
        }
    }

    var categoryEmoji: String {
        emoji ?? (category == "business" ? "💰" : category == "tech" ? "📱" : "🎬")
    }

    var readingTimeMinutes: Int {
        let wordCount = body.split(separator: " ").count
        return max(1, Int(ceil(Double(wordCount) / 200.0)))
    }

    var bottomLine: String? {
        guard let range = body.range(of: "The Bottom Line:", options: .caseInsensitive) else { return nil }
        let after = body[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        if let newline = after.firstIndex(of: "\n") {
            return String(after[after.startIndex..<newline]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return after.isEmpty ? nil : after
    }
}
