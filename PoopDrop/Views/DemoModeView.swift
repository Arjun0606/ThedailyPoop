import SwiftUI
import MapKit

/// Demo Mode View - Uses REAL app views with injected demo data
/// This ensures Apple reviewers see the EXACT same UI as real users
struct DemoModeView: View {
    @EnvironmentObject var demoManager: DemoModeManager
    @StateObject private var demoAuth = DemoAuthManager()
    @StateObject private var demoCloudKit = DemoCloudKitManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedTab = 0
    @State private var showingDropComposer = false
    
    var body: some View {
        ZStack {
            // Use the REAL MainTabView with demo data injected
            TabView(selection: $selectedTab) {
                // Feed Tab - REAL FeedView
                FeedView()
                    .environmentObject(demoAuth)
                    .environmentObject(demoCloudKit)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Feed")
                    }
                    .tag(0)
                
                // Friends Tab - REAL FriendsView
                FriendsView()
                    .environmentObject(demoAuth)
                    .environmentObject(demoCloudKit)
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
                    .environmentObject(demoAuth)
                    .environmentObject(demoCloudKit)
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "map.fill" : "map")
                        Text("Map")
                    }
                    .tag(3)
                
                // Profile Tab - REAL ProfileView
                ProfileView()
                    .environmentObject(demoAuth)
                    .environmentObject(demoCloudKit)
                    .environmentObject(subscriptionManager)
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
                    Text("DEMO MODE")
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
                .environmentObject(demoAuth)
                .environmentObject(demoCloudKit)
                .environmentObject(locationManager)
        }
    }
}

// MARK: - Demo Authentication Manager
/// Mock authentication manager that provides demo user data
@MainActor
class DemoAuthManager: ObservableObject {
    @Published var isAuthenticated = true
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Set demo user
        self.currentUser = DemoModeManager.shared.demoUser
    }
}

// MARK: - Demo CloudKit Manager
/// Mock CloudKit manager that provides demo data instead of real CloudKit calls
@MainActor
class DemoCloudKitManager: ObservableObject {
    @Published var drops: [Drop] = []
    @Published var friends: [User] = []
    @Published var isLoading = false
    
    init() {
        self.drops = DemoModeManager.shared.demoDrops
        self.friends = DemoModeManager.shared.demoFriends
    }
    
    // Mock methods that the real views might call
    func fetchDrops(limit: Int = 100) async throws -> [Drop] {
        return DemoModeManager.shared.demoDrops
    }
    
    func fetchUserDrops(userID: String, limit: Int = 50) async throws -> [Drop] {
        return DemoModeManager.shared.demoDrops.filter { $0.userID == userID }
    }
    
    func fetchNearbyDrops(coordinate: CLLocationCoordinate2D, radiusKm: Double = 50) async throws -> [Drop] {
        return DemoModeManager.shared.demoDrops
    }
    
    func createDrop(_ drop: Drop) async throws -> Drop {
        // Add to demo drops
        DemoModeManager.shared.demoDrops.insert(drop, at: 0)
        
        // Update published property
        await MainActor.run {
            self.drops = DemoModeManager.shared.demoDrops
        }
        
        return drop
    }
    
    func saveUser(_ user: User) async throws {
        // Update demo user
        DemoModeManager.shared.demoUser = user
    }
    
    func fetchUserByAppleUserID(_ appleUserID: String) async throws -> User? {
        return DemoModeManager.shared.demoUser
    }
    
    func searchUsers(username: String) async throws -> [User] {
        return DemoModeManager.shared.demoFriends.filter { $0.username.contains(username) }
    }
    
    func sendFriendRequest(to userID: String) async throws {
        // Demo - do nothing
    }
    
    func acceptFriendRequest(from userID: String) async throws {
        // Demo - do nothing
    }
    
    func getFriendRequests() async throws -> [User] {
        return []
    }
    
    func getFriends() async throws -> [User] {
        return DemoModeManager.shared.demoFriends
    }
    
    func addReaction(to dropID: String, emoji: String) async throws {
        // Demo - find drop and add reaction
        if let index = DemoModeManager.shared.demoDrops.firstIndex(where: { $0.id == dropID }) {
            var drop = DemoModeManager.shared.demoDrops[index]
            drop.reactions[emoji, default: 0] += 1
            drop.reactionCount += 1
            DemoModeManager.shared.demoDrops[index] = drop
            
            // Update published property
            await MainActor.run {
                self.drops = DemoModeManager.shared.demoDrops
            }
        }
    }
    
    func removeReaction(from dropID: String, emoji: String) async throws {
        // Demo - find drop and remove reaction
        if let index = DemoModeManager.shared.demoDrops.firstIndex(where: { $0.id == dropID }) {
            var drop = DemoModeManager.shared.demoDrops[index]
            if let count = drop.reactions[emoji], count > 0 {
                drop.reactions[emoji] = count - 1
                drop.reactionCount -= 1
                if drop.reactions[emoji] == 0 {
                    drop.reactions.removeValue(forKey: emoji)
                }
                DemoModeManager.shared.demoDrops[index] = drop
                
                // Update published property
                await MainActor.run {
                    self.drops = DemoModeManager.shared.demoDrops
                }
            }
        }
    }
}
