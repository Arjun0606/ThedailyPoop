import Foundation
import UserNotifications

// MARK: - Push Notification Service
// Registers device tokens with Supabase and triggers engagement notifications.
// Key triggers that drive retention + revenue:
//   "Someone posted gossip about you" → opens gossip, drives reveals ($1.99)
//   "New drop in [group]" → opens map, drives engagement
//   "Your group has a new challenge" → opens challenge, daily habit
//   "[Name] joined your group" → social proof, keeps groups alive

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
            print("📱 Device token registered for user \(userID)")
        } catch {
            print("Failed to register device token: \(error)")
        }
    }

    // MARK: - Local Notification Triggers
    // These fire immediately for in-app events. Server-side push handles cross-device.

    /// "Someone posted gossip in [group]" — drives opens + reveals
    func notifyNewGossip(groupName: String, groupEmoji: String) {
        schedule(
            title: "\(groupEmoji) New gossip in \(groupName)",
            body: "Someone just posted anonymous gossip. Can you figure out who? 👀",
            type: "new_gossip",
            delay: 0
        )
    }

    /// "You were mentioned in gossip" — THE highest-converting notification
    func notifyMentionedInGossip(groupName: String) {
        schedule(
            title: "🚨 Someone is talking about you",
            body: "Anonymous gossip mentioning you was just posted in \(groupName). Pay $1.99 to reveal who.",
            type: "new_gossip",
            delay: 0
        )
    }

    /// "New drop nearby" — drives map opens
    func notifyNewDrop(username: String, locationName: String?) {
        let location = locationName ?? "somewhere"
        schedule(
            title: "💩 @\(username) just dropped",
            body: "New poop pin at \(location). Check the map!",
            type: "new_drop",
            delay: 0
        )
    }

    /// "[Name] joined your group" — social proof
    func notifyGroupJoin(username: String, groupName: String) {
        schedule(
            title: "👋 @\(username) joined \(groupName)",
            body: "Your group is growing! Drop a poop to welcome them.",
            type: "new_drop",
            delay: 0
        )
    }

    /// Daily challenge available — drives daily habit
    func notifyDailyChallenge(groupName: String, groupEmoji: String) {
        schedule(
            title: "\(groupEmoji) Daily challenge in \(groupName)",
            body: "A new challenge just dropped. Respond before everyone else!",
            type: "new_gossip",
            delay: 0
        )
    }

    // MARK: - Re-engagement Nudges
    // Scheduled for users who haven't opened the app

    /// Schedule a "you're missing out" nudge for 24h later
    func scheduleReengagement(groupName: String) {
        schedule(
            title: "💩 Your group misses you",
            body: "There's new gossip and drops in \(groupName). Don't miss out!",
            type: "new_gossip",
            delay: 86400 // 24 hours
        )
    }

    /// Schedule daily drop reminder
    func scheduleDailyReminder() {
        // Fire at 2 PM local time
        var dateComponents = DateComponents()
        dateComponents.hour = 14
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "💩 Time for your daily drop"
        content.body = "Your friends are waiting. Drop a poop and keep your streak alive!"
        content.sound = .default
        content.userInfo = ["type": "new_drop"]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_drop_reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Failed to schedule daily reminder: \(error)") }
        }
    }

    // MARK: - Private

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
