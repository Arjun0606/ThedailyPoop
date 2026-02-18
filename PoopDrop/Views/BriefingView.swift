import SwiftUI
import WidgetKit

struct BriefingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var audioManager = AudioBriefingManager.shared
    @State private var briefing: Briefing?
    @State private var stories: [Story] = []
    @State private var readStoryIDs: Set<String> = []
    @State private var isLoading = true
    @State private var showingPaywall = false
    @State private var selectedStory: Story?
    @State private var showingSwipeMode = false
    @State private var storyReactionCounts: [String: Int] = [:]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(.white)
                        Text("Loading your briefing...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let briefing = briefing {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Hero Header
                            BriefingHeaderView(briefing: briefing)

                            // Stories
                            ForEach(stories) { story in
                                StoryCardView(
                                    story: story,
                                    isPremiumUser: authManager.currentUser?.isPremium ?? false,
                                    isRead: readStoryIDs.contains(story.id),
                                    totalReactions: storyReactionCounts[story.id] ?? 0,
                                    onTap: {
                                        handleStoryTap(story)
                                    }
                                )

                                if story.id != stories.last?.id {
                                    Divider()
                                        .background(Color.white.opacity(0.06))
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .refreshable { await loadBriefing() }
                } else {
                    NoBriefingView()
                }
            }
            .navigationTitle("TheDailyPoop")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Swipe mode
                        if !stories.isEmpty {
                            Button {
                                showingSwipeMode = true
                            } label: {
                                Image(systemName: "rectangle.stack")
                                    .foregroundStyle(.white)
                            }
                        }

                        // Audio
                        if !stories.isEmpty {
                            Button {
                                if audioManager.isPlaying {
                                    audioManager.togglePlayPause()
                                } else {
                                    let playable = stories.filter { $0.isFree || (authManager.currentUser?.isPremium ?? false) }
                                    audioManager.startBriefing(stories: playable)
                                }
                            } label: {
                                Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "headphones")
                                    .foregroundStyle(audioManager.isPlaying ? .brown : .white)
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if audioManager.isPlaying || audioManager.progress > 0 {
                    AudioPlayerBar(stories: stories)
                        .environmentObject(audioManager)
                }
            }
        }
        .task { await loadBriefing() }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(item: $selectedStory) { story in
            StoryDetailView(story: story)
                .environmentObject(authManager)
        }
        .fullScreenCover(isPresented: $showingSwipeMode) {
            SwipeReadingView(stories: stories, readStoryIDs: $readStoryIDs)
                .environmentObject(authManager)
        }
    }

    private func loadBriefing() async {
        guard let user = authManager.currentUser else { return }
        do {
            if let b = try await SupabaseManager.shared.fetchTodayBriefing() {
                briefing = b
                stories = try await SupabaseManager.shared.fetchBriefingStories(briefingId: b.id)
                readStoryIDs = try await SupabaseManager.shared.fetchReadStoryIDs(userID: user.id, briefingId: b.id)
                storyReactionCounts = (try? await SupabaseManager.shared.fetchBulkReactionCounts(storyIds: stories.map { $0.id })) ?? [:]
                updateWidgetData(briefing: b, stories: stories)
            }
        } catch {
            print("Briefing load error: \(error)")
        }
        isLoading = false
    }

    private func updateWidgetData(briefing: Briefing, stories: [Story]) {
        guard let defaults = UserDefaults(suiteName: "group.com.thedailypoop.app") else { return }
        defaults.set(briefing.headline, forKey: "widget_headline")
        defaults.set(briefing.storyCount, forKey: "widget_story_count")

        let storiesData = stories.prefix(3).map { story -> [String: String] in
            ["emoji": story.categoryEmoji, "headline": story.headline]
        }
        defaults.set(storiesData, forKey: "widget_stories")

        // Tell WidgetKit to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func handleStoryTap(_ story: Story) {
        let isPremiumUser = authManager.currentUser?.isPremium ?? false

        if !story.isFree && !isPremiumUser {
            showingPaywall = true
            return
        }

        selectedStory = story

        // Mark as read + ping globe
        if let user = authManager.currentUser {
            Task {
                try? await SupabaseManager.shared.markStoryRead(userID: user.id, storyID: story.id)
                readStoryIDs.insert(story.id)

                // Fire reader location ping for live globe (fire-and-forget)
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

// MARK: - Briefing Header
struct BriefingHeaderView: View {
    let briefing: Briefing

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY'S BRIEFING")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.brown)
                    .tracking(1.5)

                Spacer()

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(briefing.headline)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            if let intro = briefing.introText {
                Text(intro)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 16) {
                Label("\(briefing.storyCount) stories", systemImage: "newspaper")
                Label("\(briefing.freeStoryCount) free", systemImage: "lock.open")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Listen button
            HStack(spacing: 10) {
                Image(systemName: "headphones")
                    .font(.caption.weight(.semibold))
                Text("Listen to Briefing")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.brown)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.brown.opacity(0.15))
            .cornerRadius(20)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.brown.opacity(0.15), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: briefing.publishDate) {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
        return briefing.publishDate
    }
}

// MARK: - No Briefing
struct NoBriefingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("💩")
                .font(.system(size: 80))

            Text("No Briefing Yet")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Today's briefing hasn't been published yet. Check back soon!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Story Detail View
struct StoryDetailView: View {
    let story: Story
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var reactionCounts: [String: Int] = [:]
    @State private var userReaction: String?
    @State private var isBookmarked = false
    @State private var showingShareCard = false

    private let reactions: [(key: String, emoji: String)] = [
        ("fire", "\u{1F525}"), ("skull", "\u{1F480}"), ("laugh", "\u{1F602}"), ("mindblown", "\u{1F92F}")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Category pill + reading time
                        HStack {
                            Text("\(story.categoryEmoji) \(story.categoryLabel)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(20)

                            Spacer()

                            Label("\(story.readingTimeMinutes) min read", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Hero image
                        if let imageUrl = story.imageUrl, let url = URL(string: imageUrl) {
                            VStack(alignment: .trailing, spacing: 4) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(maxHeight: 200)
                                            .clipped()
                                            .cornerRadius(12)
                                    case .failure:
                                        EmptyView()
                                    default:
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                            .frame(height: 200)
                                            .overlay(ProgressView().tint(.secondary))
                                    }
                                }

                                if let source = story.sourceName {
                                    Text("Image: \(source)")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }
                        }

                        // Headline
                        Text(story.headline)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        // Body
                        Text(story.body)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)

                        // TLDR
                        if let tldr = story.tldr {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TLDR")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.brown)
                                    .tracking(1)

                                Text(tldr)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                                    .italic()
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }

                        // Reactions bar
                        VStack(spacing: 8) {
                            HStack(spacing: 0) {
                                ForEach(reactions, id: \.key) { reaction in
                                    Button {
                                        handleReaction(reaction.key)
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(reaction.emoji)
                                                .font(.title2)
                                            Text("\(reactionCounts[reaction.key] ?? 0)")
                                                .font(.caption2.weight(.medium))
                                                .foregroundStyle(userReaction == reaction.key ? .white : .secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            userReaction == reaction.key
                                                ? Color.white.opacity(0.12)
                                                : Color.clear
                                        )
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(4)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(14)
                        }

                        // Source + bookmark row
                        HStack {
                            if let sourceName = story.sourceName {
                                if let sourceUrl = story.sourceUrl, let url = URL(string: sourceUrl) {
                                    Link(destination: url) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.up.right.square")
                                                .font(.caption)
                                            Text(sourceName)
                                                .font(.caption.weight(.medium))
                                        }
                                        .foregroundStyle(.blue.opacity(0.8))
                                    }
                                } else {
                                    HStack(spacing: 6) {
                                        Image(systemName: "link")
                                            .font(.caption)
                                        Text("Source: \(sourceName)")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                handleBookmark()
                            } label: {
                                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                    .font(.title3)
                                    .foregroundStyle(isBookmarked ? .brown : .secondary)
                            }
                        }

                        // Action buttons
                        HStack(spacing: 12) {
                            // Share text
                            ShareLink(
                                item: "\(story.headline)\n\nRead more on TheDailyPoop",
                                subject: Text(story.headline),
                                message: Text(story.tldr ?? story.headline)
                            ) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(12)
                            }

                            // Share card
                            if story.bottomLine != nil || story.tldr != nil {
                                Button {
                                    showingShareCard = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "photo")
                                        Text("Card")
                                            .fontWeight(.semibold)
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await loadReactionsAndBookmark() }
        .sheet(isPresented: $showingShareCard) {
            ShareCardSheet(story: story)
        }
    }

    private func loadReactionsAndBookmark() async {
        guard let user = authManager.currentUser else { return }
        do {
            async let counts = SupabaseManager.shared.fetchReactionCounts(storyId: story.id)
            async let reaction = SupabaseManager.shared.fetchUserReaction(userId: user.id, storyId: story.id)
            async let bookmarked = SupabaseManager.shared.isBookmarked(userId: user.id, storyId: story.id)

            reactionCounts = try await counts
            userReaction = try await reaction
            isBookmarked = try await bookmarked
        } catch {
            print("Load reactions error: \(error)")
        }
    }

    private func handleReaction(_ reaction: String) {
        guard let user = authManager.currentUser else { return }
        let wasSelected = userReaction == reaction

        // Haptic
        let impact = UIImpactFeedbackGenerator(style: wasSelected ? .light : .medium)
        impact.impactOccurred()

        // Optimistic update
        if wasSelected {
            reactionCounts[reaction, default: 1] -= 1
            userReaction = nil
        } else {
            if let old = userReaction {
                reactionCounts[old, default: 1] -= 1
            }
            reactionCounts[reaction, default: 0] += 1
            userReaction = reaction
        }

        Task {
            try? await SupabaseManager.shared.toggleReaction(userId: user.id, storyId: story.id, reaction: reaction)
        }
    }

    private func handleBookmark() {
        guard let user = authManager.currentUser else { return }

        // Haptic
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(isBookmarked ? .warning : .success)

        isBookmarked.toggle()

        Task {
            let result = try? await SupabaseManager.shared.toggleBookmark(userId: user.id, storyId: story.id)
            if let result {
                isBookmarked = result
            }
        }
    }
}

// MARK: - Paywall
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color.brown.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    Text("💩")
                        .font(.system(size: 80))

                    Text("Unlock All Stories")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Get full access to all 10 daily stories, the archive, and keep your streak alive.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    VStack(spacing: 12) {
                        FeatureRow(icon: "newspaper.fill", text: "All 10 stories daily")
                        FeatureRow(icon: "archivebox.fill", text: "Full briefing archive")
                        FeatureRow(icon: "flame.fill", text: "Reading streak tracking")
                        FeatureRow(icon: "bell.fill", text: "Priority morning push")
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    VStack(spacing: 12) {
                        Button(action: { /* TODO: RevenueCat purchase */ }) {
                            VStack(spacing: 4) {
                                Text("$7.99/month")
                                    .font(.headline)
                                Text("Cancel anytime")
                                    .font(.caption)
                                    .opacity(0.7)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(14)
                        }

                        Button(action: { /* TODO: RevenueCat purchase */ }) {
                            VStack(spacing: 4) {
                                Text("$59.99/year")
                                    .font(.headline)
                                Text("Save 37%")
                                    .font(.caption)
                                    .opacity(0.7)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(14)
                        }

                        Button("Restore Purchases") {
                            /* TODO: RevenueCat restore */
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.brown)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

// MARK: - Audio Player Bar
struct AudioPlayerBar: View {
    let stories: [Story]
    @EnvironmentObject var audioManager: AudioBriefingManager

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.brown)
                    .frame(width: geo.size.width * audioManager.progress, height: 2)
            }
            .frame(height: 2)

            HStack(spacing: 16) {
                // Story info
                VStack(alignment: .leading, spacing: 2) {
                    if audioManager.currentStoryIndex < stories.count {
                        Text(stories[audioManager.currentStoryIndex].headline)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    Text("Story \(audioManager.currentStoryIndex + 1) of \(stories.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Controls
                HStack(spacing: 20) {
                    Button { audioManager.skipBackward() } label: {
                        Image(systemName: "backward.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }

                    Button { audioManager.togglePlayPause() } label: {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.body)
                            .foregroundStyle(.white)
                    }

                    Button { audioManager.skipForward() } label: {
                        Image(systemName: "forward.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }

                    Button { audioManager.stop() } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }
}

#Preview {
    BriefingView()
        .environmentObject(AuthenticationManager())
}
