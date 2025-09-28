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
        content.body = "\(sender.displayName) wants to be your poop buddy!"
        content.sound = UNNotificationSound.default
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
        content.body = "\(accepter.displayName) is now your poop buddy!"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: "friend_accepted_\(accepter.id)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Poop Drop Notifications (with sounds!)
    
    func sendPoopDropNotification(to friends: [User], from dropper: User, drop: Drop) async {
        for friend in friends {
            let content = UNMutableNotificationContent()
            
            if drop.isNoPoop {
                content.title = "No Poop Alert! 😵‍💫"
                content.body = "\(dropper.displayName) had no poop today but kept their streak alive!"
                content.sound = UNNotificationSound(named: UNNotificationSoundName("constipated.wav"))
            } else {
                content.title = "Fresh Drop Alert! 💩"
                content.body = "\(dropper.displayName) just dropped a poop!"
                
                // Random fart/flush sound for Pro users
                if friend.isPro {
                    let sounds = ["fart1.wav", "fart2.wav", "flush1.wav", "flush2.wav", "plop.wav"]
                    let randomSound = sounds.randomElement() ?? "fart1.wav"
                    content.sound = UNNotificationSound(named: UNNotificationSoundName(randomSound))
                } else {
                    content.sound = UNNotificationSound(named: UNNotificationSoundName("basic_poop.wav"))
                }
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
        playPoopSound(isPro: dropper.isPro, isNoPoop: drop.isNoPoop)
    }
    
    // MARK: - Reminder Notifications
    
    func schedulePoopReminder(for user: User) async {
        // Cancel existing reminder
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["poop_reminder_\(user.id)"]
        )
        
        let content = UNMutableNotificationContent()
        content.title = "Poop Check! 💩"
        content.body = "Haven't pooped in 12 hours? Add a 'No Poop' entry to keep your streak alive! 🔥"
        content.sound = UNNotificationSound.default
        content.userInfo = [
            "type": "poop_reminder",
            "userId": user.id
        ]
        
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
    
    // MARK: - Sound Effects
    
    private func playPoopSound(isPro: Bool, isNoPoop: Bool) {
        let soundName: String
        
        if isNoPoop {
            soundName = "constipated"
        } else if isPro {
            let proSounds = ["fart_pro", "flush_pro", "plop_pro", "splash_pro"]
            soundName = proSounds.randomElement() ?? "fart_pro"
        } else {
            soundName = "basic_poop"
        }
        
        guard let path = Bundle.main.path(forResource: soundName, ofType: "wav") else {
            print("Sound file not found: \(soundName).wav")
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
