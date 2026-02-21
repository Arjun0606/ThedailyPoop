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
    let imageUrl: String?
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
        case imageUrl = "image_url"
        case emoji
        case createdAt = "created_at"
    }

    var categoryLabel: String {
        switch category {
        case "business": return "Business"
        case "tech": return "Tech"
        case "politics": return "Politics"
        case "sports": return "Sports"
        case "culture": return "Culture"
        default: return category.capitalized
        }
    }

    var categoryEmoji: String {
        if let emoji = emoji { return emoji }
        switch category {
        case "business": return "💰"
        case "tech": return "📱"
        case "politics": return "🏛️"
        case "sports": return "🏆"
        default: return "🎬"
        }
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

    /// Body text with "The Bottom Line:" stripped and structural labels removed
    var bodyWithoutBottomLine: String {
        var text = body

        // Strip "The Bottom Line:" and everything after
        if let range = text.range(of: "\nThe Bottom Line:", options: .caseInsensitive) ?? text.range(of: "The Bottom Line:", options: .caseInsensitive) {
            text = String(text[text.startIndex..<range.lowerBound])
        }

        // Strip structural labels the AI sometimes outputs (with and without colons)
        let labels = [
            "HOOK:", "HOOK",
            "THE HOOK:", "THE HOOK",
            "THE FACTS:", "THE FACTS",
            "WHAT WENT DOWN:", "WHAT WENT DOWN",
            "WHY IT MATTERS:", "WHY IT MATTERS",
            "WHY THIS HITS:", "WHY THIS HITS",
            "WHAT HAPPENED:", "WHAT HAPPENED",
            "THE STORY:", "THE STORY",
            "THE CONTEXT:", "THE CONTEXT",
            "CONTEXT:", "CONTEXT",
            "THE IMPACT:", "THE IMPACT",
            "IMPACT:", "IMPACT",
        ]
        // Replace labels that appear on their own line
        for label in labels {
            text = text.replacingOccurrences(of: "\n\(label)\n", with: "\n", options: .caseInsensitive)
            text = text.replacingOccurrences(of: "\n\(label)\r\n", with: "\n", options: .caseInsensitive)
        }
        // Also strip if at the very start of the text
        for label in labels {
            if text.uppercased().hasPrefix(label.uppercased()) {
                let idx = text.index(text.startIndex, offsetBy: label.count)
                text = String(text[idx...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
