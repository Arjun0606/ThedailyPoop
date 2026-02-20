import ActivityKit
import Foundation

// MARK: - Live Activity Attributes
// This file must be included in BOTH the main app target AND the widget extension target.
// It defines the data contract between the app (which starts activities) and
// the widget (which renders them on Dynamic Island + Lock Screen).

struct PoopDropActivityAttributes: ActivityAttributes {
    // Dynamic data that can change during the activity
    struct ContentState: Codable, Hashable {
        let headline: String
        let dropType: String        // "morning", "midday", "evening"
        let storyCount: Int
        let topEmoji: String        // First story emoji
        let publishDate: String     // "Feb 19"
    }

    // Fixed context (set once at creation)
    let briefingId: String

    // Helpers
    static func dropEmoji(for dropType: String) -> String {
        switch dropType {
        case "morning": return "\u{2600}\u{FE0F}"  // sun
        case "midday": return "\u{1F525}"           // fire
        case "evening": return "\u{1F319}"          // moon
        default: return "\u{1F4F0}"                 // newspaper
        }
    }

    static func dropLabel(for dropType: String) -> String {
        switch dropType {
        case "morning": return "MORNING DROP"
        case "midday": return "MIDDAY DROP"
        case "evening": return "EVENING WRAP"
        default: return "NEW DROP"
        }
    }
}
