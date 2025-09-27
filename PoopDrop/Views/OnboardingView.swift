import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    
    private let pages = [
        OnboardingPage(
            emoji: "💩",
            title: "Welcome to Poop Drop!",
            description: "The most fun way to share your bathroom adventures with friends around the world!"
        ),
        OnboardingPage(
            emoji: "📍",
            title: "Drop Your Poops",
            description: "Drop poops at your current location and see what your friends are up to on the map!"
        ),
        OnboardingPage(
            emoji: "👑",
            title: "Go Pro for More Fun",
            description: "Unlock premium skins, longer captions, custom reactions, and exclusive map themes!"
        )
    ]
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [Color.black, Color.brown.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Current page content
                VStack(spacing: 30) {
                    Text(pages[currentPage].emoji)
                        .font(.system(size: 120))
                        .scaleEffect(currentPage == 0 ? 1.2 : 1.0)
                        .animation(.bouncy(duration: 0.6), value: currentPage)
                    
                    VStack(spacing: 16) {
                        Text(pages[currentPage].title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(pages[currentPage].description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
                Spacer()
                
                // Navigation buttons
                VStack(spacing: 16) {
                    if currentPage < pages.count - 1 {
                        Button(action: nextPage) {
                            HStack {
                                Text("Next")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        Button("Skip", action: onComplete)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 8)
                    } else {
                        Button(action: onComplete) {
                            Text("Get Started! 💩")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.x < -50 && currentPage < pages.count - 1 {
                        nextPage()
                    } else if value.translation.x > 50 && currentPage > 0 {
                        previousPage()
                    }
                }
        )
    }
    
    private func nextPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = min(currentPage + 1, pages.count - 1)
        }
    }
    
    private func previousPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage = max(currentPage - 1, 0)
        }
    }
}

struct OnboardingPage {
    let emoji: String
    let title: String
    let description: String
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}
