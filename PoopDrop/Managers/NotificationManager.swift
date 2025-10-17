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
    
    // MARK: - TheDailyPoop Notifications (with sounds!)
    
    func sendTheDailyPoopNotification(to friends: [User], from dropper: User, drop: Drop) async {
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
    
    // MARK: - Comeback/Retention Notifications
    
    /// Send "comeback" notification when user hasn't opened app in 24+ hours
    func sendComebackNotification(to user: User, friendsActive: Int = 0) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        
        if friendsActive > 0 {
            content.title = "Your friends miss you! 👋"
            content.body = "\(friendsActive) friends are active today. Don't miss out on the fun!"
        } else {
            content.title = "Come back! 💩"
            content.body = "Your streak is waiting. Keep it alive!"
        }
        
        content.sound = UNNotificationSound(named: UNNotificationSoundName("gentle_chime.wav"))
        content.userInfo = ["type": "comeback"]
        content.badge = 1
        
        // Trigger in 1 minute (for testing, would be 24-48 hours in production)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "comeback_\(user.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("🔔 Comeback notification scheduled for \(user.username)")
    }
    
    /// Notify when friends are online (creates urgency)
    func sendFriendsActiveNotification(to user: User, activeFriends: [User]) async {
        guard isAuthorized, activeFriends.count > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Friends are online now! 🟢"
        
        if activeFriends.count == 1 {
            content.body = "\(activeFriends[0].username) is dropping poops right now. Join them!"
        } else if activeFriends.count == 2 {
            content.body = "\(activeFriends[0].username) and \(activeFriends[1].username) are active. Join the party!"
        } else {
            content.body = "\(activeFriends.count) friends are active. Don't miss out!"
        }
        
        content.sound = UNNotificationSound(named: UNNotificationSoundName("gentle_chime.wav"))
        content.userInfo = ["type": "friends_active", "count": activeFriends.count]
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "friends_active_\(user.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// Notify when someone reacts to your fart attack
    func notifyAttackReaction(to userID: String, reactorUsername: String, attackID: String, emoji: String, text: String?) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(reactorUsername) reacted to your attack! \(emoji)"
        if let text = text, !text.isEmpty {
            content.body = text
        } else {
            content.body = "Check out what they said!"
        }
        content.sound = UNNotificationSound(named: UNNotificationSoundName("gentle_chime.wav"))
        content.userInfo = ["type": "attack_reaction", "attackID": attackID, "reactor": reactorUsername]
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "attack_reaction_\(attackID)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// Notify about weekly leaderboard ranking
    func sendWeeklyLeaderboardNotification(to user: User, rank: Int, totalPlayers: Int) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Weekly Leaderboard Update! 🏆"
        
        if rank <= 3 {
            content.body = "You're #\(rank)! Stay on top by sending more attacks!"
        } else if rank <= 10 {
            content.body = "You're #\(rank). Keep climbing to reach the top 3!"
        } else {
            content.body = "You're #\(rank) of \(totalPlayers). Buy attacks to climb faster!"
        }
        
        content.sound = UNNotificationSound(named: UNNotificationSoundName("celebration.wav"))
        content.userInfo = ["type": "leaderboard", "rank": rank]
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "leaderboard_\(user.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Aggressive Competitive Notifications 🔥
    
    /// "You got attacked! Get revenge NOW!"
    func sendRevengeNotification(to victim: User, from attacker: User, attackID: String) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "💨 \(attacker.username) just attacked you!"
        content.body = "Don't let them win! Attack them back NOW!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("fart_long.wav"))
        content.userInfo = ["type": "revenge", "attackerID": attacker.id, "attackID": attackID]
        content.badge = 1
        content.interruptionLevel = .timeSensitive // iOS 15+ - breaks through Focus modes
        
        // Action buttons
        let revengeAction = UNNotificationAction(identifier: "REVENGE_NOW", title: "💥 Attack Back", options: [.foreground])
        let ignoreAction = UNNotificationAction(identifier: "IGNORE", title: "Later", options: [])
        
        let category = UNNotificationCategory(
            identifier: "REVENGE_ATTACK",
            actions: [revengeAction, ignoreAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "REVENGE_ATTACK"
        
        let request = UNNotificationRequest(
            identifier: "revenge_\(attackID)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// "You're 1 attack away from beating [friend]!"
    func sendLeaderboardCompetitionNotification(to user: User, competitorName: String, attacksNeeded: Int, currentRank: Int) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 You're SO close to beating \(competitorName)!"
        
        if attacksNeeded == 1 {
            content.body = "Just 1 more attack to reach #\(currentRank - 1) on the leaderboard!"
        } else {
            content.body = "Only \(attacksNeeded) attacks to pass them. Buy a pack now!"
        }
        
        content.sound = UNNotificationSound(named: UNNotificationSoundName("urgent_reminder.wav"))
        content.userInfo = ["type": "leaderboard_competition", "competitorName": competitorName, "attacksNeeded": attacksNeeded]
        content.badge = 1
        content.interruptionLevel = .timeSensitive
        
        let buyAction = UNNotificationAction(identifier: "BUY_ATTACKS", title: "⚡️ Buy Attacks", options: [.foreground])
        let attackAction = UNNotificationAction(identifier: "SEND_ATTACK", title: "🎯 Send Attack", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "LEADERBOARD_COMPETITION",
            actions: [buyAction, attackAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "LEADERBOARD_COMPETITION"
        
        let request = UNNotificationRequest(
            identifier: "competition_\(user.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// "Your friend just passed you on the leaderboard!"
    func sendLeaderboardOvertakenNotification(to user: User, overtakenBy friend: User, oldRank: Int, newRank: Int) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "😱 \(friend.username) just passed you!"
        content.body = "You dropped from #\(oldRank) to #\(newRank). Fight back!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("sad_trombone.wav"))
        content.userInfo = ["type": "leaderboard_overtaken", "friendID": friend.id, "oldRank": oldRank, "newRank": newRank]
        content.badge = 1
        content.interruptionLevel = .timeSensitive
        
        let buyAction = UNNotificationAction(identifier: "BUY_ATTACKS_REVENGE", title: "⚡️ Buy Attacks", options: [.foreground])
        let attackAction = UNNotificationAction(identifier: "ATTACK_OVERTAKER", title: "💥 Attack \(friend.username)", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "LEADERBOARD_OVERTAKEN",
            actions: [buyAction, attackAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "LEADERBOARD_OVERTAKEN"
        
        let request = UNNotificationRequest(
            identifier: "overtaken_\(user.id)_\(friend.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// "Someone just bought an attack pack - don't fall behind!"
    func sendFriendPurchasedNotification(to user: User, friendUsername: String) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🛒 \(friendUsername) just bought attack packs!"
        content.body = "They're coming for your rank. Stay ahead!"
        content.sound = UNNotificationSound.default
        content.userInfo = ["type": "friend_purchased", "friendUsername": friendUsername]
        content.badge = 1
        
        let buyAction = UNNotificationAction(identifier: "BUY_ATTACKS_MATCH", title: "⚡️ Buy Attacks", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "FRIEND_PURCHASED",
            actions: [buyAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "FRIEND_PURCHASED"
        
        let request = UNNotificationRequest(
            identifier: "friend_purchased_\(user.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// "You're out of attacks! Buy more to keep dominating"
    func sendOutOfAttacksNotification(to user: User) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "😭 You're out of Fart Attacks!"
        content.body = "Buy more to keep pranking your friends!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("urgent_reminder.wav"))
        content.userInfo = ["type": "out_of_attacks"]
        content.badge = 1
        content.interruptionLevel = .timeSensitive
        
        let buyAction = UNNotificationAction(identifier: "BUY_ATTACKS_NOW", title: "⚡️ Buy 3 for $1.99", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "OUT_OF_ATTACKS",
            actions: [buyAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "OUT_OF_ATTACKS"
        
        let request = UNNotificationRequest(
            identifier: "out_of_attacks_\(user.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    /// "You're losing your streak! Friend is about to beat you!"
    func sendStreakCompetitionNotification(to user: User, friendUsername: String, friendStreak: Int) async {
        guard isAuthorized, user.streak < friendStreak else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ \(friendUsername) is beating your streak!"
        content.body = "They have \(friendStreak) days. You have \(user.streak). Log your poop NOW!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("urgent_reminder.wav"))
        content.userInfo = ["type": "streak_competition", "friendUsername": friendUsername]
        content.badge = 1
        content.interruptionLevel = .timeSensitive
        
        let logAction = UNNotificationAction(identifier: "LOG_POOP_NOW", title: "💩 Log Poop", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "STREAK_COMPETITION",
            actions: [logAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "STREAK_COMPETITION"
        
        let request = UNNotificationRequest(
            identifier: "streak_comp_\(user.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - 🚀 PHASE 1: CORE ENGAGEMENT HOOKS (CRITICAL FOR VIRALITY & MRR)
    
    /// 👻 Ghost Attack Received - THE #1 HOOK
    func sendGhostAttackNotification(to victim: User, attackID: String) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "👻 Someone just sent a fart your way!"
        content.body = "Tap to hear it and guess who's behind it!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(getRandomPoopSound()))
        content.userInfo = [
            "type": "ghost_attack",
            "attackID": attackID,
            "deepLink": "attack" // Opens to GhostAttackReceivedView
        ]
        content.badge = 1
        content.interruptionLevel = .timeSensitive
        
        // Action buttons to drive immediate engagement
        let guessAction = UNNotificationAction(identifier: "GUESS_NOW", title: "🕵️ Guess Now", options: [.foreground])
        let revealAction = UNNotificationAction(identifier: "REVEAL_SENDER", title: "💰 Reveal ($0.99)", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "GHOST_ATTACK",
            actions: [guessAction, revealAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "GHOST_ATTACK"
        
        let request = UNNotificationRequest(
            identifier: "ghost_attack_\(attackID)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("👻 Ghost attack notification sent for attack \(attackID)")
    }
    
    /// 💩 Friend Dropped a Poop - Creates FOMO
    func sendFriendDroppedNotification(friend: User, drop: Drop, to recipients: [User]) async {
        guard isAuthorized else { return }
        
        for recipient in recipients {
            let content = UNMutableNotificationContent()
            content.title = "💩 \(friend.username) just took a dump!"
            content.body = "In \(drop.city ?? "somewhere mysterious") • Tap to see where and react!"
            content.sound = UNNotificationSound(named: UNNotificationSoundName(getRandomPoopSound()))
            content.userInfo = [
                "type": "friend_dropped",
                "friendId": friend.id,
                "dropId": drop.id,
                "deepLink": "map"
            ]
            content.badge = 1
            
            // Action buttons
            let viewAction = UNNotificationAction(identifier: "VIEW_DROP", title: "👀 View Drop", options: [.foreground])
            let reactAction = UNNotificationAction(identifier: "REACT_NOW", title: "😂 React", options: [.foreground])
            
            let category = UNNotificationCategory(
                identifier: "FRIEND_DROPPED",
                actions: [viewAction, reactAction],
                intentIdentifiers: [],
                options: []
            )
            
            UNUserNotificationCenter.current().setNotificationCategories([category])
            content.categoryIdentifier = "FRIEND_DROPPED"
            
            let request = UNNotificationRequest(
                identifier: "friend_dropped_\(drop.id)_\(recipient.id)",
                content: content,
                trigger: nil
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
        print("💩 Friend drop notification sent to \(recipients.count) recipients")
    }
    
    /// 😂 Someone Reacted to Your Drop - Social Validation + Points
    func sendDropReactionNotification(reactor: User, dropOwner: User, emoji: String, dropId: String, pointsEarned: Int) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "😂 \(reactor.username) reacted to your drop!"
        content.body = "They sent \(emoji) • You earned +\(pointsEarned) points!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(getRandomSocialSound()))
        content.userInfo = [
            "type": "drop_reaction",
            "reactorId": reactor.id,
            "dropId": dropId,
            "emoji": emoji,
            "deepLink": "feed"
        ]
        content.badge = 1
        
        let viewAction = UNNotificationAction(identifier: "VIEW_DROP_REACTION", title: "👀 View Drop", options: [.foreground])
        let reactBackAction = UNNotificationAction(identifier: "REACT_BACK_NOW", title: "😎 React Back", options: [])
        
        let category = UNNotificationCategory(
            identifier: "DROP_REACTION_NEW",
            actions: [viewAction, reactBackAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "DROP_REACTION_NEW"
        
        let request = UNNotificationRequest(
            identifier: "drop_reaction_\(dropId)_\(reactor.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("😂 Drop reaction notification sent to \(dropOwner.username)")
    }
    
    /// 📊 New Poll Created - Drives Poll Engagement
    func sendNewPollNotification(creator: User, pollQuestion: String, to recipients: [User]) async {
        guard isAuthorized else { return }
        
        for recipient in recipients {
            let content = UNMutableNotificationContent()
            content.title = "📊 New poll: \"\(pollQuestion)\""
            content.body = "Vote for a friend now • Earn +5 points!"
            content.sound = UNNotificationSound(named: UNNotificationSoundName("gentle_chime.wav"))
            content.userInfo = [
                "type": "new_poll",
                "creatorId": creator.id,
                "deepLink": "poll"
            ]
            content.badge = 1
            
            let voteAction = UNNotificationAction(identifier: "VOTE_NOW", title: "🗳️ Vote Now", options: [.foreground])
            
            let category = UNNotificationCategory(
                identifier: "NEW_POLL",
                actions: [voteAction],
                intentIdentifiers: [],
                options: []
            )
            
            UNUserNotificationCenter.current().setNotificationCategories([category])
            content.categoryIdentifier = "NEW_POLL"
            
            let request = UNNotificationRequest(
                identifier: "new_poll_\(recipient.id)_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
        print("📊 New poll notification sent to \(recipients.count) recipients")
    }
    
    /// 🏆 Poll Results Are In - Payoff for Participation
    func sendPollResultsNotification(pollQuestion: String, winnerName: String, to recipients: [User]) async {
        guard isAuthorized else { return }
        
        for recipient in recipients {
            let content = UNMutableNotificationContent()
            content.title = "🏆 Poll results are in!"
            content.body = "\(winnerName) won \"\(pollQuestion)\" • Tap to see full results!"
            content.sound = UNNotificationSound(named: UNNotificationSoundName("celebration.wav"))
            content.userInfo = [
                "type": "poll_results",
                "deepLink": "poll"
            ]
            content.badge = 1
            
            let viewAction = UNNotificationAction(identifier: "VIEW_POLL_RESULTS", title: "📊 View Results", options: [.foreground])
            
            let category = UNNotificationCategory(
                identifier: "POLL_RESULTS",
                actions: [viewAction],
                intentIdentifiers: [],
                options: []
            )
            
            UNUserNotificationCenter.current().setNotificationCategories([category])
            content.categoryIdentifier = "POLL_RESULTS"
            
            let request = UNNotificationRequest(
                identifier: "poll_results_\(recipient.id)_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
        print("🏆 Poll results notification sent to \(recipients.count) recipients")
    }
    
    // MARK: - 💰 PHASE 1: MONETIZATION HOOKS (REVENUE DRIVERS)
    
    /// ⚠️ Low on Ghost Attacks - Scarcity + Urgency
    func sendLowAttacksNotification(to user: User, attacksRemaining: Int) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        
        if attacksRemaining == 0 {
            content.title = "😭 You're out of Ghost Attacks!"
            content.body = "Stock up now so you don't miss your chance for revenge!"
        } else {
            content.title = "⚠️ Only \(attacksRemaining) Ghost Attack\(attacksRemaining == 1 ? "" : "s") left!"
            content.body = "Stock up now so you don't miss your chance for revenge!"
        }
        
        content.sound = UNNotificationSound(named: UNNotificationSoundName("urgent_reminder.wav"))
        content.userInfo = [
            "type": "low_attacks",
            "deepLink": "shop"
        ]
        content.badge = 1
        content.interruptionLevel = .timeSensitive
        
        let buyAction = UNNotificationAction(identifier: "BUY_ATTACKS_LOW", title: "🛒 Buy 3 for $2.99", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "LOW_ATTACKS",
            actions: [buyAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "LOW_ATTACKS"
        
        let request = UNNotificationRequest(
            identifier: "low_attacks_\(user.id)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("⚠️ Low attacks notification sent to \(user.username)")
    }
    
    /// 📉/📈 Leaderboard Position Changed - Competition + Direct CTA
    func sendLeaderboardRankChangeNotification(to user: User, oldRank: Int, newRank: Int, competitorName: String?) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        
        if newRank < oldRank {
            // User moved UP
            content.title = "📈 You're now #\(newRank) on the leaderboard!"
            content.body = "Keep it up! Stay ahead with a 2X Points Boost!"
            content.sound = UNNotificationSound(named: UNNotificationSoundName("celebration.wav"))
        } else {
            // User dropped DOWN
            content.title = "📉 You dropped to #\(newRank) on the leaderboard!"
            if let competitor = competitorName {
                content.body = "\(competitor) just passed you • Buy 2X Points Boost to catch up!"
            } else {
                content.body = "Buy 2X Points Boost to climb back up!"
            }
            content.sound = UNNotificationSound(named: UNNotificationSoundName("sad_trombone.wav"))
            content.interruptionLevel = .timeSensitive
        }
        
        content.userInfo = [
            "type": "rank_change",
            "oldRank": oldRank,
            "newRank": newRank,
            "deepLink": "ranks"
        ]
        content.badge = 1
        
        let viewAction = UNNotificationAction(identifier: "VIEW_LEADERBOARD", title: "📊 View Ranks", options: [.foreground])
        let boostAction = UNNotificationAction(identifier: "BUY_BOOST", title: "⚡️ Buy Boost ($1.99)", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "RANK_CHANGE",
            actions: [viewAction, boostAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "RANK_CHANGE"
        
        let request = UNNotificationRequest(
            identifier: "rank_change_\(user.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("📊 Rank change notification sent to \(user.username): #\(oldRank) → #\(newRank)")
    }
    
    /// 🔥 Friends Are Active Right Now - FOMO
    func sendFriendsActiveNowNotification(to user: User, activeFriendNames: [String]) async {
        guard isAuthorized, activeFriendNames.count >= 3 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 Your squad is online!"
        content.body = "\(activeFriendNames[0]), \(activeFriendNames[1]), and \(activeFriendNames[2]) are pooping right now!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("gentle_chime.wav"))
        content.userInfo = [
            "type": "friends_active",
            "deepLink": "feed"
        ]
        content.badge = 1
        
        let joinAction = UNNotificationAction(identifier: "JOIN_NOW", title: "🚀 Join the Party", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "FRIENDS_ACTIVE",
            actions: [joinAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "FRIENDS_ACTIVE"
        
        let request = UNNotificationRequest(
            identifier: "friends_active_\(user.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("🔥 Friends active notification sent to \(user.username)")
    }
    
    /// 🚨 You Haven't Pooped Today - Streak Risk
    func sendDailyPoopReminderNotification(to user: User, streakDays: Int) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🚨 Your \(streakDays)-day streak is at risk!"
        content.body = "You haven't pooped today • Log one now to keep your streak alive!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("urgent_reminder.wav"))
        content.userInfo = [
            "type": "daily_reminder",
            "deepLink": "drop"
        ]
        content.badge = 1
        content.interruptionLevel = .timeSensitive
        
        let logAction = UNNotificationAction(identifier: "LOG_POOP_REMINDER", title: "💩 Log Now", options: [.foreground])
        
        let category = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [logAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "DAILY_REMINDER"
        
        // Trigger in 12 hours from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 12 * 60 * 60, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "daily_reminder_\(user.id)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("🚨 Daily poop reminder scheduled for \(user.username)")
    }
    
    // MARK: - Gossip Notifications
    
    /// 🚨 Someone Mentioned You in Gossip
    func sendGossipMentionNotification(gossipText: String, to users: [User]) async {
        guard isAuthorized else { return }
        
        for user in users {
            let content = UNMutableNotificationContent()
            content.title = "🚨 Someone's talking about you!"
            content.body = String(gossipText.prefix(100)) + (gossipText.count > 100 ? "..." : "")
            content.sound = .default
            content.userInfo = [
                "type": "gossip_mention",
                "deepLink": "gossip"
            ]
            content.badge = 1
            content.interruptionLevel = .timeSensitive
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "gossip_mention_\(user.id)_\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            try? await UNUserNotificationCenter.current().add(request)
            print("🚨 Sent gossip mention notification to \(user.username)")
        }
    }
    
    /// 📰 New Gossip Posted
    func sendNewGossipNotification(gossipText: String, to users: [User]) async {
        guard isAuthorized else { return }
        
        // Only notify first 50 friends (don't spam everyone)
        let notifyUsers = users.prefix(50)
        
        for user in notifyUsers {
            let content = UNMutableNotificationContent()
            content.title = "☕ Fresh gossip just dropped!"
            content.body = String(gossipText.prefix(80)) + (gossipText.count > 80 ? "..." : "")
            content.sound = .default
            content.userInfo = [
                "type": "new_gossip",
                "deepLink": "gossip"
            ]
            content.badge = 1
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "new_gossip_\(user.id)_\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
        print("📰 Sent new gossip notification to \(notifyUsers.count) friends")
    }
    
    /// 💬 Someone Replied to Your Gossip
    func sendGossipReplyNotification(originalGossip: String, to user: User) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "💬 Someone replied to your gossip!"
        content.body = "Tap to see what they said"
        content.sound = .default
        content.userInfo = [
            "type": "gossip_reply",
            "deepLink": "gossip"
        ]
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "gossip_reply_\(user.id)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("💬 Sent gossip reply notification to \(user.username)")
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
    
    // MARK: - High-Frequency Engagement Notifications (Viral Features)
    
    /// Morning Digest: Send at 7 AM with overnight gossip count
    func sendMorningGossipDigest(overnightCount: Int, to users: [User]) async {
        guard isAuthorized else { return }
        
        for user in users {
            let content = UNMutableNotificationContent()
            content.title = "☕ Good morning!"
            
            if overnightCount > 0 {
                content.body = "\(overnightCount) new gossip posts overnight. Someone's definitely talking about you..."
                content.sound = .default
                content.badge = NSNumber(value: overnightCount)
                content.userInfo = ["action": "open_gossip"]
                
                let request = UNNotificationRequest(
                    identifier: "morning_digest_\(user.id)_\(Date().timeIntervalSince1970)",
                    content: content,
                    trigger: nil // Send immediately
                )
                
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    print("📬 Sent morning digest to \(user.username)")
                } catch {
                    print("❌ Failed to send morning digest: \(error)")
                }
            }
        }
    }
    
    /// Gossip Expiring: Send 1 hour before expiration
    func sendGossipExpiringNotification(gossip: GossipPost, to users: [User]) async {
        guard isAuthorized else { return }
        
        for user in users {
            // Only send if user is mentioned or hasn't revealed yet
            if gossip.mentionedUserIDs.contains(user.id) {
                let content = UNMutableNotificationContent()
                content.title = "⏰ Gossip expires in 1 hour!"
                
                let preview = String(gossip.text.prefix(50))
                content.body = "Last chance to reveal who said: '\(preview)...'"
                content.sound = .default
                content.userInfo = [
                    "gossipID": gossip.id,
                    "action": "open_gossip"
                ]
                
                let request = UNNotificationRequest(
                    identifier: "expiring_\(gossip.id)_\(user.id)",
                    content: content,
                    trigger: nil
                )
                
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    print("📬 Sent expiring notification to \(user.username)")
                } catch {
                    print("❌ Failed to send expiring notification: \(error)")
                }
            }
        }
    }
    
    /// Social Proof: Multiple people revealed this gossip
    func sendMultipleRevealsNotification(gossip: GossipPost, revealCount: Int, to user: User) async {
        guard isAuthorized else { return }
        
        if revealCount >= 3 {
            let content = UNMutableNotificationContent()
            content.title = "👀 \(revealCount) people revealed this"
            content.body = "You're the only one who doesn't know who posted..."
            content.sound = .default
            content.userInfo = [
                "gossipID": gossip.id,
                "action": "open_gossip"
            ]
            
            let request = UNNotificationRequest(
                identifier: "social_proof_\(gossip.id)_\(user.id)_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("📬 Sent social proof notification to \(user.username)")
            } catch {
                print("❌ Failed to send social proof notification: \(error)")
            }
        }
    }
    
    /// FOMO: Friends are active right now
    func sendFriendsActiveNotification(activeCount: Int, to user: User) async {
        guard isAuthorized else { return }
        
        if activeCount >= 5 {
            let content = UNMutableNotificationContent()
            content.title = "🔥 Your friends are all online"
            content.body = "\(activeCount) friends are checking gossip right now"
            content.sound = .default
            content.userInfo = ["action": "open_gossip"]
            
            let request = UNNotificationRequest(
                identifier: "friends_active_\(user.id)_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("📬 Sent friends active notification to \(user.username)")
            } catch {
                print("❌ Failed to send friends active notification: \(error)")
            }
        }
    }
    
    /// Drop Mentioned in Gossip: Your drop was referenced
    func sendDropMentionedInGossipNotification(gossip: GossipPost, dropOwner: User) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "💬 Your drop was mentioned in gossip!"
        
        let preview = String(gossip.text.prefix(50))
        content.body = "Someone said: '\(preview)...'"
        content.sound = .default
        content.userInfo = [
            "gossipID": gossip.id,
            "action": "open_gossip"
        ]
        
        let request = UNNotificationRequest(
            identifier: "drop_mentioned_\(gossip.id)_\(dropOwner.id)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📬 Sent drop mentioned notification to \(dropOwner.username)")
        } catch {
            print("❌ Failed to send drop mentioned notification: \(error)")
        }
    }
}
