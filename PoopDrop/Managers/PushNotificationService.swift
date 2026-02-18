import Foundation
import UserNotifications

// MARK: - Push Notification Service
// Registers device tokens with Supabase and triggers engagement notifications.
// Key triggers that drive retention + revenue:
//   "Your morning briefing just dropped" → opens briefing, drives daily habit
//   "Breaking: [headline]" → urgency, drives opens
//   "Your streak is at risk!" → loss aversion, keeps streak alive

@MainActor
class PushNotificationService {
    static let shared = PushNotificationService()

    /// Register device token with Supabase for push targeting
    func registerDeviceToken(_ token: String, userID: String) async {
        struct TokenRow: Encodable {
            let user_id: String
            let device_token: String
            let platform: String
        }

        do {
            try await SupabaseManager.shared.client.from("device_tokens")
                .upsert(TokenRow(
                    user_id: userID,
                    device_token: token,
                    platform: "ios"
                ))
                .execute()
            print("Device token registered for user \(userID)")
        } catch {
            print("Failed to register device token: \(error)")
        }
    }

    // MARK: - Local Notification Triggers

    /// "Your morning briefing just dropped" — drives daily opens
    func notifyNewBriefing(dropType: String) {
        let (title, body) = dropTitle(for: dropType)
        schedule(
            title: title,
            body: body,
            type: "new_drop",
            delay: 0
        )
    }

    /// "Breaking story" — urgency notification
    func notifyBreakingStory(headline: String) {
        schedule(
            title: "Breaking",
            body: headline,
            type: "new_drop",
            delay: 0
        )
    }

    /// "Your streak is at risk!" — loss aversion
    func notifyStreakAtRisk(currentStreak: Int) {
        schedule(
            title: "Your \(currentStreak)-day streak is at risk",
            body: "Read at least one story today to keep it alive!",
            type: "streak_reminder",
            delay: 0
        )
    }

    // MARK: - Re-engagement Nudges

    /// Schedule a "you're missing out" nudge for 24h later
    func scheduleReengagement() {
        schedule(
            title: "You're missing out",
            body: "Today's stories are going viral. Catch up before everyone else.",
            type: "reengagement",
            delay: 86400 // 24 hours
        )
    }

    /// Schedule daily briefing reminder
    func scheduleDailyReminder() {
        // Fire at 7:30 AM local time (just after morning drop)
        var dateComponents = DateComponents()
        dateComponents.hour = 7
        dateComponents.minute = 30

        let content = UNMutableNotificationContent()
        content.title = "Your morning briefing is ready"
        content.body = "10 stories to start your day. Quick reads, zero fluff."
        content.sound = .default
        content.userInfo = ["type": "new_drop"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_briefing_reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Failed to schedule daily reminder: \(error)") }
        }
    }

    // MARK: - Private

    private func dropTitle(for dropType: String) -> (String, String) {
        switch dropType {
        case "morning":
            return ("Your morning briefing just dropped", "10 stories to start your day. Read time: 5 min.")
        case "midday":
            return ("Midday update is live", "5 stories you need to see before end of day.")
        case "evening":
            return ("Tonight's wrap is ready", "3 stories to close out the day.")
        default:
            return ("New briefing available", "Fresh stories are waiting for you.")
        }
    }

    private func schedule(title: String, body: String, type: String, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["type": type]

        let trigger: UNNotificationTrigger?
        if delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }

        let id = "\(type)_\(UUID().uuidString.prefix(8))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
