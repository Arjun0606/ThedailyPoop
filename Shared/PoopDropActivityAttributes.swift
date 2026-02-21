import ActivityKit
import Foundation

// MARK: - Live Activity Attributes
// Included in BOTH the main app target AND the widget extension target.

struct PoopDropActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let headline: String
        let dropType: String         // "daily", "morning", "midday", "evening"
        let storyCount: Int
        let readCount: Int           // Live read progress
        let vibeEmoji: String        // Today's Vibe emoji
        let vibeLabel: String        // Today's Vibe label
        let publishDate: String      // "Feb 19"
    }

    let briefingId: String

    static func dropEmoji(for dropType: String) -> String {
        switch dropType {
        case "daily", "morning": return "\u{2600}\u{FE0F}"
        case "midday": return "\u{1F525}"
        case "evening": return "\u{1F319}"
        default: return "\u{1F4A9}"
        }
    }

    static func dropLabel(for dropType: String) -> String {
        switch dropType {
        case "daily": return "TODAY'S BRIEFING"
        case "morning": return "MORNING DROP"
        case "midday": return "MIDDAY DROP"
        case "evening": return "EVENING WRAP"
        default: return "NEW DROP"
        }
    }

    static func dropColorRGB(for dropType: String) -> (r: Double, g: Double, b: Double) {
        switch dropType {
        case "daily", "morning": return (1.0, 0.76, 0.28)
        case "midday": return (1.0, 0.55, 0.2)
        case "evening": return (0.5, 0.4, 1.0)
        default: return (1.0, 0.76, 0.28)
        }
    }
}
