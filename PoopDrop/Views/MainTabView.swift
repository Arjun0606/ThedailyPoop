import SwiftUI
import CoreLocation

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    @State private var showingDropComposer = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                GlobeMapView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "globe.americas.fill" : "globe.americas")
                        Text("Map")
                    }
                    .tag(0)

                GossipFeedView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "eye.fill" : "eye")
                        Text("Gossip")
                    }
                    .tag(1)

                GroupsView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "person.3.fill" : "person.3")
                        Text("Groups")
                    }
                    .tag(2)

                ProfileView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                        Text("Profile")
                    }
                    .tag(3)
            }
            .accentColor(.white)
            .onAppear {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.black
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            // Cross-tab navigation
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SWITCH_TO_MAP_TAB"))) { _ in
                selectedTab = 0
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SWITCH_TO_GOSSIP_TAB"))) { _ in
                selectedTab = 1
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("DID_CREATE_DROP"))) { notification in
                if let drop = notification.userInfo?["drop"] as? Drop, let coord = drop.location {
                    selectedTab = 0
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: Notification.Name("CENTER_MAP"),
                            object: nil,
                            userInfo: ["coordinate": coord, "drop": drop]
                        )
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SHOW_DROP_FROM_GOSSIP"))) { notification in
                if let username = notification.userInfo?["username"] as? String {
                    selectedTab = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(
                            name: Notification.Name("CENTER_MAP_ON_USER"),
                            object: nil,
                            userInfo: ["username": username]
                        )
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SHOW_GOSSIP_FOR_DROP"))) { _ in
                selectedTab = 1
            }

            // Floating Action Button for Drop
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingDropComposer = true }) {
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
                    .padding(.bottom, 90)
                }
            }
        }
        .sheet(isPresented: $showingDropComposer) {
            DropComposerView()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 0 {
                NotificationCenter.default.post(name: Notification.Name("REFRESH_MAP"), object: nil)
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
        .environmentObject(LocationManager())
}
