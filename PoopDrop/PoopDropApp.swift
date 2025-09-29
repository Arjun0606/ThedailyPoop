import SwiftUI
import CloudKit
import UserNotifications
// import GoogleMobileAds // TODO: Add as Swift Package when ready

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
        // If GoogleMobileAds is added via SPM, uncomment the import at the top and this line:
        // GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // Setup notification handler
        notificationHandler.setup()
        notificationHandler.setupDeleteAccountListener()
        
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