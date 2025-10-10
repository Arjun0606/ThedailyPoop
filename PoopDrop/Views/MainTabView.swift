import SwiftUI
import CoreLocation

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var fartAttackManager = FartAttackManager.shared
    @State private var selectedTab = 0
    @State private var showingDropComposer = false
    @State private var pendingCenterCoordinate: CLLocationCoordinate2D? = nil
    @State private var showingFartAttackOnboarding = false
    
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
                
                // Activity Tab
                AttackActivityFeedView()
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "bolt.fill" : "bolt")
                        Text("Activity")
                    }
                    .tag(4)

                // Fart Attacks Tab
                ZStack {
                    FartAttackShopView()
                    VStack {
                        Spacer()
                        // Inline low inventory banner on the attacks tab as well
                        HStack { BuyMoreBanner() }
                            .padding(.horizontal)
                            .padding(.bottom, 90)
                    }
                }
                    .tabItem {
                        Image(systemName: selectedTab == 5 ? "burst.fill" : "burst")
                        Text("Attacks")
                    }
                    .tag(5)
                    .badge(fartAttackManager.inventory?.availableAttacks ?? 0)
                
                // Profile Tab
                ProfileView()
                    .tabItem {
                        Image(systemName: selectedTab == 6 ? "person.fill" : "person")
                        Text("Profile")
                    }
                    .tag(6)
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
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SWITCH_TO_FRIENDS_TAB"))) { _ in
                selectedTab = 1 // Switch to Friends tab
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SWITCH_TO_ATTACKS_TAB"))) { _ in
                selectedTab = 5 // Switch to Attacks tab (after adding Activity tab)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OPEN_FART_ATTACK"))) { notification in
                // Handle incoming fart attack from Universal Link
                if let attackID = notification.userInfo?["attackID"] as? String,
                   let currentUser = authManager.currentUser {
                    Task {
                        await fartAttackManager.processExternalAttackLink(attackID: attackID, currentUser: currentUser)
                    }
                }
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
                // Always refresh map when switching to it (to handle app restart scenario)
                print("🗺️ Switching to Map tab, posting REFRESH_MAP")
                NotificationCenter.default.post(name: Notification.Name("REFRESH_MAP"), object: nil)
                // Clear pending coordinate after use
                pendingCenterCoordinate = nil
            }
        }
        .onAppear {
            // Load inventory and check for pending fart attacks on app launch
            if let currentUser = authManager.currentUser {
                Task {
                    await fartAttackManager.loadInventory(for: currentUser)
                    await fartAttackManager.checkPendingAttacks(for: currentUser)
                    
                    // Give 1 FREE attack on first launch
                    if !UserDefaults.standard.bool(forKey: "hasReceivedFreeFartAttack") {
                        await fartAttackManager.addAttacksFromPurchase(for: currentUser, count: 1)
                        UserDefaults.standard.set(true, forKey: "hasReceivedFreeFartAttack")
                    }
                    
                    // Show onboarding if haven't seen it
                    await MainActor.run {
                        if !UserDefaults.standard.bool(forKey: "hasSeenFartAttackOnboarding") {
                            // Delay slightly so user sees the main app first
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
                // After onboarding, highlight the Attacks tab
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        selectedTab = 5 // Attacks tab (after adding Activity tab)
                    }
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
