import SwiftUI
import MapKit
import CoreLocation

/// Demo Mode View - Uses REAL app views with pre-loaded demo data
/// This ensures Apple reviewers see the EXACT same UI as real users
struct DemoModeView: View {
    @EnvironmentObject var demoManager: DemoModeManager
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var locationManager: LocationManager
    @State private var selectedTab = 0
    @State private var showingDropComposer = false
    
    init() {
        // Initialize with demo location manager (SF location)
        let demoLoc = LocationManager()
        _locationManager = StateObject(wrappedValue: demoLoc)
    }
    
    var body: some View {
        ZStack {
            // Use the REAL MainTabView with demo data injected
            TabView(selection: $selectedTab) {
                // Feed Tab - REAL FeedView
                FeedView()
                    .environmentObject(authManager)
                    .environmentObject(cloudKitManager)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Feed")
                    }
                    .tag(0)
                
                // Friends Tab - REAL FriendsView
                FriendsView()
                    .environmentObject(authManager)
                    .environmentObject(cloudKitManager)
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "person.2.fill" : "person.2")
                        Text("Friends")
                    }
                    .tag(1)
                
                // Placeholder for center FAB
                Color.clear
                    .tabItem {
                        Image(systemName: "plus")
                        Text("Drop")
                    }
                    .tag(2)
                
                // Map Tab - REAL SnapchatStyleMapView
                SnapchatStyleMapView()
                    .environmentObject(authManager)
                    .environmentObject(cloudKitManager)
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "map.fill" : "map")
                        Text("Map")
                    }
                    .tag(3)
                
                // Profile Tab - REAL ProfileView
                ProfileView()
                    .environmentObject(authManager)
                    .environmentObject(cloudKitManager)
                    .environmentObject(subscriptionManager)
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                        Text("Profile")
                    }
                    .tag(4)
            }
            .accentColor(.white)
            .onAppear {
                // Set up demo data
                setupDemoMode()
                
                // Configure tab bar appearance for dark mode
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.black
                appearance.selectionIndicatorTintColor = UIColor.white
                
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: UIColor.gray
                ]
                
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: UIColor.white
                ]
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            .onChange(of: selectedTab) { _, newTab in
                if newTab == 2 {
                    showingDropComposer = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedTab = 0
                    }
                }
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingDropComposer = true
                    }) {
                        Text("💩")
                            .font(.system(size: 40))
                            .frame(width: 70, height: 70)
                            .background(
                                LinearGradient(
                                    colors: [Color.brown, Color.brown.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    Spacer()
                }
                .padding(.bottom, 80)
            }
            
            // Demo Mode Banner at BOTTOM (not blocking top)
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                    Text("DEMO MODE - San Francisco")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        demoManager.exitDemoMode()
                    }) {
                        Text("Exit")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.85))
                .padding(.bottom, 96) // Above tab bar
            }
        }
        .sheet(isPresented: $showingDropComposer) {
            // Use REAL DropComposerView with demo environment
            DropComposerView()
                .environmentObject(authManager)
                .environmentObject(cloudKitManager)
                .environmentObject(locationManager)
        }
    }
    
    private func setupDemoMode() {
        // Set demo user in auth manager
        authManager.currentUser = DemoModeManager.shared.demoUser
        authManager.isAuthenticated = true
        
        // Pre-load demo drops into CloudKit manager
        cloudKitManager.drops = DemoModeManager.shared.demoDrops
        
        // Force multiple refreshes to ensure data loads
        Task {
            // Immediate set
            await MainActor.run {
                cloudKitManager.drops = DemoModeManager.shared.demoDrops
            }
            
            // Wait and set again (for views that load on appear)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                cloudKitManager.drops = DemoModeManager.shared.demoDrops
                // Post notification to force refresh
                NotificationCenter.default.post(name: Notification.Name("REFRESH_MAP"), object: nil)
            }
            
            // One more time after 1 second
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                cloudKitManager.drops = DemoModeManager.shared.demoDrops
            }
        }
    }
}
