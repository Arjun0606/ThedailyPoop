import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0

    private let tabs: [(icon: String, iconFill: String, label: String)] = [
        ("newspaper", "newspaper.fill", "Today"),
        ("globe.americas", "globe.americas.fill", "Live"),
        ("clock.arrow.circlepath", "clock.arrow.circlepath", "Catch Up"),
        ("person", "person.fill", "You"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case 0: BriefingView()
                case 1: LiveGlobeView()
                case 2: ArchiveView()
                case 3: ProfileView()
                default: BriefingView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating tab bar
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            if selectedTab == index {
                                // Haptic on re-tap (scroll to top hint)
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            }
                            selectedTab = index
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == index ? tabs[index].iconFill : tabs[index].icon)
                                .font(.system(size: 20, weight: selectedTab == index ? .semibold : .regular))
                                .symbolEffect(.bounce, value: selectedTab == index)

                            Text(tabs[index].label)
                                .font(.system(size: 10, weight: selectedTab == index ? .semibold : .regular))
                        }
                        .foregroundStyle(selectedTab == index ? .white : .white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                    )
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 0.5)
                    }
            )
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}
