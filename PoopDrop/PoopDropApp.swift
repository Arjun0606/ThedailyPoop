import SwiftUI
import UserNotifications

@main
struct TheDailyPoopApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var locationManager = LocationManager()

    init() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(locationManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    locationManager.requestLocationPermission()
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
