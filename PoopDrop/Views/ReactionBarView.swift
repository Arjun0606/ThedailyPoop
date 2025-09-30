import SwiftUI

struct ReactionBarView: View {
    let drop: Drop
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @State private var localReactions: [String: Int]
    @State private var showingEmojiPicker = false
    @State private var showingProUpsell = false
    @State private var userReactions: Set<String> = [] // Track what user has reacted to
    
    private let freeReactions = ["😂", "🤢", "🔥", "👏"]
    
    init(drop: Drop) {
        self.drop = drop
        self._localReactions = State(initialValue: [:])
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // All users: show top reactions + add button
            ProReactionView(
                reactions: localReactions,
                onReactionTap: handleReaction,
                onAddReaction: {
                    showingEmojiPicker = true
                }
            )
        }
        .sheet(isPresented: $showingEmojiPicker) {
            EmojiPickerView { emoji in
                handleReaction(emoji)
                showingEmojiPicker = false
            }
        }
        .sheet(isPresented: $showingProUpsell) {
            ProUpsellView()
        }
        .onReceive(cloudKitManager.$drops) { drops in
            // Update local reactions when CloudKit data changes
            if let updatedDrop = drops.first(where: { $0.id == drop.id }) {
                // Fetch reactions from CloudKit for this drop
                // localReactions = updatedDrop.reactions
            }
        }
    }
    
    private func handleReaction(_ emoji: String) {
        // Check if user already reacted with this emoji
        let hasReacted = userReactions.contains(emoji)
        
        // Update local state immediately for responsiveness
        if hasReacted {
            // Remove reaction
            localReactions[emoji] = max(0, (localReactions[emoji] ?? 0) - 1)
            if localReactions[emoji] == 0 {
                localReactions.removeValue(forKey: emoji)
            }
            userReactions.remove(emoji)
        } else {
            // Add reaction
            localReactions[emoji] = (localReactions[emoji] ?? 0) + 1
            userReactions.insert(emoji)
        }
        
        // Update CloudKit
        Task {
            do {
                try await cloudKitManager.updateDropReaction(drop.id, emoji: emoji, increment: !hasReacted)
            } catch {
                // Revert local changes on error
                if hasReacted {
                    localReactions[emoji] = (localReactions[emoji] ?? 0) + 1
                    userReactions.insert(emoji)
                } else {
                    localReactions[emoji] = max(0, (localReactions[emoji] ?? 0) - 1)
                    if localReactions[emoji] == 0 {
                        localReactions.removeValue(forKey: emoji)
                    }
                    userReactions.remove(emoji)
                }
                print("Failed to update reaction: \(error)")
            }
        }
    }
}

struct FreeReactionView: View {
    let reactions: [String: Int]
    let freeReactions: [String]
    let onReactionTap: (String) -> Void
    let onProReactionTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(freeReactions, id: \.self) { emoji in
                ReactionButton(
                    emoji: emoji,
                    count: reactions[emoji] ?? 0,
                    isSelected: false
                    action: {
                        onReactionTap(emoji)
                    }
                )
            }
            
            // Pro teaser button
            Button(action: onProReactionTap) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.yellow)
                    Text("PRO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(12)
            }
        }
    }
}

struct ProReactionView: View {
    let reactions: [String: Int]
    let onReactionTap: (String) -> Void
    let onAddReaction: () -> Void
    
    // Show top reactions + add button
    var topReactions: [String] {
        Array(reactions.keys.sorted { reactions[$0] ?? 0 > reactions[$1] ?? 0 }.prefix(6))
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(topReactions, id: \.self) { emoji in
                ReactionButton(
                    emoji: emoji,
                    count: reactions[emoji] ?? 0,
                    isSelected: false
                    action: {
                        onReactionTap(emoji)
                    }
                )
            }
            
            // Add reaction button
            Button(action: onAddReaction) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.white)
                    .font(.title3)
            }
        }
    }
}

struct ReactionButton: View {
    let emoji: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.body)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, count > 0 ? 8 : 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.bouncy(duration: 0.3), value: isSelected)
    }
}

struct EmojiPickerView: View {
    let onEmojiSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    // Popular emojis organized by category
    private let emojiCategories = [
        "Faces": ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙", "😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔", "🤐", "🤨", "😐", "😑", "😶", "😏", "😒", "🙄", "😬", "🤥", "😔", "😪", "🤤", "😴", "😷", "🤒", "🤕", "🤢", "🤮", "🤧", "🥵", "🥶", "🥴", "😵", "🤯", "🤠", "🥳", "😎", "🤓", "🧐"],
        "Poop & Fun": ["💩", "🔥", "💯", "✨", "⭐", "🌟", "💫", "🎉", "🎊", "🎈", "🎁", "🏆", "🥇", "🥈", "🥉", "👑", "💎", "💰", "🤑"],
        "Hearts": ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝"],
        "Gestures": ["👍", "👎", "👌", "🤌", "🤏", "✌️", "🤞", "🤟", "🤘", "🤙", "👈", "👉", "👆", "🖕", "👇", "☝️", "👏", "🙌", "👐", "🤲", "🤝", "🙏"],
        "Food": ["🍎", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑", "🥦", "🥬", "🥒", "🌶️", "🌽", "🥕", "🧄", "🧅", "🥔", "🍠", "🥐", "🍞", "🥖", "🥨", "🧀", "🥚", "🍳", "🧈", "🥞", "🧇", "🥓", "🥩", "🍗", "🍖", "🌭", "🍔", "🍟", "🍕", "🥪", "🥙", "🌮", "🌯", "🥗", "🥘", "🥫", "🍝", "🍜", "🍲", "🍛", "🍣", "🍱", "🥟", "🦪", "🍤", "🍙", "🍚", "🍘", "🍥", "🥠", "🥮", "🍢", "🍡", "🍧", "🍨", "🍦", "🥧", "🧁", "🍰", "🎂", "🍮", "🍭", "🍬", "🍫", "🍿", "🍩", "🍪", "🌰", "🥜", "🍯"]
    ]
    
    @State private var selectedCategory = "Faces"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(emojiCategories.keys), id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                                    .font(.subheadline)
                                    .fontWeight(selectedCategory == category ? .semibold : .regular)
                                    .foregroundColor(selectedCategory == category ? .yellow : .white.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedCategory == category ? Color.yellow.opacity(0.2) : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Emoji grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(emojiCategories[selectedCategory] ?? [], id: \.self) { emoji in
                            Button(action: {
                                onEmojiSelected(emoji)
                            }) {
                                Text(emoji)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color.black)
            .navigationTitle("Choose Reaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ReactionBarView(drop: Drop.sampleDrop)
        .environmentObject(SubscriptionManager())
        .environmentObject(CloudKitManager())
        .background(Color.black)
}
