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
                    setupApp()
                }
        }
    }

    private func setupApp() {
        locationManager.requestLocationPermission()

        Task {
            await NotificationManager.shared.requestPermission()
        }
    }
}
