import Foundation
import CloudKit
import UserNotifications

/// Manages real push notifications via CloudKit Database Subscriptions
@MainActor
class PushNotificationManager: ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published var isRegisteredForPush = false
    private let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
    
    init() {}
    
    // MARK: - Register for Push Notifications
    
    /// Call this after user signs in to register for push notifications
    func registerForPushNotifications() async {
        // Request permission first
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            guard granted else {
                print("⚠️ Push notifications permission denied")
                return
            }
            
            // Register with APNs
            await UIApplication.shared.registerForRemoteNotifications()
            
            // Set up CloudKit subscriptions
            await setupCloudKitSubscriptions()
            
            self.isRegisteredForPush = true
            print("✅ Successfully registered for push notifications")
            
        } catch {
            print("❌ Failed to register for push notifications: \(error)")
        }
    }
    
    // MARK: - CloudKit Database Subscriptions
    
    /// Set up database subscriptions to listen for changes
    private func setupCloudKitSubscriptions() async {
        do {
            // Subscribe to new drops from friends
            try await subscribeToFriendDrops()
            
            // Subscribe to friend requests
            try await subscribeToFriendRequests()
            
            // Subscribe to reactions on your drops
            try await subscribeToReactions()
            
            print("✅ CloudKit subscriptions set up successfully")
            
        } catch {
            print("❌ Failed to set up CloudKit subscriptions: \(error)")
        }
    }
    
    // MARK: - Individual Subscriptions
    
    /// Subscribe to new drops from friends
    private func subscribeToFriendDrops() async throws {
        let subscriptionID = "friend-drops-subscription"
        
        // Check if subscription already exists
        do {
            let existingSubscription = try await container.publicCloudDatabase.subscription(for: subscriptionID)
            print("ℹ️ Friend drops subscription already exists: \(existingSubscription.subscriptionID)")
            return
        } catch {
            // Subscription doesn't exist, create it
        }
        
        // Create predicate for drops (all drops are public, filtering happens client-side)
        let predicate = NSPredicate(value: true)
        
        // Create query subscription
        let subscription = CKQuerySubscription(
            recordType: "Drop",
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation]
        )
        
        // Configure notification info
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "A friend just dropped a poop! 💩"
        notificationInfo.soundName = "fart_short.wav"
        notificationInfo.shouldBadge = true
        notificationInfo.category = "FRIEND_POOP"
        
        subscription.notificationInfo = notificationInfo
        
        // Save subscription
        _ = try await container.publicCloudDatabase.save(subscription)
        print("✅ Subscribed to friend drops")
    }
    
    /// Subscribe to friend requests
    private func subscribeToFriendRequests() async throws {
        guard let currentUserID = CloudKitManager.shared.currentUser?.id else {
            print("⚠️ No current user, skipping friend request subscription")
            return
        }
        
        let subscriptionID = "friend-requests-\(currentUserID)"
        
        // Check if subscription already exists
        do {
            let existingSubscription = try await container.publicCloudDatabase.subscription(for: subscriptionID)
            print("ℹ️ Friend request subscription already exists: \(existingSubscription.subscriptionID)")
            return
        } catch {
            // Subscription doesn't exist, create it
        }
        
        // Create predicate for friend requests to this user
        let predicate = NSPredicate(format: "toUserId == %@", currentUserID)
        
        // Create query subscription
        let subscription = CKQuerySubscription(
            recordType: "Friendship",
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation]
        )
        
        // Configure notification info
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "New friend request! 👥"
        notificationInfo.soundName = "friend_request.wav"
        notificationInfo.shouldBadge = true
        notificationInfo.category = "FRIEND_REQUEST"
        
        subscription.notificationInfo = notificationInfo
        
        // Save subscription
        _ = try await container.publicCloudDatabase.save(subscription)
        print("✅ Subscribed to friend requests")
    }
    
    /// Subscribe to reactions on your drops
    private func subscribeToReactions() async throws {
        guard let currentUserID = CloudKitManager.shared.currentUser?.id else {
            print("⚠️ No current user, skipping reactions subscription")
            return
        }
        
        let subscriptionID = "reactions-\(currentUserID)"
        
        // Check if subscription already exists
        do {
            let existingSubscription = try await container.publicCloudDatabase.subscription(for: subscriptionID)
            print("ℹ️ Reactions subscription already exists: \(existingSubscription.subscriptionID)")
            return
        } catch {
            // Subscription doesn't exist, create it
        }
        
        // Create predicate for reactions (reactions are stored in Drop record as a map)
        // We'll rely on CloudKit silent notifications and filter client-side
        let predicate = NSPredicate(format: "userID == %@", currentUserID)
        
        // Create query subscription
        let subscription = CKQuerySubscription(
            recordType: "Drop",
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordUpdate]
        )
        
        // Configure notification info
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "Someone reacted to your drop!"
        notificationInfo.soundName = "gentle_chime.wav"
        notificationInfo.shouldBadge = true
        notificationInfo.category = "DROP_REACTION"
        
        subscription.notificationInfo = notificationInfo
        
        // Save subscription
        _ = try await container.publicCloudDatabase.save(subscription)
        print("✅ Subscribed to reactions on your drops")
    }
    
    // MARK: - Unsubscribe (on sign out)
    
    func unsubscribeFromPushNotifications() async {
        do {
            // Fetch all subscriptions
            let allSubscriptions = try await container.publicCloudDatabase.allSubscriptions()
            
            // Delete each subscription
            for subscription in allSubscriptions {
                _ = try await container.publicCloudDatabase.deleteSubscription(withID: subscription.subscriptionID)
                print("🗑️ Deleted subscription: \(subscription.subscriptionID)")
            }
            
            self.isRegisteredForPush = false
            print("✅ Unsubscribed from all push notifications")
            
        } catch {
            print("❌ Failed to unsubscribe: \(error)")
        }
    }
    
    // MARK: - Handle Incoming Push Notifications
    
    /// Call this from AppDelegate when receiving remote notifications
    func handleRemoteNotification(userInfo: [AnyHashable: Any]) async {
        print("📬 Handling remote notification: \(userInfo)")
        
        // Parse CloudKit notification
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            
            if let queryNotification = notification as? CKQueryNotification {
                let recordID = queryNotification.recordID
                let recordType = queryNotification.recordType
                
                print("📬 CloudKit query notification for \(recordType ?? "unknown"): \(recordID?.recordName ?? "unknown")")
                
                // Fetch the actual record to get details
                if let recordID = recordID {
                    await fetchAndShowNotification(recordType: recordType, recordID: recordID)
                }
            }
        }
    }
    
    /// Fetch record details and show rich notification
    private func fetchAndShowNotification(recordType: String?, recordID: CKRecord.ID) async {
        guard let recordType = recordType else { return }
        
        do {
            let record = try await container.publicCloudDatabase.record(for: recordID)
            
            switch recordType {
            case "Drop":
                await showDropNotification(record: record)
                
            case "Friendship":
                await showFriendRequestNotification(record: record)
                
            default:
                print("⚠️ Unknown record type: \(recordType)")
            }
            
        } catch {
            print("❌ Failed to fetch record: \(error)")
        }
    }
    
    /// Show notification for a new drop
    private func showDropNotification(record: CKRecord) async {
        let username = record["username"] as? String ?? "Someone"
        let city = record["city"] as? String ?? "somewhere"
        let isNoPoop = record["isNoPoop"] as? Bool ?? false
        let dropID = record.recordID.recordName
        let userID = record["userID"] as? String ?? ""
        
        // Check if this drop is from a friend (client-side filtering)
        let isFriend = await CloudKitManager.shared.isFriend(userID: userID)
        
        guard isFriend else {
            print("ℹ️ Drop from non-friend, not showing notification")
            return
        }
        
        let content = UNMutableNotificationContent()
        
        if isNoPoop {
            content.title = "Constipation Update! 😵‍💫"
            content.body = "\(username) is backed up in \(city)!"
            content.sound = UNNotificationSound(named: UNNotificationSoundName("sad_trombone.wav"))
        } else {
            content.title = "Fresh Drop Alert! 💩"
            content.body = "\(username) just dropped a poop in \(city)!"
            content.sound = UNNotificationSound(named: UNNotificationSoundName(getRandomPoopSound()))
        }
        
        content.userInfo = [
            "type": "friend_pooped",
            "friendId": userID,
            "dropId": dropID,
            "city": city
        ]
        content.badge = 1
        content.categoryIdentifier = "FRIEND_POOP"
        
        let request = UNNotificationRequest(
            identifier: "drop_\(dropID)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("✅ Showed drop notification from \(username)")
    }
    
    /// Show notification for a friend request
    private func showFriendRequestNotification(record: CKRecord) async {
        let fromUsername = record["fromUsername"] as? String ?? "Someone"
        let fromUserID = record["fromUserId"] as? String ?? ""
        
        let content = UNMutableNotificationContent()
        content.title = "New Friend Request! 👥"
        content.body = "\(fromUsername) wants to be your poop buddy!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("friend_request.wav"))
        content.userInfo = [
            "type": "friend_request",
            "senderId": fromUserID,
            "senderUsername": fromUsername
        ]
        content.badge = 1
        content.categoryIdentifier = "FRIEND_REQUEST"
        
        let request = UNNotificationRequest(
            identifier: "friend_request_\(fromUserID)",
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
        print("✅ Showed friend request notification from \(fromUsername)")
    }
    
    // MARK: - Helper Methods
    
    private func getRandomPoopSound() -> String {
        let poopSounds = [
            "fart_short.wav",
            "fart_long.wav",
            "bubble_fart.wav",
            "plop_single.wav",
            "big_splash.wav"
        ]
        return poopSounds.randomElement() ?? "fart_short.wav"
    }
}

