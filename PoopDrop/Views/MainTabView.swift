import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BriefingView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "newspaper.fill" : "newspaper")
                    Text("Today")
                }
                .tag(0)

            LiveGlobeView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "globe.americas.fill" : "globe.americas")
                    Text("Live")
                }
                .tag(1)

            ArchiveView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "archivebox.fill" : "archivebox")
                    Text("Archive")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                    Text("You")
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
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}
