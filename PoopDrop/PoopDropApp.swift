import SwiftUI
import UserNotifications

@main
struct TheDailyPoopApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    init() {
        SubscriptionManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(subscriptionManager)
                .preferredColorScheme(.dark)
                .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                    if isAuthenticated {
                        requestNotificationPermission()
                        // Login to RevenueCat and sync premium status
                        Task {
                            if let user = authManager.currentUser {
                                await subscriptionManager.login(userID: user.id)
                                authManager.currentUser?.isPremium = subscriptionManager.isPremium
                            }
                        }
                    }
                }
                // Keep premium status in sync when RevenueCat updates
                .onChange(of: subscriptionManager.isPremium) { _, isPremium in
                    authManager.currentUser?.isPremium = isPremium
                    if var user = authManager.currentUser {
                        user.isPremium = isPremium
                        Task {
                            try? await SupabaseManager.shared.saveUser(user)
                        }
                    }
                }
        }
    }

    private func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted == true {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}
