import SwiftUI
import CoreLocation

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var fartAttackManager = FartAttackManager.shared
    @State private var selectedTab = 0
    @State private var showingDropComposer = false
    @State private var pendingCenterCoordinate: CLLocationCoordinate2D? = nil
    @State private var showingFartAttackOnboarding = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                FeedView()
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Feed")
                    }
                    .tag(0)

                GossipFeedView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                        Text("Gossip")
                    }
                    .tag(1)

                SnapchatStyleMapView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "map.fill" : "map")
                        Text("Map")
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
                appearance.selectionIndicatorTintColor = UIColor.white
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            // Cross-tab navigation
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SWITCH_TO_MAP_TAB"))) { _ in
                selectedTab = 2
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SWITCH_TO_FRIENDS_TAB"))) { _ in
                selectedTab = 0
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SWITCH_TO_ATTACKS_TAB"))) { _ in
                selectedTab = 0
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("DID_CREATE_DROP"))) { notification in
                if let drop = notification.userInfo?["drop"] as? Drop, let coord = drop.location {
                    pendingCenterCoordinate = coord
                    selectedTab = 2
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("CENTER_MAP"), object: nil, userInfo: ["coordinate": coord, "drop": drop])
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SHOW_DROP_FROM_GOSSIP"))) { notification in
                if let userInfo = notification.userInfo, let username = userInfo["username"] as? String {
                    selectedTab = 2
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(name: Notification.Name("CENTER_MAP_ON_USER"), object: nil, userInfo: ["username": username])
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SHOW_GOSSIP_FOR_DROP"))) { _ in
                selectedTab = 1
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SWITCH_TO_GOSSIP_TAB"))) { _ in
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
                                .fill(LinearGradient(colors: [Color.brown, Color.brown.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
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
        .onChange(of: selectedTab) { newTab in
            if newTab == 2 {
                NotificationCenter.default.post(name: Notification.Name("REFRESH_MAP"), object: nil)
                pendingCenterCoordinate = nil
            }
        }
        .onAppear {
            if let currentUser = authManager.currentUser {
                Task {
                    await fartAttackManager.loadInventory(for: currentUser)
                    let userKey = "hasReceivedFreeGhostAttack_\(currentUser.id)"
                    let hasReceivedBefore = UserDefaults.standard.bool(forKey: userKey)
                    if !hasReceivedBefore {
                        UserDefaults.standard.set(true, forKey: userKey)
                        UserDefaults.standard.synchronize()
                        await fartAttackManager.addAttacksFromPurchase(for: currentUser, count: 1)
                    }
                    await fartAttackManager.checkPendingAttacks(for: currentUser)
                    let onboardingKey = "hasSeenFartAttackOnboarding_\(currentUser.id)"
                    await MainActor.run {
                        if !UserDefaults.standard.bool(forKey: onboardingKey) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showingFartAttackOnboarding = true
                            }
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $fartAttackManager.showingAttackOverlay) {
            if let attack = fartAttackManager.currentAttack {
                FartAttackReceivedView(attack: attack) {
                    fartAttackManager.dismissCurrentAttack()
                }
            }
        }
        .sheet(isPresented: $showingFartAttackOnboarding) {
            FartAttackOnboardingView {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { selectedTab = 1 }
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
        .environmentObject(CloudKitManager())
        .environmentObject(LocationManager())
}
