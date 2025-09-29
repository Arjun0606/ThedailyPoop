import SwiftUI

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
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("DID_CREATE_DROP"))) { notification in
                if let drop = notification.userInfo?["drop"] as? Drop, let coord = drop.location {
                    // Switch to Map tab and remember coordinate
                    pendingCenterCoordinate = coord
                    selectedTab = 3
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
            }
            if newTab == 3, let coord = pendingCenterCoordinate {
                // Notify map view to center on coordinate
                NotificationCenter.default.post(name: Notification.Name("CENTER_MAP"), object: nil, userInfo: ["coordinate": coord])
                pendingCenterCoordinate = nil
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
