import SwiftUI

struct GossipFeedView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var friendsManager: FriendsManager
    @StateObject private var gossipManager = GossipManager.shared
    @StateObject private var storeKitManager = StoreKitManager.shared
    
    @State private var showingComposer = false
    @State private var showingRevealed: Set<String> = []
    
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
                        }
                        .refreshable {
                            await gossipManager.loadTodaysGossip()
                        }
                    }
                    
                    // Compose Button
                    Button(action: { showingComposer = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Post Anonymous Gossip")
                                .font(.headline)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("☕ Gossip")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingComposer) {
                GossipComposerView()
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
        
        // Purchase reveal IAP (using existing pollReveal product ID)
        do {
            if let product = storeKitManager.getProduct(byID: IAPProducts.pollReveal) {
                try await storeKitManager.purchase(product)
                
                // After successful purchase, reveal the sender
                let (revealed, sender) = await gossipManager.revealSender(
                    gossipID: gossip.id,
                    currentUser: currentUser
                )
                
                if revealed {
                    showingRevealed.insert(gossip.id)
                    print("✅ Revealed sender: \(sender ?? "unknown")")
                }
            }
        } catch {
            print("❌ Purchase failed: \(error)")
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
                
                // Reply button (commented out for Phase 1)
                /*
                Button(action: { showingReplies.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("Reply")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                */
                
                Spacer()
            }
            
            // Reveal button
            if !isRevealed {
                Button(action: { Task { await onReveal() }}) {
                    HStack {
                        Image(systemName: isMentioned ? "exclamationmark.circle.fill" : "lock.open.fill")
                        Text(isMentioned ? "🚨 WHO SAID THIS? - $1.99" : "Reveal Sender - $1.99")
                    }
                    .font(isMentioned ? .caption.bold() : .caption)
                    .foregroundColor(isMentioned ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isMentioned ? Color.red : Color.white.opacity(0.1))
                    .cornerRadius(8)
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
                    
                    Spacer()
                    
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

#Preview {
    GossipFeedView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(FriendsManager.shared)
}

