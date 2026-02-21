import ActivityKit
import Foundation

@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<PoopDropActivityAttributes>?
    private var currentBriefingId: String?
    private var currentState: PoopDropActivityAttributes.ContentState?

    // MARK: - Start

    func startDropActivity(briefing: Briefing, storyCount: Int, readCount: Int) {
        // Skip if same briefing already active
        if currentBriefingId == briefing.id && currentActivity != nil {
            // But still update read progress
            if readCount != currentState?.readCount {
                updateReadProgress(readCount: readCount)
            }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

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
            readCount: readCount,
            vibeEmoji: briefing.vibeEmoji ?? "",
            vibeLabel: briefing.vibeLabel ?? "",
            publishDate: displayDate
        )

        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(4 * 60 * 60))

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentBriefingId = briefing.id
            currentState = state

            // Auto-end after 4 hours
            Task {
                try? await Task.sleep(for: .seconds(4 * 60 * 60))
                endCurrentActivity()
            }
        } catch {
            print("Live Activity start error: \(error)")
        }
    }

    // MARK: - Update Progress

    func updateReadProgress(readCount: Int) {
        guard let activity = currentActivity,
              let state = currentState,
              readCount != state.readCount else { return }

        let newState = PoopDropActivityAttributes.ContentState(
            headline: state.headline,
            dropType: state.dropType,
            storyCount: state.storyCount,
            readCount: readCount,
            vibeEmoji: state.vibeEmoji,
            vibeLabel: state.vibeLabel,
            publishDate: state.publishDate
        )
        currentState = newState

        let content = ActivityContent(state: newState, staleDate: Date().addingTimeInterval(4 * 60 * 60))

        Task {
            await activity.update(content)
        }

        // Auto-dismiss when all stories read
        if readCount >= state.storyCount {
            Task {
                try? await Task.sleep(for: .seconds(60))
                endCurrentActivity()
            }
        }
    }

    // MARK: - End

    func endCurrentActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            currentBriefingId = nil
            currentState = nil
        }
    }

    func endAllActivities() {
        Task {
            for activity in Activity<PoopDropActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
            currentBriefingId = nil
            currentState = nil
        }
    }
}
