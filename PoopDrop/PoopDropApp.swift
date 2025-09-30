import SwiftUI
import CloudKit
import UserNotifications
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@main
struct PlopApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var locationManager = LocationManager()
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
                .preferredColorScheme(.dark) // Dark-mode first
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Initialize Google Mobile Ads if SDK is linked
#if canImport(GoogleMobileAds)
        MobileAds.shared.start(completionHandler: nil)
        
        // ALWAYS use test mode until AdMob approves the app
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [
            "Simulator"
        ]
        
        #if DEBUG
        print("[AdMob] SDK initialized (TEST mode - will show sample ads)")
        #else
        print("[AdMob] SDK initialized (TEST mode - waiting for AdMob approval)")
        #endif
#endif
        
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