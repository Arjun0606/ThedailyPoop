import SwiftUI
import CloudKit

@main
struct PoopDropApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var locationManager = LocationManager()
    
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
        // Initialize CloudKit container
        cloudKitManager.initialize()
        
        // Check subscription status
        Task {
            await subscriptionManager.checkSubscriptionStatus()
        }
        
        // Request location permission
        locationManager.requestLocationPermission()
    }
}