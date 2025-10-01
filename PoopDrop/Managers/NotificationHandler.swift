import Foundation
import UserNotifications
import UIKit

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHandler()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func setup() {
        // Setup notification categories and actions
        setupNotificationCategories()
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        // Handle different notification types and actions
        Task {
            await handleNotificationResponse(actionIdentifier: actionIdentifier, userInfo: userInfo)
            completionHandler()
        }
    }
    
    private func handleNotificationResponse(actionIdentifier: String, userInfo: [AnyHashable: Any]) async {
        guard let notificationType = userInfo["type"] as? String else { return }
        
        switch actionIdentifier {
        // Default tap - open app to relevant screen
        case UNNotificationDefaultActionIdentifier:
            await handleDefaultNotificationTap(type: notificationType, userInfo: userInfo)
            
        // Friend poop notifications
        case "VIEW_DROP":
            if let dropId = userInfo["dropId"] as? String {
                await openDropDetail(dropId: dropId)
            }
            
        case "QUICK_REACT":
            if let dropId = userInfo["dropId"] as? String {
                await quickReactToDrop(dropId: dropId)
            }
            
        case "WHERE":
            if let dropId = userInfo["dropId"] as? String {
                await openMapToLocation(dropId: dropId)
            }
            
        // Friend request notifications
        case "ACCEPT_FRIEND":
            if let senderId = userInfo["senderId"] as? String {
                await acceptFriendRequest(senderId: senderId)
            }
            
        case "DECLINE_FRIEND":
            if let senderId = userInfo["senderId"] as? String {
                await declineFriendRequest(senderId: senderId)
            }
            
        case "VIEW_PROFILE":
            if let senderId = userInfo["senderId"] as? String {
                await openUserProfile(userId: senderId)
            }
            
        // Streak reminder notifications
        case "LOG_POOP":
            await openDropComposer()
            
        case "NO_POOP":
            await logNoPoopEntry()
            
        // Reaction notifications
        case "VIEW_REACTION":
            if let dropId = userInfo["dropId"] as? String {
                await openDropDetail(dropId: dropId)
            }
            
        case "REACT_BACK":
            if let dropId = userInfo["dropId"] as? String {
                await quickReactBackToDrop(dropId: dropId)
            }
            
        // Support actions
        case "SEND_SUPPORT":
            if let friendId = userInfo["friendId"] as? String {
                await sendSupportMessage(to: friendId)
            }
            
        default:
            print("Unhandled notification action: \(actionIdentifier)")
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleDefaultNotificationTap(type: String, userInfo: [AnyHashable: Any]) async {
        switch type {
        case "friend_pooped":
            if let dropId = userInfo["dropId"] as? String {
                await openDropDetail(dropId: dropId)
            }
            
        case "friend_request":
            await openFriendsTab()
            
        case "friend_accepted":
            if let friendId = userInfo["friendId"] as? String {
                await openUserProfile(userId: friendId)
            }
            
        case "drop_reaction":
            if let dropId = userInfo["dropId"] as? String {
                await openDropDetail(dropId: dropId)
            }
            
        case "poop_reminder":
            await openDropComposer()
            
        case "streak_broken":
            if let friendId = userInfo["friendId"] as? String {
                await openUserProfile(userId: friendId)
            }
            
        default:
            await openMainApp()
        }
    }
    
    private func openDropDetail(dropId: String) async {
        await MainActor.run {
            // Navigate to specific drop detail
            NotificationCenter.default.post(name: .openDropDetail, object: dropId)
        }
    }
    
    private func quickReactToDrop(dropId: String) async {
        // Add a quick 😂 reaction
        await MainActor.run {
            NotificationCenter.default.post(name: .quickReactToDrop, object: ["dropId": dropId, "emoji": "😂"])
        }
    }
    
    private func openMapToLocation(dropId: String) async {
        await MainActor.run {
            NotificationCenter.default.post(name: .openMapToLocation, object: dropId)
        }
    }
    
    private func acceptFriendRequest(senderId: String) async {
        await MainActor.run {
            NotificationCenter.default.post(name: .acceptFriendRequest, object: senderId)
        }
    }
    
    private func declineFriendRequest(senderId: String) async {
        await MainActor.run {
            NotificationCenter.default.post(name: .declineFriendRequest, object: senderId)
        }
    }
    
    private func openUserProfile(userId: String) async {
        await MainActor.run {
            NotificationCenter.default.post(name: .openUserProfile, object: userId)
        }
    }
    
    private func openDropComposer() async {
        await MainActor.run {
            NotificationCenter.default.post(name: .openDropComposer, object: nil)
        }
    }
    
    private func logNoPoopEntry() async {
        await MainActor.run {
            NotificationCenter.default.post(name: .logNoPoopEntry, object: nil)
        }
    }
    
    private func quickReactBackToDrop(dropId: String) async {
        // Add a quick reaction back (like a thumbs up)
        await MainActor.run {
            NotificationCenter.default.post(name: .quickReactToDrop, object: ["dropId": dropId, "emoji": "👍"])
        }
    }
    
    private func sendSupportMessage(to friendId: String) async {
        await MainActor.run {
            NotificationCenter.default.post(name: .sendSupportMessage, object: friendId)
        }
    }
    
    private func openFriendsTab() async {
        await MainActor.run {
            NotificationCenter.default.post(name: .openFriendsTab, object: nil)
        }
    }
    
    private func openMainApp() async {
        await MainActor.run {
            NotificationCenter.default.post(name: .openMainApp, object: nil)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let openDropDetail = Notification.Name("openDropDetail")
    static let quickReactToDrop = Notification.Name("quickReactToDrop")
    static let openMapToLocation = Notification.Name("openMapToLocation")
    static let acceptFriendRequest = Notification.Name("acceptFriendRequest")
    static let declineFriendRequest = Notification.Name("declineFriendRequest")
    static let openUserProfile = Notification.Name("openUserProfile")
    static let openDropComposer = Notification.Name("openDropComposer")
    static let logNoPoopEntry = Notification.Name("logNoPoopEntry")
    static let sendSupportMessage = Notification.Name("sendSupportMessage")
    static let openFriendsTab = Notification.Name("openFriendsTab")
    static let openMainApp = Notification.Name("openMainApp")
}

// MARK: - Setup Methods Extension
extension NotificationHandler {
    func setupNotificationCategories() {
        // Set up notification categories with actions
        let center = UNUserNotificationCenter.current()
        
        // TheDailyPoop Actions
        let viewDropAction = UNNotificationAction(identifier: "VIEW_DROP", title: "View Drop 👁️", options: [.foreground])
        let reactAction = UNNotificationAction(identifier: "QUICK_REACT", title: "React 😂", options: [])
        let mapAction = UNNotificationAction(identifier: "OPEN_MAP", title: "Where? 🗺️", options: [.foreground])
        
        let poopDropCategory = UNNotificationCategory(
            identifier: "POOP_DROP",
            actions: [viewDropAction, reactAction, mapAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Friend Request Actions  
        let acceptAction = UNNotificationAction(identifier: "ACCEPT_FRIEND", title: "Accept 👥", options: [.foreground])
        let declineAction = UNNotificationAction(identifier: "DECLINE_FRIEND", title: "Decline ❌", options: [])
        
        let friendRequestCategory = UNNotificationCategory(
            identifier: "FRIEND_REQUEST",
            actions: [acceptAction, declineAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Streak Reminder Actions
        let logPoopAction = UNNotificationAction(identifier: "LOG_POOP", title: "Log Poop 💩", options: [.foreground])
        let noPoopAction = UNNotificationAction(identifier: "NO_POOP_TODAY", title: "No Poop Today 😵‍💫", options: [])
        
        let streakReminderCategory = UNNotificationCategory(
            identifier: "STREAK_REMINDER", 
            actions: [logPoopAction, noPoopAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        center.setNotificationCategories([poopDropCategory, friendRequestCategory, streakReminderCategory])
    }
    
    // Delete account logic handled inside SettingsView via CloudKitManager, no global observer to avoid accidental triggers
}
