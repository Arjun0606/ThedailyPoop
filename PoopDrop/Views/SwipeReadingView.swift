import SwiftUI

struct SwipeReadingView: View {
    let stories: [Story]
    @Binding var readStoryIDs: Set<String>
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var audioManager = AudioBriefingManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0

    private var progress: CGFloat {
        guard !stories.isEmpty else { return 0 }
        return CGFloat(currentIndex + 1) / CGFloat(stories.count)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                    SwipeCardContent(
                        story: story,
                        isLocked: !story.isFree && !(authManager.currentUser?.isPremium ?? false),
                        isRead: readStoryIDs.contains(story.id),
                        index: index,
                        total: stories.count
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentIndex) { _, newIndex in
                markAsRead(index: newIndex)
                if audioManager.isPlaying {
                    audioManager.jumpToStory(at: newIndex)
                }
            }

            // Top bar
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Segmented progress bar
                    HStack(spacing: 3) {
                        ForEach(0..<stories.count, id: \.self) { i in
                            Capsule()
                                .fill(
                                    i < currentIndex ? Theme.accent :
                                    i == currentIndex ? Color.white :
                                    Color.white.opacity(0.15)
                                )
                                .frame(height: 3)
                                .animation(.spring(response: 0.3), value: currentIndex)
                        }
                    }

                    // Counter
                    Text("\(currentIndex + 1)/\(stories.count)")
                        .font(.system(size: 12, weight: .bold).monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 36)

                    // Close
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial.opacity(0.5))
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.9), location: 0),
                            .init(color: .black.opacity(0.5), location: 0.7),
                            .init(color: .clear, location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                )

                Spacer()
            }
        }
        .onAppear {
            markAsRead(index: 0)
        }
    }

    private func markAsRead(index: Int) {
        guard index < stories.count,
              let user = authManager.currentUser else { return }
        let story = stories[index]

        if story.isFree || user.isPremium {
            readStoryIDs.insert(story.id)
            LiveActivityManager.shared.updateReadProgress(readCount: readStoryIDs.count)
            Task {
                try? await SupabaseManager.shared.markStoryRead(userID: user.id, storyID: story.id)
                try? await SupabaseManager.shared.pingReaderLocation(
                    userId: user.id,
                    storyId: story.id,
                    username: user.username,
                    storyHeadline: story.headline
                )
            }
        }
    }
}

// MARK: - Swipe Card Content
struct SwipeCardContent: View {
    let story: Story
    let isLocked: Bool
    let isRead: Bool
    let index: Int
    let total: Int

    private var catColor: Color {
        Theme.categoryColor(for: story.category)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Spacer(minLength: 50)

                // Category + index
                HStack {
                    CategoryPill(category: story.category, emoji: story.categoryEmoji)

                    Spacer()

                    if isRead {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                            Text("Read")
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(.green.opacity(0.7))
                    }
                }

                // Headline
                Text(story.headline)
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)

                // Meta row
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("\(story.readingTimeMinutes) min read")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(Theme.textTertiary)

                    if let source = story.sourceName {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 10))
                            Text(source)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(Theme.textTertiary)
                    }
                }

                if isLocked {
                    // Locked premium state
                    VStack(spacing: 20) {
                        Spacer(minLength: 30)

                        ZStack {
                            Circle()
                                .fill(Theme.accent.opacity(0.1))
                                .frame(width: 80, height: 80)

                            Image(systemName: "lock.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Theme.accent)
                        }

                        VStack(spacing: 8) {
                            Text("Premium Story")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)

                            Text("Upgrade to unlock all stories")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }

                        Spacer(minLength: 30)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // Body (with signature elements styled)
                    StoryBodyView(storyText: story.bodyWithoutBottomLine, catColor: catColor)

                    // The Bottom Line — signature element
                    if let bottomLine = story.bottomLine {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Rectangle()
                                    .fill(Theme.accent)
                                    .frame(width: 3, height: 16)
                                    .clipShape(Capsule())
                                Text("THE BOTTOM LINE")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(Theme.accent)
                                    .tracking(2)
                            }

                            Text(bottomLine)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.accent.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
                        )
                    }

                    // TLDR card
                    if let tldr = story.tldr {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Text("TLDR")
                                    .font(.system(size: 11, weight: .heavy))
                                    .tracking(1.5)
                                    .foregroundStyle(catColor)
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(catColor.opacity(0.3))
                                    .frame(height: 1)
                            }

                            Text(tldr)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .italic()
                                .lineSpacing(3)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(catColor.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(catColor.opacity(0.15), lineWidth: 0.5)
                        )
                    }

                    // Source link
                    if let source = story.sourceName {
                        if let sourceUrl = story.sourceUrl, let url = URL(string: sourceUrl) {
                            Link(destination: url) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.up.right.square.fill")
                                        .font(.caption)
                                    Text("Read on \(source)")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(catColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(catColor.opacity(0.08))
                                .clipShape(Capsule())
                            }
                        }
                    }

                    // Reactions, share, bookmark
                    SwipeEngagementBar(story: story, catColor: catColor)

                    // Swipe hint
                    if index < total - 1 {
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Text("Swipe for next")
                                    .font(.caption2.weight(.medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.04))
                            .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    }

                    // "You're all caught up" on last story
                    if index == total - 1 {
                        HStack {
                            Spacer()
                            VStack(spacing: 6) {
                                Text("You're all caught up")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.textSecondary)
                                Text("That's all \(total) stories")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    }
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Swipe Engagement Bar (reactions + share + bookmark)
struct SwipeEngagementBar: View {
    let story: Story
    let catColor: Color
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var userReaction: String?
    @State private var isBookmarked = false
    @State private var showingShareCard = false
    @State private var comments: [StoryComment] = []
    @State private var commentText = ""
    @State private var isPostingComment = false
    @State private var showAllComments = false

    private let quickReactions = ["\u{1F525}", "\u{1F480}", "\u{1F602}", "\u{1F92F}", "\u{1F4A9}", "\u{1F921}"]

    var body: some View {
        VStack(spacing: 14) {
            // Quick reaction row
            HStack(spacing: 0) {
                ForEach(quickReactions, id: \.self) { emoji in
                    Button {
                        handleReaction(emoji)
                    } label: {
                        Text(emoji)
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                userReaction == emoji
                                    ? catColor.opacity(0.15)
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 0.5)
            )

            // Share + Bookmark row
            HStack(spacing: 10) {
                ShareLink(
                    item: "\(story.headline)\n\n\(story.bottomLine ?? story.tldr ?? story.headline)\n\n\u{2014} TheDailyPoop | thedailypoop.app",
                    subject: Text(story.headline),
                    message: Text(story.bottomLine ?? story.tldr ?? story.headline)
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if story.bottomLine != nil || story.tldr != nil {
                    Button { showingShareCard = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "photo")
                            Text("Card")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.elevatedBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.cardBorder, lineWidth: 0.5)
                        )
                    }
                }

                Button {
                    toggleBookmark()
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundStyle(isBookmarked ? catColor : Theme.textTertiary)
                        .symbolEffect(.bounce, value: isBookmarked)
                        .frame(width: 48, height: 44)
                        .background(Theme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.cardBorder, lineWidth: 0.5)
                        )
                }
            }

            // Comments section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("COMMENTS")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)

                    Spacer()

                    if comments.count > 3 {
                        Button {
                            showAllComments.toggle()
                        } label: {
                            Text(showAllComments ? "Show less" : "See all \(comments.count)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(catColor)
                        }
                    }
                }

                // Comment input
                if authManager.currentUser != nil {
                    HStack(spacing: 10) {
                        TextField("Add a comment...", text: $commentText)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .textFieldStyle(.plain)

                        Button {
                            postComment()
                        } label: {
                            if isPostingComment {
                                ProgressView()
                                    .tint(catColor)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(
                                        commentText.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? Theme.textTertiary
                                        : catColor
                                    )
                            }
                        }
                        .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty || isPostingComment)
                    }
                    .padding(12)
                    .background(Theme.elevatedBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 0.5)
                    )
                }

                // Comments list
                let visibleComments = showAllComments ? comments : Array(comments.prefix(3))
                ForEach(visibleComments) { comment in
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("@\(comment.username)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(catColor)

                                Text(relativeTime(comment.createdAt))
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textTertiary)
                            }

                            Text(comment.text)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button {
                            guard let user = authManager.currentUser else { return }
                            Task {
                                try? await SupabaseManager.shared.upvoteComment(
                                    userId: user.id, commentId: comment.id
                                )
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 10, weight: .bold))
                                if comment.upvotes > 0 {
                                    Text("\(comment.upvotes)")
                                        .font(.system(size: 9, weight: .bold).monospacedDigit())
                                }
                            }
                            .foregroundStyle(Theme.textTertiary)
                            .frame(width: 28)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(Theme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                if comments.isEmpty {
                    Text("Be the first to comment")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
        }
        .task { await loadState() }
        .sheet(isPresented: $showingShareCard) {
            ShareCardSheet(story: story)
        }
    }

    private func loadState() async {
        guard let user = authManager.currentUser else { return }
        userReaction = try? await SupabaseManager.shared.fetchUserReaction(userId: user.id, storyId: story.id)
        isBookmarked = (try? await SupabaseManager.shared.isBookmarked(userId: user.id, storyId: story.id)) ?? false
        comments = (try? await SupabaseManager.shared.fetchComments(storyId: story.id)) ?? []
    }

    private func handleReaction(_ emoji: String) {
        guard let user = authManager.currentUser else { return }
        let impact = UIImpactFeedbackGenerator(style: userReaction == emoji ? .light : .medium)
        impact.impactOccurred()

        if userReaction == emoji {
            userReaction = nil
        } else {
            userReaction = emoji
        }

        Task {
            try? await SupabaseManager.shared.toggleReaction(userId: user.id, storyId: story.id, reaction: emoji)
        }
    }

    private func toggleBookmark() {
        guard let user = authManager.currentUser else { return }
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(isBookmarked ? .warning : .success)
        isBookmarked.toggle()

        Task {
            let result = try? await SupabaseManager.shared.toggleBookmark(userId: user.id, storyId: story.id)
            if let result { isBookmarked = result }
        }
    }

    private func postComment() {
        guard let user = authManager.currentUser else { return }
        let text = commentText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        isPostingComment = true

        Task {
            do {
                try await SupabaseManager.shared.postComment(userId: user.id, storyId: story.id, text: text)
                comments = try await SupabaseManager.shared.fetchComments(storyId: story.id)
                commentText = ""
            } catch {
                print("Post comment error: \(error)")
            }
            isPostingComment = false
        }
    }

    private func relativeTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "" }
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(Int(diff / 60))m" }
        if diff < 86400 { return "\(Int(diff / 3600))h" }
        return "\(Int(diff / 86400))d"
    }
}
