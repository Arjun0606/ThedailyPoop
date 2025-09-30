import SwiftUI
import CoreLocation

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedTab = 0
    @State private var showingDropComposer = false
    @State private var pendingCenterCoordinate: CLLocationCoordinate2D? = nil
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Feed Tab (Friends only)
                FeedView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Feed")
                    }
                    .tag(0)
                
                // Friends Tab
                FriendsView()
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
                
                // Map Tab
                SnapchatStyleMapView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "map.fill" : "map")
                        Text("Map")
                    }
                    .tag(3)
                
                // Profile Tab
                ProfileView()
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                        Text("Profile")
                    }
                    .tag(4)
            }
            .accentColor(.white)
            .onAppear {
                // Configure tab bar appearance for dark mode
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.black
                appearance.selectionIndicatorTintColor = UIColor.white
                
                // Normal state
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                    .foregroundColor: UIColor.gray
                ]
                
                // Selected state
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                    .foregroundColor: UIColor.white
                ]
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SWITCH_TO_MAP_TAB"))) { _ in
                selectedTab = 3 // Switch to Map tab
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("DID_CREATE_DROP"))) { notification in
                print("📱 MainTabView received DID_CREATE_DROP notification")
                if let drop = notification.userInfo?["drop"] as? Drop, let coord = drop.location {
                    print("📍 Switching to Map tab and centering on: \(coord)")
                    // Switch to Map tab and remember coordinate
                    pendingCenterCoordinate = coord
                    selectedTab = 3
                    // Forward full drop to map on next runloop so the view is ready
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("CENTER_MAP"), object: nil, userInfo: ["coordinate": coord, "drop": drop])
                    }
                } else {
                    print("⚠️ Drop or location missing from notification")
                }
            }
            
            // Floating Action Button for Drop
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingDropComposer = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.brown, Color.brown.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Text("💩")
                                .font(.system(size: 32))
                                .scaleEffect(showingDropComposer ? 0.8 : 1.0)
                                .animation(.bouncy(duration: 0.3), value: showingDropComposer)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90) // Above tab bar
                }
            }
        }
        .sheet(isPresented: $showingDropComposer) {
            DropComposerView()
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == 2 {
                // Reset to previous tab and show composer
                selectedTab = 0
                showingDropComposer = true
            } else if newTab == 3 {
                // Only refresh map if we don't have a pending coordinate (fresh drop)
                if pendingCenterCoordinate == nil {
                    print("🗺️ Switching to Map tab, posting REFRESH_MAP")
                    NotificationCenter.default.post(name: Notification.Name("REFRESH_MAP"), object: nil)
                } else {
                    print("🗺️ Switching to Map tab, but have pending coordinate - skipping refresh")
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(CloudKitManager())
        .environmentObject(LocationManager())
}
