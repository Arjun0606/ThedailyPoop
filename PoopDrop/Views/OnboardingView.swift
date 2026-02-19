import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages = [
        OnboardingPage(
            emoji: "",
            title: "Welcome to\nTheDailyPoop",
            description: "Your daily scoop on business, tech, politics, sports, and culture — delivered with the irreverence of a group chat and the depth of actual journalism.",
            accent: Color(red: 1.0, green: 0.76, blue: 0.28),
            useLogo: true
        ),
        OnboardingPage(
            emoji: "📰",
            title: "20 Stories.\nEvery Morning.",
            description: "Deep dives, quick hits, and everything in between — fresh every day at 7 AM. 10 free stories daily, upgrade for the full 20.",
            accent: Color(red: 1.0, green: 0.55, blue: 0.2)
        ),
        OnboardingPage(
            emoji: "🔥",
            title: "Build Your\nStreak",
            description: "Read at least one story a day to keep your streak alive. Miss a day and it resets. No pressure... but also, pressure.",
            accent: .orange
        )
    ]

    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: [.black, pages[currentPage].accent.opacity(0.15), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Progress bar
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentPage ? pages[currentPage].accent : Color.white.opacity(0.15))
                            .frame(height: 3)
                            .animation(.spring(response: 0.4), value: currentPage)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)

                Spacer()

                // Content
                VStack(spacing: 36) {
                    // Emoji or Logo
                    Group {
                        if pages[currentPage].useLogo {
                            AppLogoView(size: 100)
                        } else {
                            Text(pages[currentPage].emoji)
                                .font(.system(size: 100))
                        }
                    }
                    .shadow(color: pages[currentPage].accent.opacity(0.4), radius: 40, x: 0, y: 10)
                    .id("emoji_\(currentPage)")
                    .transition(.scale.combined(with: .opacity))

                    VStack(spacing: 16) {
                        Text(pages[currentPage].title)
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .id("title_\(currentPage)")
                            .transition(.push(from: .trailing))

                        Text(pages[currentPage].description)
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                            .id("desc_\(currentPage)")
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Bottom actions
                VStack(spacing: 14) {
                    if currentPage < pages.count - 1 {
                        Button(action: nextPage) {
                            HStack(spacing: 8) {
                                Text("Next")
                                    .font(.system(size: 17, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(pages[currentPage].accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(PressableButtonStyle())

                        Button("Skip", action: onComplete)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.vertical, 6)
                    } else {
                        Button(action: onComplete) {
                            HStack(spacing: 8) {
                                Text("Get Started")
                                    .font(.system(size: 17, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.orange, Theme.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 && currentPage < pages.count - 1 {
                        nextPage()
                    } else if value.translation.width > 50 && currentPage > 0 {
                        previousPage()
                    }
                }
        )
    }

    private func nextPage() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentPage = min(currentPage + 1, pages.count - 1)
        }
    }

    private func previousPage() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentPage = max(currentPage - 1, 0)
        }
    }
}

struct OnboardingPage {
    let emoji: String
    let title: String
    let description: String
    let accent: Color
    var useLogo: Bool = false
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}
