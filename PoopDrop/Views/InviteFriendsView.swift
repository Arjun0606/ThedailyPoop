import SwiftUI

struct InviteFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    
    var inviteLink: String {
        "https://apps.apple.com/app/thedailypoop/id123456789" // Replace with actual App Store link
    }
    
    var inviteMessage: String {
        """
        💩 Join me on TheDailyPoop!
        
        Track your bathroom adventures, prank friends with Ghost Attacks, compete on leaderboards, and vote in daily polls!
        
        Download now: \(inviteLink)
        """
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color.black, Color.purple.opacity(0.3), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Text("💩")
                                .font(.system(size: 80))
                            
                            Text("Invite Your Friends!")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Share TheDailyPoop and make bathroom time social")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // Features
                        VStack(spacing: 16) {
                            featureCard(
                                emoji: "👻",
                                title: "Ghost Attacks",
                                subtitle: "Send anonymous fart attacks",
                                color: .purple
                            )
                            
                            featureCard(
                                emoji: "📊",
                                title: "Daily Polls",
                                subtitle: "Vote for your friends",
                                color: .blue
                            )
                            
                            featureCard(
                                emoji: "🏆",
                                title: "Leaderboards",
                                subtitle: "Compete for daily rankings",
                                color: .yellow
                            )
                        }
                        .padding(.horizontal)
                        
                        // Share buttons
                        VStack(spacing: 16) {
                            Text("Share the App")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ShareLink(item: inviteMessage) {
                                HStack(spacing: 12) {
                                    Image(systemName: "megaphone.fill")
                                        .font(.title3)
                                    Text("Share Invite Link")
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.yellow, Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.yellow.opacity(0.4), radius: 10, x: 0, y: 5)
                            }
                            
                            Button(action: {
                                copyToClipboard()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                    Text(copied ? "Copied!" : "Copy Link")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Social proof
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Text("🌟")
                                Text("Join thousands tracking their daily drops")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                    .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Feature Card
    
    @ViewBuilder
    private func featureCard(emoji: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 50))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.5), lineWidth: 2)
                )
        )
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = inviteLink
        copied = true
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}
