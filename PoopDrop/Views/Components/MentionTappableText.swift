import SwiftUI

/// A beautiful SwiftUI component that renders text with tappable @mentions
/// Handles all mention interactions and provides clean action callbacks
struct MentionTappableText: View {
    let text: String
    let fontSize: CGFloat
    let textColor: Color
    let mentionColor: Color
    let onMentionTapped: (String) -> Void // Called with username (without @)
    
    @State private var segments: [MentionDetector.TextSegment] = []
    @State private var selectedMention: String?
    
    init(
        text: String,
        fontSize: CGFloat = 16,
        textColor: Color = .white,
        mentionColor: Color = .purple,
        onMentionTapped: @escaping (String) -> Void
    ) {
        self.text = text
        self.fontSize = fontSize
        self.textColor = textColor
        self.mentionColor = mentionColor
        self.onMentionTapped = onMentionTapped
    }
    
    var body: some View {
        // Use Text concatenation for inline rendering
        segments.reduce(Text("")) { result, segment in
            switch segment {
            case .text(let str):
                return result + Text(str)
                    .foregroundColor(textColor)
                    .font(.system(size: fontSize))
                
            case .mention(let username):
                return result + Text("@\(username)")
                    .foregroundColor(mentionColor)
                    .font(.system(size: fontSize, weight: .semibold))
                    .underline()
            }
        }
        .onTapGesture {
            // Detect which mention was tapped (if any)
            // For now, show action sheet for all mentions in text
            // In future, could use UITextView for precise tap detection
            let mentionedUsernames = MentionDetector.extractMentions(from: text)
            if !mentionedUsernames.isEmpty {
                selectedMention = mentionedUsernames.first
            }
        }
        .onAppear {
            segments = MentionDetector.parseTextSegments(from: text)
        }
        .onChange(of: text) { newText in
            segments = MentionDetector.parseTextSegments(from: newText)
        }
        .actionSheet(item: Binding(
            get: { selectedMention.map { MentionActionItem(username: $0) } },
            set: { selectedMention = $0?.username }
        )) { item in
            ActionSheet(
                title: Text("@\(item.username)"),
                message: Text("What would you like to do?"),
                buttons: [
                    .default(Text("View on Map 🗺️")) {
                        onMentionTapped(item.username)
                    },
                    .default(Text("View Profile 👤")) {
                        // For now, same action as map
                        // In future, could have separate profile view
                        onMentionTapped(item.username)
                    },
                    .cancel()
                ]
            )
        }
    }
}

// Helper struct for ActionSheet
private struct MentionActionItem: Identifiable {
    let id = UUID()
    let username: String
}

// MARK: - Advanced Version with Precise Tap Detection

/// Advanced mention text that detects WHICH specific mention was tapped
/// Uses attributed string and tap location detection
struct AdvancedMentionText: View {
    let text: String
    let fontSize: CGFloat
    let textColor: Color
    let mentionColor: Color
    let onMentionTapped: (String) -> Void
    
    @State private var tappedMention: String?
    
    init(
        text: String,
        fontSize: CGFloat = 16,
        textColor: Color = .white,
        mentionColor: Color = .purple,
        onMentionTapped: @escaping (String) -> Void
    ) {
        self.text = text
        self.fontSize = fontSize
        self.textColor = textColor
        self.mentionColor = mentionColor
        self.onMentionTapped = onMentionTapped
    }
    
    var body: some View {
        MentionTextViewRepresentable(
            text: text,
            fontSize: fontSize,
            textColor: UIColor(textColor),
            mentionColor: UIColor(mentionColor),
            onMentionTapped: { username in
                tappedMention = username
            }
        )
        .frame(minHeight: fontSize * 1.5) // Ensure proper height
        .actionSheet(item: Binding(
            get: { tappedMention.map { MentionActionItem(username: $0) } },
            set: { tappedMention = $0?.username }
        )) { item in
            ActionSheet(
                title: Text("@\(item.username)"),
                message: Text("What would you like to do?"),
                buttons: [
                    .default(Text("View on Map 🗺️")) {
                        onMentionTapped(item.username)
                    },
                    .default(Text("View Profile 👤")) {
                        onMentionTapped(item.username)
                    },
                    .cancel()
                ]
            )
        }
    }
}

// MARK: - UITextView Wrapper for Precise Tap Detection

private struct MentionTextViewRepresentable: UIViewRepresentable {
    let text: String
    let fontSize: CGFloat
    let textColor: UIColor
    let mentionColor: UIColor
    let onMentionTapped: (String) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        let attributedString = createAttributedString()
        uiView.attributedText = attributedString
        
        // Store mention ranges in coordinator for tap detection
        context.coordinator.mentionRanges = extractMentionRanges(from: text)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onMentionTapped: onMentionTapped)
    }
    
    private func createAttributedString() -> NSAttributedString {
        let segments = MentionDetector.parseTextSegments(from: text)
        let attributedString = NSMutableAttributedString()
        
        for segment in segments {
            switch segment {
            case .text(let str):
                let attrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: textColor,
                    .font: UIFont.systemFont(ofSize: fontSize)
                ]
                attributedString.append(NSAttributedString(string: str, attributes: attrs))
                
            case .mention(let username):
                let mentionText = "@\(username)"
                let attrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: mentionColor,
                    .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: "mention://\(username)" // Custom URL scheme for detection
                ]
                attributedString.append(NSAttributedString(string: mentionText, attributes: attrs))
            }
        }
        
        return attributedString
    }
    
    private func extractMentionRanges(from text: String) -> [(range: NSRange, username: String)] {
        var ranges: [(NSRange, String)] = []
        let pattern = "@([a-zA-Z][a-zA-Z0-9_]*)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return ranges
        }
        
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)
        
        for match in matches {
            if let usernameRange = Range(match.range(at: 1), in: text) {
                let username = String(text[usernameRange])
                ranges.append((match.range, username))
            }
        }
        
        return ranges
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UITextViewDelegate {
        let onMentionTapped: (String) -> Void
        var mentionRanges: [(range: NSRange, username: String)] = []
        
        init(onMentionTapped: @escaping (String) -> Void) {
            self.onMentionTapped = onMentionTapped
        }
        
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            // Detect custom mention:// URL scheme
            if URL.scheme == "mention", let username = URL.host {
                onMentionTapped(username)
                return false // Prevent default action
            }
            return true
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Simple version
        MentionTappableText(
            text: "Hey @Sarah and @Jake! Let's meet at @Starbucks 🔥",
            fontSize: 16,
            textColor: .white,
            mentionColor: .purple
        ) { username in
            print("Tapped: @\(username)")
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        
        // Advanced version with precise tap detection
        AdvancedMentionText(
            text: "Saw @Emily with @Mike at the library 👀",
            fontSize: 18,
            textColor: .white,
            mentionColor: .yellow
        ) { username in
            print("Advanced tap: @\(username)")
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
    .padding()
    .background(Color.black)
}

