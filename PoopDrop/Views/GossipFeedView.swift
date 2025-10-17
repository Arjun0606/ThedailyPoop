import SwiftUI

struct GossipFeedView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var friendsManager: FriendsManager
    @StateObject private var gossipManager = GossipManager.shared
    @StateObject private var storeKitManager = StoreKitManager.shared
    
    @State private var showingComposer = false
    @State private var showingRevealed: Set<String> = []
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var toastIcon = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Feed
                    if gossipManager.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if gossipManager.todaysGossip.isEmpty {
                        EmptyGossipView(onPost: { showingComposer = true })
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(gossipManager.todaysGossip) { gossip in
                                    GossipCard(
                                        gossip: gossip,
                                        currentUser: authManager.currentUser!,
                                        friends: friendsManager.friends,
                                        isRevealed: showingRevealed.contains(gossip.id) || gossipManager.myReveals[gossip.id] != nil,
                                        onReveal: {
                                            await revealSender(gossip)
                                        },
                                        onReact: { emoji in
                                            await gossipManager.addReaction(to: gossip.id, emoji: emoji)
                                        }
                                    )
                                }
                            }
                            .padding(.vertical)
                            .padding(.bottom, 80) // Space for FAB
                        }
                        .refreshable {
                            await gossipManager.loadTodaysGossip()
                        }
                    }
                }
                
                // Floating Action Button (only show when there's gossip)
                if !gossipManager.todaysGossip.isEmpty && !gossipManager.isLoading {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: { showingComposer = true }) {
                                Image(systemName: "plus")
                                    .font(.title2.bold())
                                    .foregroundColor(.black)
                                    .frame(width: 60, height: 60)
                                    .background(Color.yellow)
                                    .clipShape(Circle())
                                    .shadow(color: Color.yellow.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 90) // Above tab bar
                        }
                    }
                }
            }
            .navigationTitle("☕ Gossip")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingComposer) {
                GossipComposerView()
            }
            .overlay(alignment: .top) {
                if showingToast {
                    ToastView(message: toastMessage, icon: toastIcon)
                        .padding(.top, 50)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(999)
                }
            }
            .task {
                await gossipManager.loadTodaysGossip()
                if let currentUser = authManager.currentUser {
                    await gossipManager.loadMyReveals(for: currentUser.id)
                }
            }
        }
    }
    
    private func revealSender(_ gossip: GossipPost) async {
        guard let currentUser = authManager.currentUser else { return }
        
        // Purchase reveal IAP
        do {
            if let product = storeKitManager.getProduct(byID: IAPProducts.gossipReveal) {
                // CRITICAL FIX: Check if purchase was successful
                let purchaseSucceeded = try await storeKitManager.purchase(product)
                
                // ONLY reveal if payment succeeded
                if purchaseSucceeded {
                    let (revealed, sender) = await gossipManager.revealSender(
                        gossipID: gossip.id,
                        currentUser: currentUser
                    )
                    
                    if revealed {
                        showingRevealed.insert(gossip.id)
                        print("✅ Revealed sender: \(sender ?? "unknown")")
                        showToast("Revealed! @\(sender ?? "unknown")", icon: "checkmark.circle.fill")
                    }
                } else {
                    print("❌ Purchase cancelled or failed - NOT revealing")
                }
            }
        } catch {
            print("❌ Purchase error: \(error) - NOT revealing")
            showToast("Purchase failed. Try again.", icon: "xmark.circle.fill")
        }
    }
    
    private func showToast(_ message: String, icon: String) {
        toastMessage = message
        toastIcon = icon
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showingToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showingToast = false
            }
        }
    }
}

// MARK: - Gossip Card
struct GossipCard: View {
    let gossip: GossipPost
    let currentUser: User
    let friends: [User]
    let isRevealed: Bool
    let onReveal: () async -> Void
    let onReact: (String) async -> Void
    
    @State private var showingReactions = false
    @State private var showingReplies = false
    
    // Check if current user is mentioned
    private var isMentioned: Bool {
        gossip.mentionedUserIDs.contains(currentUser.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(isRevealed ? Color.purple : Color.gray)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: isRevealed ? "person.fill" : "person.fill.questionmark")
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isRevealed ? gossip.posterUsername : "Anonymous")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(gossip.createdAt.timeAgoString())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Expires indicator
                if gossip.expiresAt.timeIntervalSinceNow < 3600 {
                    Text("⏰ Expires soon")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // Gossip text
            Text(gossip.text)
                .font(.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            // Stats row
            HStack(spacing: 16) {
                // Reactions count
                if !gossip.reactions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(gossip.reactions.keys.prefix(3)), id: \.self) { emoji in
                            Text(emoji)
                        }
                        if gossip.reactions.values.reduce(0, +) > 0 {
                            Text("\(gossip.reactions.values.reduce(0, +))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Reply count
                if gossip.replyCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("\(gossip.replyCount)")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                // View count
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                    Text("\(gossip.viewCount)")
                }
                .font(.caption)
                .foregroundColor(.gray)
                
                Spacer()
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // React button
                Button(action: { showingReactions.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "face.smiling")
                        Text("React")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                // Reply button
                Button(action: { showingReplies.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("Reply")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Reply thread (if showing)
            if showingReplies {
                ReplyThreadView(
                    gossipID: gossip.id,
                    currentUser: currentUser,
                    onClose: { showingReplies = false }
                )
            }
            
            // SMART REVEAL BUTTON: Dynamic styling based on urgency, social proof, and mentions
            if !isRevealed {
                Button(action: { Task { await onReveal() }}) {
                    HStack {
                        Image(systemName: revealButtonIcon)
                        Text(revealButtonText)
                    }
                    .font(revealButtonFont)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(revealButtonBackground)
                    .cornerRadius(10)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Posted by @\(gossip.posterUsername)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 4)
            }
            
            // CROSS-TAB INTEGRATION: Link to mentioned users' drops
            if !gossip.mentionedUsernames.isEmpty {
                Button(action: {
                    // Switch to Map tab and show mentioned user's drops
                    if let firstMentionedUsername = gossip.mentionedUsernames.first {
                        NotificationCenter.default.post(
                            name: Notification.Name("SHOW_DROP_FROM_GOSSIP"),
                            object: nil,
                            userInfo: ["username": firstMentionedUsername]
                        )
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.purple)
                        Text("See @\(gossip.mentionedUsernames.first ?? "their") drops on map")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            
            // Reaction picker
            if showingReactions {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(["😂", "😱", "🔥", "💀", "👀", "🤮", "💩", "🚽"], id: \.self) { emoji in
                            Button(action: {
                                Task {
                                    await onReact(emoji)
                                    showingReactions = false
                                }
                            }) {
                                Text(emoji)
                                    .font(.title2)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isMentioned ? Color.red.opacity(0.1) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isMentioned ? Color.red.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - Smart Reveal Button Helpers
    
    private var isUrgent: Bool {
        gossip.expiresAt.timeIntervalSinceNow < 3600 // Less than 1 hour
    }
    
    private var hasMultipleReveals: Bool {
        gossip.revealedBy.count >= 3
    }
    
    private var revealButtonIcon: String {
        if isUrgent {
            return "clock.fill"
        } else if isMentioned {
            return "exclamationmark.circle.fill"
        } else if hasMultipleReveals {
            return "eye.fill"
        } else {
            return "lock.open.fill"
        }
    }
    
    private var revealButtonText: String {
        if isUrgent {
            return "⏰ REVEAL NOW - Expires in 1h - $1.99"
        } else if hasMultipleReveals {
            return "👀 \(gossip.revealedBy.count) people revealed - $1.99"
        } else if isMentioned {
            return "🚨 WHO SAID THIS ABOUT YOU? - $1.99"
        } else {
            return "Reveal Sender - $1.99"
        }
    }
    
    private var revealButtonFont: Font {
        if isUrgent || isMentioned {
            return .caption.bold()
        } else {
            return .caption
        }
    }
    
    private var revealButtonBackground: some View {
        Group {
            if isUrgent {
                LinearGradient(
                    colors: [.red, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if hasMultipleReveals {
                LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else if isMentioned {
                Color.red
            } else {
                Color.white.opacity(0.1)
            }
        }
    }
}

// MARK: - Empty State
struct EmptyGossipView: View {
    let onPost: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("☕")
                .font(.system(size: 80))
            
            Text("No Gossip Yet")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("Be the first to spill the tea!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: onPost) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Post Anonymous Gossip")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Gossip Composer
struct GossipComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var friendsManager: FriendsManager
    @StateObject private var gossipManager = GossipManager.shared
    
    @State private var gossipText = ""
    @State private var isPosting = false
    
    private let maxCharacters = 280
    
    private var detectedMentions: [User] {
        gossipManager.detectMentions(in: gossipText, from: friendsManager.friends)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Text editor
                        ZStack(alignment: .topLeading) {
                            if gossipText.isEmpty {
                                Text("What's the tea? ☕\n\nMention friends with @username")
                                    .foregroundColor(.gray)
                                    .padding(8)
                            }
                            
                            TextEditor(text: $gossipText)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 200)
                                .padding(4)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                        
                        // Character count
                        HStack {
                            Text("\(gossipText.count)/\(maxCharacters)")
                                .font(.caption)
                                .foregroundColor(gossipText.count > maxCharacters ? .red : .gray)
                            
                            Spacer()
                            
                            if !detectedMentions.isEmpty {
                                Text("Mentioning: \(detectedMentions.map { "@" + $0.username }.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        // Tips
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💡 Tips:")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                            
                            Text("• Your identity is hidden (anonymous)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Mention friends with @username")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• They can pay $1.99 to reveal who posted")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("• Gossip expires in 24 hours")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.yellow.opacity(0.1))
                        )
                        
                        // Post button
                        Button(action: postGossip) {
                            if isPosting {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text("Post Anonymously")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canPost ? Color.yellow : Color.gray)
                        .cornerRadius(12)
                        .disabled(!canPost || isPosting)
                    }
                    .padding()
                }
            }
            .navigationTitle("☕ New Gossip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private var canPost: Bool {
        !gossipText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        gossipText.count <= maxCharacters
    }
    
    private func postGossip() {
        guard let currentUser = authManager.currentUser, canPost else { return }
        
        isPosting = true
        
        Task {
            await gossipManager.postGossip(
                text: gossipText,
                poster: currentUser,
                mentionedFriends: detectedMentions
            )
            
            await MainActor.run {
                isPosting = false
                dismiss()
            }
        }
    }
}

// MARK: - Reply Thread View
struct ReplyThreadView: View {
    let gossipID: String
    let currentUser: User
    let onClose: () -> Void
    
    @StateObject private var gossipManager = GossipManager.shared
    @State private var replies: [GossipReply] = []
    @State private var replyText = ""
    @State private var isPostingReply = false
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("💬 Replies")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Replies list
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding()
            } else if replies.isEmpty {
                VStack(spacing: 8) {
                    Text("👻")
                        .font(.system(size: 40))
                    Text("No replies yet")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Be the first to reply!")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(replies) { reply in
                            ReplyCard(reply: reply)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
            
            // Reply composer
            HStack(spacing: 12) {
                TextField("Write a reply...", text: $replyText, axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                
                Button(action: postReply) {
                    if isPostingReply {
                        ProgressView()
                            .tint(.purple)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(canPostReply ? .purple : .gray)
                    }
                }
                .disabled(!canPostReply || isPostingReply)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .task {
            await loadReplies()
        }
    }
    
    private var canPostReply: Bool {
        !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func loadReplies() async {
        isLoading = true
        replies = await gossipManager.loadReplies(for: gossipID)
        isLoading = false
    }
    
    private func postReply() {
        guard canPostReply else { return }
        
        isPostingReply = true
        let textToPost = replyText
        replyText = ""
        
        Task {
            await gossipManager.postReply(
                to: gossipID,
                replyText: textToPost,
                replier: currentUser,
                isAnonymous: true
            )
            
            // Reload replies
            await loadReplies()
            
            await MainActor.run {
                isPostingReply = false
            }
        }
    }
}

// MARK: - Reply Card
struct ReplyCard: View {
    let reply: GossipReply
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: reply.isAnonymous ? "person.fill.questionmark" : "person.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(reply.isAnonymous ? "Anonymous" : reply.replierUsername)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    
                    Text(reply.createdAt.timeAgoString())
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Text(reply.replyText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
            
            Text(message)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.2))
                .background(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// Preview removed - use simulator to test (managers don't have .shared instances)

