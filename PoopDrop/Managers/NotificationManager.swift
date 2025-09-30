import Foundation
import UserNotifications
import AVFoundation

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        checkNotificationPermission()
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await MainActor.run {
                self.isAuthorized = granted
            }
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
    
    // Alias for shorter method name
    func requestPermission() async {
        await requestNotificationPermission()
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Friend Notifications
    
    func sendFriendRequestNotification(to user: User, from sender: User) async {
        let content = UNMutableNotificationContent()
        content.title = "New Friend Request! 👥"
        content.body = "\(sender.username) wants to be your poop buddy!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("friend_request.wav"))
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "friend_request_\(sender.id)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    func sendFriendAcceptedNotification(to user: User, from accepter: User) async {
        let content = UNMutableNotificationContent()
        content.title = "Friend Request Accepted! 🎉"
        content.body = "\(accepter.username) is now your poop buddy!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("celebration.wav"))
        
        let request = UNNotificationRequest(
            identifier: "friend_accepted_\(accepter.id)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Poop Drop Notifications (with sounds!)
    
    func sendPoopMapNotification(to friends: [User], from dropper: User, drop: Drop) async {
        for friend in friends {
            let content = UNMutableNotificationContent()
            
            if drop.isNoPoop {
                content.title = "No Poop Alert! 😵‍💫"
                content.body = "\(dropper.username) had no poop today but kept their streak alive!"
                content.sound = UNNotificationSound(named: UNNotificationSoundName("constipated.wav"))
            } else {
                content.title = "Fresh Drop Alert! 💩"
                content.body = "\(dropper.username) just dropped a poop!"
                
                // Random fart/flush/plop sound!
                let sounds = ["fart_short.wav", "fart_long.wav", "bubble_fart.wav", "plop_single.wav", "big_splash.wav"]
                let randomSound = sounds.randomElement() ?? "fart_short.wav"
                content.sound = UNNotificationSound(named: UNNotificationSoundName(randomSound))
            }
            
            content.badge = 1
            content.userInfo = [
                "type": "poop_drop",
                "dropId": drop.id,
                "dropperId": dropper.id
            ]
            
            let request = UNNotificationRequest(
                identifier: "poop_drop_\(drop.id)_\(friend.id)",
                content: content,
                trigger: nil
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
        
        // Play local sound effect for immediate feedback
        playPoopSound(isNoPoop: drop.isNoPoop)
    }
    
    // MARK: - Reminder Notifications
    
    func schedulePoopReminder(for user: User) async {
        // Cancel existing reminder
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["poop_reminder_\(user.id)"]
        )
        
        let content = UNMutableNotificationContent()
        content.title = "🚨 Poop Check Alert!"
        content.body = "12 hours without logging! Don't break your \(user.streak)-day streak! 🔥💩"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("urgent_reminder.wav"))
        content.badge = 1
        content.userInfo = [
            "type": "poop_reminder",
            "userId": user.id
        ]
        
        // Add action buttons for quick response
        let poopAction = UNNotificationAction(
            identifier: "LOG_POOP",
            title: "Log Poop 💩",
            options: [.foreground]
        )
        let noPoopAction = UNNotificationAction(
            identifier: "NO_POOP",
            title: "No Poop Today 😵‍💫",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "POOP_REMINDER",
            actions: [poopAction, noPoopAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "POOP_REMINDER"
        
        // Trigger after 12 hours
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 12 * 60 * 60, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "poop_reminder_\(user.id)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    func cancelPoopReminder(for user: User) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["poop_reminder_\(user.id)"]
        )
    }
    
    /// Schedule daily streak reminder at a specific time
    func scheduleDailyStreakReminder(for user: User, hour: Int, minute: Int) async {
        // Cancel existing daily reminder
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["daily_streak_reminder_\(user.id)"]
        )
        
        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak! 🔥"
        content.body = "You're on a \(user.streak)-day streak! Log your poop to keep it going 💩"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("urgent_reminder.wav"))
        content.badge = 1
        content.userInfo = [
            "type": "daily_streak_reminder",
            "userId": user.id
        ]
        
        // Create date components for daily trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_streak_reminder_\(user.id)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("📅 Daily streak reminder scheduled for \(hour):\(String(format: "%02d", minute))")
    }
    
    func cancelDailyStreakReminder(for user: User) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["daily_streak_reminder_\(user.id)"]
        )
    }
    
    // MARK: - Comprehensive Notification System
    
    /// Friend dropped a poop
    func notifyFriendPooped(friend: User, drop: Drop, recipients: [User]) async {
        for recipient in recipients {
            let content = UNMutableNotificationContent()
            
            if drop.isNoPoop {
                content.title = "Constipation Update! 😵‍💫"
                content.body = "\(friend.username) is backed up in \(drop.city ?? "somewhere")!"
                content.sound = UNNotificationSound(named: UNNotificationSoundName("sad_trombone.wav"))
            } else {
                content.title = "Fresh Drop Alert! 💩"
                content.body = "\(friend.username) just dropped a poop in \(drop.city ?? "somewhere")!"
                content.sound = UNNotificationSound(named: UNNotificationSoundName(getRandomPoopSound()))
            }
            
            content.userInfo = [
                "type": "friend_pooped",
                "friendId": friend.id,
                "dropId": drop.id,
                "city": drop.city ?? "Unknown"
            ]
            content.badge = 1
            
            // Add action buttons
            let viewAction = UNNotificationAction(identifier: "VIEW_DROP", title: "View Drop 👀", options: [.foreground])
            let reactAction = UNNotificationAction(identifier: "QUICK_REACT", title: "React 😂", options: [])
            let whereAction = UNNotificationAction(identifier: "WHERE", title: "Where? 🗺️", options: [.foreground])
            
            let category = UNNotificationCategory(
                identifier: "FRIEND_POOP",
                actions: [viewAction, reactAction, whereAction],
                intentIdentifiers: [],
                options: []
            )
            
            UNUserNotificationCenter.current().setNotificationCategories([category])
            content.categoryIdentifier = "FRIEND_POOP"
            
            let request = UNNotificationRequest(
                identifier: "friend_poop_\(friend.id)_\(drop.id)",
                content: content,
                trigger: nil
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
    
    /// Friend broke their streak
    func notifyStreakBroken(friend: User, previousStreak: Int, recipients: [User]) async {
        for recipient in recipients {
            let content = UNMutableNotificationContent()
            content.title = "Streak Broken! 💔"
            content.body = "\(friend.username) broke their \(previousStreak)-day streak! Send them support! 🔥💔"
            content.sound = UNNotificationSound(named: UNNotificationSoundName("sad_trombone.wav"))
            content.userInfo = [
                "type": "streak_broken",
                "friendId": friend.id,
                "previousStreak": previousStreak
            ]
            content.badge = 1
            
            let supportAction = UNNotificationAction(identifier: "SEND_SUPPORT", title: "Send Support 💪", options: [.foreground])
            let encourageAction = UNNotificationAction(identifier: "ENCOURAGE", title: "Encourage 🎉", options: [])
            
            let category = UNNotificationCategory(
                identifier: "STREAK_BROKEN",
                actions: [supportAction, encourageAction],
                intentIdentifiers: [],
                options: []
            )
            
            UNUserNotificationCenter.current().setNotificationCategories([category])
            content.categoryIdentifier = "STREAK_BROKEN"
            
            let request = UNNotificationRequest(
                identifier: "streak_broken_\(friend.id)_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
    
    /// Friend reacted to your drop
    func notifyReaction(from reactor: User, to dropOwner: User, emoji: String, dropId: String) async {
        let content = UNMutableNotificationContent()
        content.title = "\(reactor.username) reacted to your drop!"
        content.body = "\(emoji) - Check it out!"
        content.sound = UNNotificationSound.default
        content.userInfo = [
            "type": "reaction",
            "reactorId": reactor.id,
            "dropId": dropId,
            "emoji": emoji
        ]
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "reaction_\(dropId)_\(reactor.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// Friend request received
    func notifyFriendRequestReceived(from sender: User, to recipient: User) async {
        let content = UNMutableNotificationContent()
        content.title = "New Friend Request! 👥"
        content.body = "\(sender.username) wants to be your poop buddy!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("friend_request.wav"))
        content.userInfo = [
            "type": "friend_request",
            "senderId": sender.id,
            "senderUsername": sender.username
        ]
        content.badge = 1
        
        let acceptAction = UNNotificationAction(identifier: "ACCEPT_FRIEND", title: "Accept 🤝", options: [])
        let declineAction = UNNotificationAction(identifier: "DECLINE_FRIEND", title: "Decline ❌", options: [])
        let viewAction = UNNotificationAction(identifier: "VIEW_PROFILE", title: "View Profile 👤", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "FRIEND_REQUEST",
            actions: [acceptAction, declineAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "FRIEND_REQUEST"
        
        let request = UNNotificationRequest(
            identifier: "friend_request_\(sender.id)_\(recipient.id)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// Friend request accepted
    func notifyFriendRequestAccepted(from accepter: User, to requester: User) async {
        let content = UNMutableNotificationContent()
        content.title = "Friend Request Accepted! 🎉"
        content.body = "\(accepter.username) is now your poop buddy! Time to share some drops! 💩"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("celebration.wav"))
        content.userInfo = [
            "type": "friend_accepted",
            "friendId": accepter.id,
            "friendUsername": accepter.username
        ]
        content.badge = 1
        
        let viewAction = UNNotificationAction(identifier: "VIEW_FRIEND", title: "View Friend 👤", options: [.foreground])
        let sayHiAction = UNNotificationAction(identifier: "SAY_HI", title: "Say Hi! 👋", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "FRIEND_ACCEPTED",
            actions: [viewAction, sayHiAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "FRIEND_ACCEPTED"
        
        let request = UNNotificationRequest(
            identifier: "friend_accepted_\(accepter.id)_\(requester.id)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// Reaction to user's drop
    func notifyDropReaction(reactor: User, drop: Drop, reaction: String, isEmoji: Bool, to dropOwner: User) async {
        let content = UNMutableNotificationContent()
        
        if isEmoji {
            content.title = "New Reaction! \(reaction)"
            content.body = "\(reactor.username) reacted to your drop with \(reaction)!"
        } else {
            content.title = "New Comment! 💬"
            content.body = "\(reactor.username) commented on your drop: \"\(String(reaction.prefix(50)))\""
        }
        
        content.sound = UNNotificationSound(named: UNNotificationSoundName(getRandomSocialSound()))
        content.userInfo = [
            "type": "drop_reaction",
            "reactorId": reactor.id,
            "dropId": drop.id,
            "reaction": reaction,
            "isEmoji": isEmoji
        ]
        content.badge = 1
        
        let viewAction = UNNotificationAction(identifier: "VIEW_REACTION", title: "View Drop 👀", options: [.foreground])
        let reactBackAction = UNNotificationAction(identifier: "REACT_BACK", title: "React Back 😂", options: [])
        
        let category = UNNotificationCategory(
            identifier: "DROP_REACTION",
            actions: [viewAction, reactBackAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "DROP_REACTION"
        
        let request = UNNotificationRequest(
            identifier: "reaction_\(reactor.id)_\(drop.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Sound Library
    
    private func getRandomPoopSound() -> String {
        let poopSounds = [
            "fart_short.wav",
            "fart_long.wav", 
            "bubble_fart.wav",
            "squeaky_fart.wav",
            "wet_fart.wav",
            "plop_single.wav",
            "big_splash.wav"
        ]
        return poopSounds.randomElement() ?? "fart_short.wav"
    }
    
    private func getRandomSocialSound() -> String {
        let socialSounds = [
            "gentle_chime.wav",
            "friend_ping.wav",
            "social_ding.wav",
            "notification_bell.wav"
        ]
        return socialSounds.randomElement() ?? "gentle_chime.wav"
    }
    
    // MARK: - Sound Effects
    
    private func playPoopSound(isNoPoop: Bool) {
        let soundName: String
        
        if isNoPoop {
            soundName = "constipated"
        } else {
            soundName = getRandomPoopSound()
        }
        
        guard let path = Bundle.main.path(forResource: soundName, ofType: "wav") else {
            print("Sound file not found: \(soundName)")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    // MARK: - Badge Management
    
    func updateAppBadge(count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        updateAppBadge(count: 0)
    }
}
