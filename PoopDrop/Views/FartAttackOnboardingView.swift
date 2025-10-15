import SwiftUI

struct FartAttackOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentPage = 0
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding()
                }
                
                TabView(selection: $currentPage) {
                    // Page 1: Introduction
                    VStack(spacing: 0) {
                        OnboardingPageContent(
                            emoji: "💨",
                            title: "Introducing\nGhost Attacks!",
                            subtitle: "Prank your friends with legendary fart sounds",
                            description: "Send a 4-second epic fart that plays when they open the app. It's hilarious, unexpected, and totally unforgettable!",
                            buttonText: "Continue",
                            buttonAction: { currentPage = 1 }
                        )
                    }
                    .tag(0)
                    
                    // Page 2: How it works
                    VStack(spacing: 0) {
                        OnboardingPageContent(
                            emoji: "🎁",
                            title: "Get Your First\nFREE Attack!",
                            subtitle: "We're giving you 1 free ghost attack to try",
                            description: "Go to Friends → Pick someone → Tap Send Ghost Attack. When they open the app... BOOM! 💨\n\nThen buy packs of 3 for just $1.99",
                            buttonText: "Show Me How",
                            buttonAction: { currentPage = 2 }
                        )
                    }
                    .tag(1)
                    
                    // Page 3: Call to action
                    VStack(spacing: 0) {
                        OnboardingPageContent(
                            emoji: "🚀",
                            title: "Ready to\nPrank?",
                            subtitle: "Your free attack is waiting",
                            description: "Tap the Attacks tab to see your inventory, or go to Friends and send your first attack right now!",
                            buttonText: "Let's Go!",
                            buttonAction: { completeOnboarding() }
                        )
                    }
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Spacer()
            }
        }
    }
    
    private func completeOnboarding() {
        // Mark as seen for this specific user
        if let userID = authManager.currentUser?.id {
            UserDefaults.standard.set(true, forKey: "hasSeenFartAttackOnboarding_\(userID)")
        }
        onComplete()
        dismiss()
    }
}

struct OnboardingPageContent: View {
    let emoji: String
    let title: String
    let subtitle: String
    let description: String
    let buttonText: String
    let buttonAction: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Emoji
            Text(emoji)
                .font(.system(size: 120))
                .padding(.bottom, 20)
            
            // Title
            Text(title)
                .font(.system(size: 36, weight: .black))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
            
            // Subtitle
            Text(subtitle)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
            
            // Description
            Text(description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // Button
            Button(action: buttonAction) {
                Text(buttonText)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    FartAttackOnboardingView(onComplete: {})
}

