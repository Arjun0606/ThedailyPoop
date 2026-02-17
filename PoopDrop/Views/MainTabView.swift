import SwiftUI
import CoreLocation

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    @State private var showingDropComposer = false
    @State private var showingDeepLinkJoin = false
    @State private var deepLinkInviteCode = ""

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
            // Deep link: open join group with pre-filled code
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OPEN_JOIN_GROUP"))) { notification in
                if let code = notification.userInfo?["inviteCode"] as? String {
                    deepLinkInviteCode = code
                    selectedTab = 2  // Switch to groups tab
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingDeepLinkJoin = true
                    }
                }
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
        .sheet(isPresented: $showingDeepLinkJoin) {
            DeepLinkJoinView(inviteCode: deepLinkInviteCode)
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 0 {
                NotificationCenter.default.post(name: Notification.Name("REFRESH_MAP"), object: nil)
            }
        }
    }
}

// MARK: - Deep Link Join View (auto-fills invite code from URL)
struct DeepLinkJoinView: View {
    let inviteCode: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isJoining = false
    @State private var joinedGroup: Group?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                if let group = joinedGroup {
                    // Success state
                    Text("🎉")
                        .font(.system(size: 80))

                    Text("You're in!")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    VStack(spacing: 8) {
                        Text(group.emoji)
                            .font(.system(size: 48))
                        Text(group.name)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                    }

                    Button(action: { dismiss() }) {
                        Text("Let's Go")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 40)
                } else if let error = errorMessage {
                    // Error state
                    Text("😕")
                        .font(.system(size: 80))

                    Text("Couldn't Join")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 40)
                } else {
                    // Loading state
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    Text("Joining group...")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Code: \(inviteCode)")
                        .font(.title3.monospaced())
                        .foregroundStyle(.yellow)
                }
            }
        }
        .task { await joinGroup() }
    }

    private func joinGroup() async {
        guard let user = authManager.currentUser else {
            errorMessage = "You need to sign in first."
            return
        }
        isJoining = true
        do {
            let group = try await SupabaseManager.shared.joinGroupByInviteCode(inviteCode, userID: user.id)
            joinedGroup = group
        } catch {
            errorMessage = "Invalid or expired invite code."
        }
        isJoining = false
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
        .environmentObject(LocationManager())
}
