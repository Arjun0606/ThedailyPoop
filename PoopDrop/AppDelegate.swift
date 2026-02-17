import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 Device Token: \(token)")
        UserDefaults.standard.set(token, forKey: "deviceToken")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }

    // MARK: - Universal Links (group invite deep links)

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return false }

        // Parse group invite: https://thedailypoop.app/join/[inviteCode]
        if url.pathComponents.count >= 3, url.pathComponents[1] == "join" {
            let inviteCode = url.pathComponents[2]
            NotificationCenter.default.post(
                name: Notification.Name("OPEN_JOIN_GROUP"),
                object: nil,
                userInfo: ["inviteCode": inviteCode]
            )
            return true
        }

        return false
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let type = userInfo["type"] as? String ?? ""

        switch type {
        case "new_drop":
            NotificationCenter.default.post(name: Notification.Name("SWITCH_TO_MAP_TAB"), object: nil)
        case "new_gossip":
            NotificationCenter.default.post(name: Notification.Name("SWITCH_TO_GOSSIP_TAB"), object: nil)
        case "group_invite":
            if let code = userInfo["inviteCode"] as? String {
                NotificationCenter.default.post(
                    name: Notification.Name("OPEN_JOIN_GROUP"),
                    object: nil,
                    userInfo: ["inviteCode": code]
                )
            }
        default:
            break
        }

        completionHandler()
    }
}
