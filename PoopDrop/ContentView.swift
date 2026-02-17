import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var showProfileSetup = false

    var body: some View {
        SwiftUI.Group {
            if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }
            } else if !authManager.isAuthenticated {
                AuthenticationView()
            } else if showProfileSetup {
                ProfileSetupView {
                    showProfileSetup = false
                }
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        .animation(.easeInOut(duration: 0.3), value: showProfileSetup)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated, let user = authManager.currentUser {
                showProfileSetup = user.username.isEmpty
            }
        }
    }
}
