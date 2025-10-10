import SwiftUI
import CloudKit
import UserNotifications

@main
struct TheDailyPoopApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var fartAttackManager = FartAttackManager.shared
    @StateObject private var friendsManager = FriendsManager()
    private let notificationHandler = NotificationHandler()
    
    init() {
        // Register for remote notifications on app launch
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(subscriptionManager)
                .environmentObject(cloudKitManager)
                .environmentObject(locationManager)
                .environmentObject(fartAttackManager)
                .environmentObject(friendsManager)
                .preferredColorScheme(.dark) // Dark-mode first
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Setup notification handler
        notificationHandler.setup()
        
        // Initialize CloudKit container
        cloudKitManager.initialize()
        
        // Load existing drops on app start
        Task {
            do {
                _ = try await cloudKitManager.fetchDrops(limit: 100)
                print("📱 Loaded drops on app start")
            } catch {
                print("❌ Failed to load drops on app start: \(error)")
            }
        }
        
        // Check subscription status
        Task {
            await subscriptionManager.checkSubscriptionStatus()
        }
        
        // Request location permission
        locationManager.requestLocationPermission()
        
        // Request notification permission
        Task {
            await NotificationManager.shared.requestPermission()
        }
    }
}