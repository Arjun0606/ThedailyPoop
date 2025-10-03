import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var demoManager = DemoModeManager.shared
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var showProfileSetup = false
    
    var body: some View {
        Group {
            if demoManager.isDemoMode {
                // Demo mode - bypass authentication
                DemoModeView()
                    .environmentObject(demoManager)
            } else if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }
            } else if showProfileSetup {
                ProfileSetupView {
                    showProfileSetup = false
                }
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: demoManager.isDemoMode)
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        .animation(.easeInOut(duration: 0.3), value: showProfileSetup)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated, let user = authManager.currentUser {
                // Check if user needs to complete profile setup
                showProfileSetup = user.username.isEmpty
            }
        }
    }
}
