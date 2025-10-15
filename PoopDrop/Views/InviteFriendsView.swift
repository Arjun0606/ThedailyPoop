import SwiftUI

struct InviteFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var copied = false
    @State private var showingShareSheet = false
    @State private var friendsInvited: Int = 0 // Track via UserDefaults or CloudKit
    
    var inviteLink: String {
        "https://poopdrop.app/invite?ref=\(authManager.currentUser?.id ?? "app")"
    }
    
    var inviteMessage: String {
        """
        💩 I dare you to join me on TheDailyPoop!
        
        Track your drops, prank friends with Ghost Attacks, and compete on leaderboards!
        
        Download now: \(inviteLink)
        """
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background for excitement
                LinearGradient(
                    colors: [Color.black, Color.purple.opacity(0.3), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Massive reward header
                        VStack(spacing: 16) {
                            Text("💰")
                                .font(.system(size: 80))
                            
                            Text("Get FREE Ghost Attacks!")
                                .font(.largeTitle.bold())
                                .foregroundColor(.yellow)
                                .multilineTextAlignment(.center)
                            
                            Text("Invite friends and dominate the leaderboard")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Reward breakdown (THE KILLER FEATURE)
                        VStack(spacing: 16) {
                            rewardCard(
                                emoji: "🎁",
                                title: "3 FREE Attacks",
                                subtitle: "For every friend who joins",
                                color: .green
                            )
                            
                            rewardCard(
                                emoji: "🔥",
                                title: "Unlimited Rewards",
                                subtitle: "No limit! Invite 10 friends = 30 attacks",
                                color: .orange
                            )
                            
                            rewardCard(
                                emoji: "👑",
                                title: "Dominate the Leaderboard",
                                subtitle: "More attacks = higher rank",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                        
                        // Progress tracker
                        VStack(spacing: 12) {
                            HStack {
                                Text("Your Progress")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(friendsInvited) friends invited")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)
                            }
                            
                            // Progress bar
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .yellow],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: progressWidth, height: 12)
                            }
                            
                            HStack {
                                Text("🎯 Next: \(3 - (friendsInvited % 3)) friends = 3 attacks")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                        .padding(.horizontal)
                        
                        // Share buttons
                        VStack(spacing: 16) {
                            Text("Start Inviting Now!")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ShareLink(item: inviteMessage) {
                                HStack(spacing: 12) {
                                    Image(systemName: "megaphone.fill")
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Share Invite Link")
                                            .fontWeight(.bold)
                                        Text("3 attacks per friend")
                                            .font(.caption)
                                    }
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
                                Text("⚡️")
                                Text("Top pranksters invited 10+ friends")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Free Attacks")
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
        .onAppear {
            loadInviteProgress()
        }
    }
    
    // MARK: - Reward Card
    
    @ViewBuilder
    private func rewardCard(emoji: String, title: String, subtitle: String, color: Color) -> some View {
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
    
    // MARK: - Progress Width
    
    private var progressWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 64 // Account for padding
        let progress = CGFloat(friendsInvited % 5) / 5.0
        return screenWidth * progress
    }
    
    // MARK: - Load Invite Progress
    
    private func loadInviteProgress() {
        // Load from UserDefaults or CloudKit
        friendsInvited = UserDefaults.standard.integer(forKey: "friendsInvited_\(authManager.currentUser?.id ?? "")")
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
