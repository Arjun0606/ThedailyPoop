import ActivityKit
import Foundation

// MARK: - Live Activity Manager
// Starts, updates, and ends Dynamic Island live activities for new drops.

@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<PoopDropActivityAttributes>?

    // MARK: - Start Live Activity

    /// Call when a new briefing drop loads. Shows on Dynamic Island + Lock Screen.
    func startDropActivity(briefing: Briefing, storyCount: Int, topStoryEmoji: String) {
        // Only iOS 16.2+ supports Live Activities
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }

        // End any existing activity first
        endCurrentActivity()

        let attributes = PoopDropActivityAttributes(briefingId: briefing.id)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let displayDate: String
        if let date = formatter.date(from: briefing.publishDate) {
            formatter.dateFormat = "MMM d"
            displayDate = formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d"
            displayDate = formatter.string(from: Date())
        }

        let state = PoopDropActivityAttributes.ContentState(
            headline: briefing.headline,
            dropType: briefing.dropType,
            storyCount: storyCount,
            topEmoji: topStoryEmoji,
            publishDate: displayDate
        )

        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(30 * 60))

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil  // Local only (no push updates needed)
            )
            print("Live Activity started: \(briefing.dropLabel)")

            // Auto-end after 30 minutes (urgency driver)
            Task {
                try? await Task.sleep(for: .seconds(30 * 60))
                endCurrentActivity()
            }
        } catch {
            print("Live Activity start error: \(error)")
        }
    }

    // MARK: - End Activity

    func endCurrentActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    /// End all activities (call on app terminate or user logout)
    func endAllActivities() {
        Task {
            for activity in Activity<PoopDropActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
        }
    }
}
