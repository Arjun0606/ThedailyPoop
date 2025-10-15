import SwiftUI
import AVFoundation

struct GhostAttackReceivedView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var friendsManager: FriendsManager
    @Environment(\.dismiss) private var dismiss
    
    let attack: FartAttack
    let onComplete: () -> Void
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var hasPlayedSound = false
    @State private var selectedGuessID: String?
    @State private var hasGuessed: Bool = false
    @State private var showingReveal = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.purple.opacity(0.8), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Status
                if attack.ghostRevealed {
                    revealedView
                } else if hasGuessed {
                    wrongGuessView
                } else {
                    guessingView
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            playFartSound()
            hasGuessed = !attack.ghostGuesses.isEmpty // If they've guessed before, show wrong guess view
        }
        .sheet(isPresented: $showingReveal) {
            RevealPurchaseView(
                attack: attack,
                onRevealPurchased: {
                    // TODO: Mark attack as revealed in CloudKit
                    dismiss()
                    onComplete()
                }
            )
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("👻")
                .font(.system(size: 80))
            
            Text("Ghost Attack!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("Someone sent you an anonymous fart")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // One guess warning
            if !attack.ghostRevealed && !hasGuessed {
                Text("You get ONE guess!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Guessing View
    
    private var guessingView: some View {
        VStack(spacing: 16) {
            Text("Who do you think sent it?")
                .font(.headline)
                .foregroundColor(.white)
            
            // Show ALL friends - no narrowing
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(friendsManager.friends) { friend in
                        FriendGuessRow(
                            friend: friend,
                            isSelected: selectedGuessID == friend.id,
                            wasGuessed: attack.ghostGuesses.contains(friend.id),
                            onTap: {
                                selectedGuessID = friend.id
                            }
                        )
                    }
                }
            }
            
            // Guess button
            if let selectedID = selectedGuessID {
                Button(action: {
                    makeGuess(userID: selectedID)
                }) {
                    Text("Make Your Guess")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(16)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Paid Reveal button ($0.99) - ONLY OPTION
            if !attack.ghostRevealed {
                Button(action: {
                    showingReveal = true
                }) {
                    HStack {
                        Text("🔓")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Can't Figure It Out?")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text("Reveal for $0.99")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
            
            // Skip button
            Button(action: {
                dismiss()
                onComplete()
            }) {
                Text("Skip for now")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Wrong Guess View
    
    private var wrongGuessView: some View {
        VStack(spacing: 20) {
            Text("😵‍💫")
                .font(.system(size: 60))
            
            Text("Wrong Guess!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("The mystery remains unsolved...")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Reveal option
            Button(action: {
                showingReveal = true
            }) {
                HStack {
                    Text("🔓")
                    VStack(alignment: .leading) {
                        Text("Reveal Who Sent It")
                            .font(.headline)
                        Text("$0.99")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            
            Button(action: {
                dismiss()
                onComplete()
            }) {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(16)
            }
        }
        .padding()
    }
    
    // MARK: - Revealed View
    
    private var revealedView: some View {
        VStack(spacing: 20) {
            Text("🎭")
                .font(.system(size: 60))
            
            Text("Mystery Solved!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Show sender
            if let sender = friendsManager.friends.first(where: { $0.id == attack.senderID }) {
                VStack(spacing: 12) {
                    Text("It was:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(sender.username)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.orange)
                    
                    Text("💨")
                        .font(.system(size: 50))
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
            }
            
            Button(action: {
                dismiss()
                onComplete()
            }) {
                Text("Got it!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(16)
            }
        }
        .padding()
    }
    
    // MARK: - Functions
    
    private func playFartSound() {
        guard !hasPlayedSound else { return }
        
        if let soundURL = Bundle.main.url(forResource: attack.soundFileName, withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
                hasPlayedSound = true
            } catch {
                print("Failed to play sound: \(error)")
            }
        }
    }
    
    private func makeGuess(userID: String) {
        // Check if correct
        if userID == attack.senderID {
            // Correct guess!
            print("🎉 Correct guess!")
            // Show the revealed view (mark as solved)
            hasGuessed = false // Keep in guessing state but auto-reveal
            // TODO: Update CloudKit to mark attack as revealed
        } else {
            // Wrong guess - ONE SHOT, YOU'RE DONE
            print("❌ Wrong guess - out of attempts!")
            hasGuessed = true
            
            // TODO: Update CloudKit with failed guess
            selectedGuessID = nil
        }
    }
}

// MARK: - Friend Guess Row

struct FriendGuessRow: View {
    let friend: User
    let isSelected: Bool
    let wasGuessed: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            guard !wasGuessed else { return }
            onTap()
        }) {
            HStack(spacing: 16) {
                // Avatar placeholder
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(friend.username.prefix(1)).uppercased())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.username)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if wasGuessed {
                        Text("Already guessed ❌")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                } else if !wasGuessed {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.orange.opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
            .opacity(wasGuessed ? 0.5 : 1.0)
        }
        .disabled(wasGuessed)
    }
}

// MARK: - Reveal Purchase View

struct RevealPurchaseView: View {
    @Environment(\.dismiss) private var dismiss
    let attack: FartAttack
    let onRevealPurchased: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("🔓")
                        .font(.system(size: 60))
                    
                    Text("Reveal Mystery Sender?")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Instantly see who sent the ghost attack")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Single reveal option - $0.99
                    Button(action: {
                        // TODO: Trigger IAP
                        onRevealPurchased()
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Text("🎭")
                                .font(.system(size: 40))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reveal Sender")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Instantly see who sent it")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text("$0.99")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.purple.opacity(0.5), lineWidth: 2)
                            )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Reveal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

