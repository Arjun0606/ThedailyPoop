import SwiftUI
import CloudKit
import UserNotifications
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@main
struct PoopDropApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var locationManager = LocationManager()
    private let notificationHandler = NotificationHandler()
    
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
        GADMobileAds.sharedInstance().start(completionHandler: nil)
#endif
        
        // Setup notification handler
        notificationHandler.setup()
        
        // Initialize CloudKit container
        cloudKitManager.initialize()
        
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