import SwiftUI
import UserNotifications

@main
struct TheDailyPoopApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthenticationManager()

    init() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    requestNotificationPermission()
                }
        }
    }

    private func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            let _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
    }
}
