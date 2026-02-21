import SwiftUI

/// Simple emoji picker using a TextField with emoji keyboard
struct EmojiPickerSheet: View {
    let onEmojiSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var emojiText = ""
    @FocusState private var isFocused: Bool

    // Common reaction emojis grouped by vibe
    private let emojiGrid: [[String]] = [
        ["😂", "🤣", "💀", "😭", "🫠", "😵‍💫", "🤡", "💩"],
        ["🔥", "🤯", "😱", "🫣", "😤", "🥴", "🤮", "🫡"],
        ["👑", "💰", "🎯", "⚡️", "🚀", "🗑️", "🪦", "🏆"],
        ["❤️", "💔", "👀", "🙄", "🤷", "👏", "✊", "🫶"],
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Pick your reaction")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                // Grid of popular emojis
                VStack(spacing: 12) {
                    ForEach(0..<emojiGrid.count, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(emojiGrid[row], id: \.self) { emoji in
                                Button {
                                    onEmojiSelected(emoji)
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 28))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)

                // Text field for any emoji via keyboard
                HStack(spacing: 12) {
                    TextField("Or type any emoji...", text: $emojiText)
                        .font(.system(size: 28))
                        .multilineTextAlignment(.center)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .focused($isFocused)
                        .onChange(of: emojiText) { _, newValue in
                            // Only keep the last emoji character
                            if let lastScalar = newValue.unicodeScalars.last,
                               lastScalar.properties.isEmoji && lastScalar.value > 0x238C {
                                let emoji = String(newValue.suffix(1))
                                onEmojiSelected(emoji)
                            }
                        }

                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 20)
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
}
