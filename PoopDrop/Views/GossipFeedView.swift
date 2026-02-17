import SwiftUI

// MARK: - Gossip Feed (group-scoped, 24h expiry, $1.99 reveals)
struct GossipFeedView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var gossip: [GossipPost] = []
    @State private var groups: [Group] = []
    @State private var selectedGroup: Group?
    @State private var revealedIDs: Set<String> = []       // gossip IDs this user has revealed
    @State private var revealedUsernames: [String: String] = [:] // gossipID → author username

    @State private var isLoading = true
    @State private var showingComposer = false

    // Toast
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var toastIcon = ""

    // Secure reveal
    @State private var showingSecureReveal = false
    @State private var revealedUsername = ""

    // Share after reveal
    @State private var showingRevealShare = false
    @State private var lastRevealedGroupName = ""
    @State private var lastRevealedGroupEmoji = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Group picker
                    if !groups.isEmpty {
                        GroupGossipPicker(
                            selectedGroup: $selectedGroup,
                            groups: groups,
                            onChange: { loadGossip() }
                        )
                    }

                    // Feed
                    if isLoading {
                        Spacer()
                        ProgressView().tint(.white)
                        Spacer()
                    } else if gossip.isEmpty {
                        EmptyGossipView(onPost: { showingComposer = true })
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(gossip) { post in
                                    GossipCard(
                                        post: post,
                                        isRevealed: revealedIDs.contains(post.id),
                                        revealedUsername: revealedUsernames[post.id],
                                        onReveal: { await revealSender(post) },
                                        onShare: { shareGossipTease(post) }
                                    )
                                }
                            }
                            .padding(.vertical)
                            .padding(.bottom, 80)
                        }
                        .refreshable { loadGossip() }
                    }
                }

                // FAB
                if !gossip.isEmpty && !isLoading {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: { showingComposer = true }) {
                                Image(systemName: "plus")
                                    .font(.title2.bold())
                                    .foregroundStyle(.black)
                                    .frame(width: 60, height: 60)
                                    .background(Color.yellow)
                                    .clipShape(Circle())
                                    .shadow(color: .yellow.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 90)
                        }
                    }
                }
            }
            .navigationTitle("☕ Gossip")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingComposer) {
                GossipComposerView(
                    selectedGroup: selectedGroup,
                    groups: groups,
                    onPosted: { loadGossip() }
                )
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
                await loadGroups()
                loadGossip()
            }
            .onAppear { setupScreenshotDetection() }
            .fullScreenCover(isPresented: $showingSecureReveal) {
                SecureRevealView(posterUsername: revealedUsername) {
                    showingSecureReveal = false
                    // Show share prompt after reveal
                    lastRevealedGroupName = selectedGroup?.name ?? ""
                    lastRevealedGroupEmoji = selectedGroup?.emoji ?? "💩"
                    showingRevealShare = true
                }
            }
            .sheet(isPresented: $showingRevealShare) {
                GossipRevealSharePrompt(
                    groupName: lastRevealedGroupName,
                    groupEmoji: lastRevealedGroupEmoji,
                    onShare: {
                        let card = GossipRevealShareCard(
                            groupName: lastRevealedGroupName,
                            groupEmoji: lastRevealedGroupEmoji
                        )
                        if let image = ShareCardGenerator.render(card) {
                            ShareCardGenerator.share(image: image)
                        }
                        showingRevealShare = false
                    },
                    onSkip: {
                        showingRevealShare = false
                        showToast("Revealed! @\(revealedUsername)", icon: "checkmark.circle.fill")
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Data Loading

    private func loadGroups() async {
        guard let user = authManager.currentUser else { return }
        do {
            groups = try await SupabaseManager.shared.fetchMyGroups(userID: user.id)
            if selectedGroup == nil { selectedGroup = groups.first }
        } catch {
            print("Failed to load groups: \(error)")
        }
    }

    private func loadGossip() {
        guard let group = selectedGroup else {
            isLoading = false
            return
        }
        Task {
            do {
                gossip = try await SupabaseManager.shared.fetchGossip(groupID: group.id)
                // Check which ones this user already revealed
                if let user = authManager.currentUser {
                    for post in gossip {
                        if try await SupabaseManager.shared.hasRevealedGossip(
                            gossipID: post.id, userID: user.id
                        ) {
                            revealedIDs.insert(post.id)
                            // Fetch the author username
                            let username = try await SupabaseManager.shared.revealGossip(
                                gossipID: post.id, revealedBy: user.id
                            )
                            revealedUsernames[post.id] = username
                        }
                    }
                }
            } catch {
                print("Failed to load gossip: \(error)")
            }
            isLoading = false
        }
    }

    // MARK: - Reveal

    private func revealSender(_ post: GossipPost) async {
        guard let user = authManager.currentUser else { return }

        // TODO: Integrate RevenueCat purchase ($1.99) before revealing
        // For now, reveal directly for testing
        do {
            let username = try await SupabaseManager.shared.revealGossip(
                gossipID: post.id, revealedBy: user.id
            )
            revealedIDs.insert(post.id)
            revealedUsernames[post.id] = username
            revealedUsername = username
            showingSecureReveal = true
        } catch {
            showToast("Reveal failed. Try again.", icon: "xmark.circle.fill")
        }
    }

    // MARK: - Share Gossip Tease

    private func shareGossipTease(_ post: GossipPost) {
        guard let group = selectedGroup else { return }
        let snippet = String(post.content.prefix(80)) + (post.content.count > 80 ? "..." : "")
        let card = GossipTeaseCard(
            groupName: group.name,
            groupEmoji: group.emoji,
            previewSnippet: snippet
        )
        if let image = ShareCardGenerator.render(card) {
            ShareCardGenerator.share(image: image)
        }
    }

    // MARK: - Screenshot Detection

    private func setupScreenshotDetection() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            showToast("📸 Screenshot detected!", icon: "camera.fill")
        }
    }

    // MARK: - Toast

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

// MARK: - Group Picker (horizontal pills)
struct GroupGossipPicker: View {
    @Binding var selectedGroup: Group?
    let groups: [Group]
    let onChange: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(groups) { group in
                    Button(action: {
                        selectedGroup = group
                        onChange()
                    }) {
                        HStack(spacing: 6) {
                            Text(group.emoji)
                            Text(group.name)
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(selectedGroup?.id == group.id ? .black : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedGroup?.id == group.id ? Color.yellow : Color.white.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Gossip Card
struct GossipCard: View {
    let post: GossipPost
    let isRevealed: Bool
    let revealedUsername: String?
    let onReveal: () async -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Circle()
                    .fill(isRevealed ? Color.purple : Color.gray)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: isRevealed ? "person.fill" : "person.fill.questionmark")
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(isRevealed ? "@\(revealedUsername ?? "unknown")" : "Anonymous")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(post.createdAt.timeAgoString())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Share button
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Expiry badge
                if post.expiresAt.timeIntervalSinceNow < 3600 {
                    Text("⏰ <1h left")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            // Content
            Text(post.content)
                .font(.body)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            // Reveal / Revealed state
            if isRevealed {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Posted by @\(revealedUsername ?? "unknown")")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 4)

                    // View their drops on map
                    Button(action: {
                        NotificationCenter.default.post(
                            name: Notification.Name("SHOW_DROP_FROM_GOSSIP"),
                            object: nil,
                            userInfo: ["username": revealedUsername ?? ""]
                        )
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "map.fill").font(.subheadline)
                            Text("View @\(revealedUsername ?? "")'s drops")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    }
                }
            } else {
                // Reveal button
                Button(action: { Task { await onReveal() } }) {
                    HStack {
                        Image(systemName: revealIcon)
                        Text(revealText)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(revealBackground)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal)
    }

    // MARK: - Reveal Button Styling

    private var isUrgent: Bool {
        post.expiresAt.timeIntervalSinceNow < 3600
    }

    private var revealIcon: String {
        isUrgent ? "clock.fill" : "lock.open.fill"
    }

    private var revealText: String {
        isUrgent
            ? "⏰ REVEAL NOW — Expires soon — $1.99"
            : "Reveal Sender — $1.99"
    }

    @ViewBuilder
    private var revealBackground: some View {
        if isUrgent {
            LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
        } else {
            Color.white.opacity(0.1)
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
                .foregroundStyle(.white)

            Text("Be the first to spill the tea!")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onPost) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Post Anonymous Gossip")
                }
                .font(.headline)
                .foregroundStyle(.black)
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
    let selectedGroup: Group?
    let groups: [Group]
    let onPosted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var gossipText = ""
    @State private var composerGroup: Group?
    @State private var isPosting = false

    private let maxChars = 280

    private var canPost: Bool {
        !gossipText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && gossipText.count <= maxChars
        && composerGroup != nil
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Group selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Post in Group")
                                .font(.headline)
                                .foregroundStyle(.white)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(groups) { group in
                                        Button(action: { composerGroup = group }) {
                                            HStack(spacing: 6) {
                                                Text(group.emoji)
                                                Text(group.name)
                                                    .font(.subheadline.weight(.medium))
                                            }
                                            .foregroundStyle(composerGroup?.id == group.id ? .black : .white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(composerGroup?.id == group.id ? Color.yellow : Color.white.opacity(0.1))
                                            .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }

                        // Text editor
                        ZStack(alignment: .topLeading) {
                            if gossipText.isEmpty {
                                Text("What's the tea? ☕")
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                            }

                            TextEditor(text: $gossipText)
                                .foregroundStyle(.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 200)
                                .padding(4)
                                .onChange(of: gossipText) { _, newValue in
                                    if newValue.count > maxChars {
                                        gossipText = String(newValue.prefix(maxChars))
                                    }
                                }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )

                        // Char count
                        HStack {
                            Text("\(gossipText.count)/\(maxChars)")
                                .font(.caption)
                                .foregroundStyle(gossipText.count > maxChars ? .red : .secondary)
                            Spacer()
                        }

                        // Tips
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💡 Tips:")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                            Text("• Your identity is hidden (anonymous)")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("• Others can pay $1.99 to reveal who posted")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("• Gossip expires in 24 hours")
                                .font(.caption).foregroundStyle(.secondary)
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
                                ProgressView().tint(.black)
                            } else {
                                Text("Post Anonymously")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(.black)
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
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            composerGroup = selectedGroup ?? groups.first
        }
    }

    private func postGossip() {
        guard let user = authManager.currentUser,
              let group = composerGroup, canPost else { return }
        isPosting = true

        Task {
            do {
                try await SupabaseManager.shared.postGossip(
                    authorID: user.id,
                    groupID: group.id,
                    content: gossipText
                )
                onPosted()
                dismiss()
            } catch {
                print("Failed to post gossip: \(error)")
            }
            isPosting = false
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
            Text(message)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.2))
                .background(.ultraThinMaterial)
        )
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    GossipFeedView()
        .environmentObject(AuthenticationManager())
}
