import SwiftUI

struct FartAttackReceivedView: View {
    let attack: FartAttack
    let onDismiss: () -> Void
    
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingReactionSheet = false
    @State private var selectedEmoji: String? = nil
    @State private var customText: String = ""
    @State private var isSubmitting = false
    @State private var canDismiss = false
    @State private var animationPhase = 0
    
    var body: some View {
        ZStack {
            // Full-screen dark background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Animated fart emojis
                HStack(spacing: 20) {
                    ForEach(0..<3, id: \.self) { index in
                        Text("💨")
                            .font(.system(size: 80))
                            .scaleEffect(animationPhase == index ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animationPhase)
                    }
                }
                .padding(.bottom, 20)
                
                // Main message
                VStack(spacing: 16) {
                    Text("YOU'VE BEEN")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("FART ATTACKED!")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.center)
                    
                    Text("By @\(attack.senderUsername)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.top, 8)
                }
                
                // Epic blast indicator
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.title2)
                    Text("EPIC BLAST PLAYING...")
                        .font(.headline)
                }
                .foregroundColor(.orange)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.2))
                )
                
                Spacer()
                
                // Dismiss button (only after 4 seconds)
                if canDismiss {
                    VStack(spacing: 16) {
                        Button(action: onDismiss) {
                            Text("Dismiss")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.yellow)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        
                        Button(action: {
                            showingReactionSheet = true
                        }) {
                            HStack(spacing: 8) {
                                Text("💨")
                                Text("React / Get Revenge?")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .font(.subheadline)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Can't dismiss yet...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 40)
                }
            }
            .padding()
        }
        .onAppear {
            // Start animation
            withAnimation {
                animationPhase = 1
            }
            
            // Enable dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation(.spring()) {
                    canDismiss = true
                }
            }
        }
        .sheet(isPresented: $showingReactionSheet) {
            AttackReactionSheet(attack: attack)
                .onDisappear {
                    showingReactionSheet = false
                    onDismiss()
                }
        }
    }
}

// MARK: - Preview
#Preview {
    FartAttackReceivedView(
        attack: FartAttack(
            senderID: "user123",
            senderUsername: "prankster",
            targetUserID: "user456",
            targetUsername: "victim"
        ),
        onDismiss: {}
    )
}

