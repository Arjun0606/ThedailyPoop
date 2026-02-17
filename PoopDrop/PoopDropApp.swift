import SwiftUI
import CloudKit
import UserNotifications

@main
struct TheDailyPoopApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var fartAttackManager = FartAttackManager.shared
    @StateObject private var friendsManager = FriendsManager()
    private let notificationHandler = NotificationHandler()

    init() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(cloudKitManager)
                .environmentObject(locationManager)
                .environmentObject(fartAttackManager)
                .environmentObject(friendsManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupApp()
                }
        }
    }

    private func setupApp() {
        notificationHandler.setup()
        cloudKitManager.initialize()

        Task {
            do {
                _ = try await cloudKitManager.fetchDrops(limit: 100)
                print("Loaded drops on app start")
            } catch {
                print("Failed to load drops on app start: \(error)")
            }
        }

        locationManager.requestLocationPermission()

        Task {
            await NotificationManager.shared.requestPermission()
        }
    }
}
