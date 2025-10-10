import UIKit
import UserNotifications
import CloudKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register for remote notifications
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // Called when APNs successfully registers the device
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📱 Device Token: \(token)")
        
        // Store the token if needed for direct push notifications
        UserDefaults.standard.set(token, forKey: "deviceToken")
    }
    
    // Called if registration fails
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    // Handle received remote notifications
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📬 Received remote notification: \(userInfo)")
        
        // Handle CloudKit notification
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            print("📬 CloudKit notification type: \(notification.notificationType.rawValue)")
            
            // Refresh data based on notification
            Task {
                do {
                    _ = try await CloudKitManager.shared.fetchDrops(limit: 100)
                    completionHandler(.newData)
                } catch {
                    completionHandler(.failed)
                }
            }
        } else {
            completionHandler(.noData)
        }
    }
    
    // MARK: - Universal Links
    
    /// Handle Universal Links (e.g., https://thedailypoop.app/fart/[attackID])
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL else {
            return false
        }
        
        print("💨 Received Universal Link: \(incomingURL.absoluteString)")
        
        // Parse fart attack URL: https://thedailypoop.app/fart/[attackID]
        if incomingURL.pathComponents.count >= 3,
           incomingURL.pathComponents[1] == "fart" {
            let attackID = incomingURL.pathComponents[2]
            
            print("💨 Processing fart attack: \(attackID)")
            
            // Post notification to handle fart attack
            NotificationCenter.default.post(
                name: Notification.Name("OPEN_FART_ATTACK"),
                object: nil,
                userInfo: ["attackID": attackID]
            )
            
            return true
        }
        
        return false
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Called when notification is received while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📬 Notification received in foreground: \(notification.request.content.title)")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Called when user taps on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("📬 User tapped notification: \(userInfo)")
        
        // Handle notification actions
        let type = userInfo["type"] as? String ?? ""
        
        switch type {
        case "friend_pooped":
            if let dropId = userInfo["dropId"] as? String {
                print("📍 Opening drop: \(dropId)")
                // Post notification to open drop detail
                NotificationCenter.default.post(name: Notification.Name("OPEN_DROP_DETAIL"), object: nil, userInfo: ["dropId": dropId])
            }
            
        case "reaction":
            if let dropId = userInfo["dropId"] as? String {
                print("📍 Opening drop: \(dropId)")
                NotificationCenter.default.post(name: Notification.Name("OPEN_DROP_DETAIL"), object: nil, userInfo: ["dropId": dropId])
            }
            
        case "friend_request":
            print("📍 Opening friends tab")
            NotificationCenter.default.post(name: Notification.Name("OPEN_FRIENDS_TAB"), object: nil)
            
        case "daily_streak_reminder":
            print("📍 Opening drop composer")
            NotificationCenter.default.post(name: Notification.Name("OPEN_DROP_COMPOSER"), object: nil)
            
        default:
            print("📍 Unknown notification type: \(type)")
        }
        
        completionHandler()
    }
}
