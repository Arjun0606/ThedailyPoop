import SwiftUI

struct AttackReactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var fartAttackManager: FartAttackManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    let attack: FartAttack
    
    @State private var selectedEmoji: String = ""
    @State private var reactionText: String = ""
    @State private var isSubmitting = false
    
    let emojiOptions = ["😭", "😂", "😱", "🤬", "💀", "🔥", "👀", "🙈"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("React to the Attack!")
                    .font(.title2.bold())
                    .padding(.top)
                
                // Emoji picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pick an emoji")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedEmoji = emoji
                                }
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 40))
                                    .frame(width: 60, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedEmoji == emoji ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Optional text reaction
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add a message (optional)")
                        .font(.headline)
                    
                    TextField("I'll get you back @\(attack.senderUsername)...", text: $reactionText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Submit button
                Button {
                    submitReaction()
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("Post Reaction")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(selectedEmoji.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(selectedEmoji.isEmpty || isSubmitting)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitReaction() {
        guard let currentUser = authManager.currentUser else { return }
        
        isSubmitting = true
        
        Task {
            do {
                // Save the reaction
                try await fartAttackManager.reactToAttack(
                    attack: attack,
                    reactor: currentUser,
                    emoji: selectedEmoji,
                    text: reactionText.isEmpty ? nil : reactionText
                )
                
                // Send push notification to the sender
                await notificationManager.notifyAttackReaction(
                    to: attack.senderID,
                    reactorUsername: currentUser.username,
                    attackID: attack.id,
                    emoji: selectedEmoji,
                    text: reactionText.isEmpty ? nil : reactionText
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error submitting reaction: \(error)")
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}
