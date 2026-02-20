import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    var body: some View {
        SwiftUI.Group {
            if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }
            } else if !authManager.isAuthenticated {
                AuthenticationView()
            } else if authManager.needsProfileSetup {
                ProfileSetupView {
                    authManager.needsProfileSetup = false
                }
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        .animation(.easeInOut(duration: 0.3), value: authManager.needsProfileSetup)
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
    }
}
