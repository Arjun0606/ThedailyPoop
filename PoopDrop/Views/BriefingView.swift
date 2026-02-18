import SwiftUI
import WidgetKit

struct BriefingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var audioManager = AudioBriefingManager.shared
    @State private var drops: [BriefingDrop] = []
    @State private var readStoryIDs: Set<String> = []
    @State private var isLoading = true
    @State private var showingPaywall = false
    @State private var selectedStory: Story?
    @State private var showingSwipeMode = false
    @State private var storyReactionCounts: [String: Int] = [:]
    @State private var wordGames: [WordGame] = []
    @State private var selectedWordGame: WordGame?

    private var allStories: [Story] {
        drops.flatMap { $0.stories }
    }

    private var totalStories: Int { allStories.count }
    private var readCount: Int { allStories.filter { readStoryIDs.contains($0.id) }.count }
    private var readProgress: Double {
        totalStories > 0 ? Double(readCount) / Double(totalStories) : 0
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                loadingView
            } else if !drops.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(drops) { drop in
                            DropHeaderView(
                                briefing: drop.briefing,
                                isFirst: drop.id == drops.first?.id,
                                readCount: drop.stories.filter { readStoryIDs.contains($0.id) }.count,
                                totalCount: drop.stories.count
                            )

                            // Word Drop challenge card
                            if let game = wordGames.first(where: { $0.dropType == drop.briefing.dropType }) {
                                WordDropCardView(
                                    game: game,
                                    isPremium: authManager.currentUser?.isPremium ?? false,
                                    onPlay: { selectedWordGame = game },
                                    onUpgrade: { showingPaywall = true }
                                )
                                .padding(.horizontal, Theme.pagePadding)
                                .padding(.vertical, 8)
                            }

                            ForEach(drop.stories) { story in
                                StoryCardView(
                                    story: story,
                                    isPremiumUser: authManager.currentUser?.isPremium ?? false,
                                    isRead: readStoryIDs.contains(story.id),
                                    totalReactions: storyReactionCounts[story.id] ?? 0,
                                    onTap: { handleStoryTap(story) }
                                )
                            }

                            if drop.id != drops.last?.id {
                                DropDivider()
                            }
                        }

                        Spacer(minLength: 120)
                    }
                }
                .refreshable { await loadBriefing() }
            } else {
                NoBriefingView()
            }
        }
        .safeAreaInset(edge: .top) {
            topBar
        }
        .safeAreaInset(edge: .bottom) {
            if audioManager.isPlaying || audioManager.progress > 0 {
                AudioPlayerBar(stories: allStories)
                    .environmentObject(audioManager)
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
            SwipeReadingView(stories: allStories, readStoryIDs: $readStoryIDs)
                .environmentObject(authManager)
        }
        .fullScreenCover(item: $selectedWordGame) { game in
            WordDropGameView(game: game)
                .environmentObject(authManager)
                .onDisappear {
                    Task {
                        if let user = authManager.currentUser {
                            wordGames = (try? await SupabaseManager.shared.fetchTodayGames(userId: user.id)) ?? wordGames
                        }
                    }
                }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TheDailyPoop")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                Text(formattedToday)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            if !allStories.isEmpty {
                // Reading progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: readProgress)
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5), value: readProgress)
                    Text("\(readCount)")
                        .font(.system(size: 11, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                }
                .frame(width: 32, height: 32)

                // Swipe mode
                Button {
                    showingSwipeMode = true
                } label: {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 36, height: 36)
                        .background(Theme.cardBg)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.cardBorder, lineWidth: 0.5))
                }

                // Audio
                Button {
                    if audioManager.isPlaying {
                        audioManager.togglePlayPause()
                    } else {
                        let playable = allStories.filter { $0.isFree || (authManager.currentUser?.isPremium ?? false) }
                        audioManager.startBriefing(stories: playable)
                    }
                } label: {
                    Image(systemName: audioManager.isPlaying ? "pause.fill" : "headphones")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(audioManager.isPlaying ? Theme.accent : .white.opacity(0.7))
                        .frame(width: 36, height: 36)
                        .background(audioManager.isPlaying ? Theme.accentDim : Theme.cardBg)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(audioManager.isPlaying ? Theme.accent.opacity(0.3) : Theme.cardBorder, lineWidth: 0.5))
                }
            }
        }
        .padding(.horizontal, Theme.pagePadding)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Rectangle().fill(Color.black.opacity(0.6)))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5)
                }
        )
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 3)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
            }
            Text("Loading your briefing...")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var formattedToday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Data
    private func loadBriefing() async {
        guard let user = authManager.currentUser else { return }
        do {
            let fetchedDrops = try await SupabaseManager.shared.fetchTodayDrops()
            drops = fetchedDrops

            // Load word games
            wordGames = (try? await SupabaseManager.shared.fetchTodayGames(userId: user.id)) ?? []

            if !fetchedDrops.isEmpty {
                let briefingIds = fetchedDrops.map { $0.briefing.id }
                readStoryIDs = try await SupabaseManager.shared.fetchReadStoryIDs(userID: user.id, briefingIds: briefingIds)

                let allIds = fetchedDrops.flatMap { $0.stories.map { $0.id } }
                storyReactionCounts = (try? await SupabaseManager.shared.fetchBulkReactionCounts(storyIds: allIds)) ?? [:]

                if let morningDrop = fetchedDrops.first {
                    updateWidgetData(briefing: morningDrop.briefing, stories: morningDrop.stories)
                }
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
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func handleStoryTap(_ story: Story) {
        let isPremiumUser = authManager.currentUser?.isPremium ?? false

        if !story.isFree && !isPremiumUser {
            showingPaywall = true
            return
        }

        selectedStory = story

        if let user = authManager.currentUser {
            Task {
                try? await SupabaseManager.shared.markStoryRead(userID: user.id, storyID: story.id)
                readStoryIDs.insert(story.id)

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

// MARK: - Drop Header
struct DropHeaderView: View {
    let briefing: Briefing
    let isFirst: Bool
    var readCount: Int = 0
    var totalCount: Int = 0

    private var dropColor: Color {
        Theme.dropColor(for: briefing.dropType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Drop type label + progress
            HStack {
                HStack(spacing: 6) {
                    Text(briefing.dropEmoji)
                        .font(.caption)
                    Text(briefing.dropLabel)
                        .font(.caption.weight(.black))
                        .tracking(1.5)
                }
                .foregroundStyle(dropColor)

                Spacer()

                if totalCount > 0 {
                    Text("\(readCount)/\(totalCount) read")
                        .font(.caption2.weight(.medium).monospacedDigit())
                        .foregroundStyle(Theme.textTertiary)
                }

                if isFirst {
                    Text(formattedDate)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            // Headline
            Text(briefing.headline)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            // Intro
            if let intro = briefing.introText {
                Text(intro)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
        }
        .padding(Theme.pagePadding)
        .padding(.top, isFirst ? 8 : 0)
        .background(
            LinearGradient(
                colors: [dropColor.opacity(0.1), Color.clear],
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

// MARK: - Drop Divider
struct DropDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(
                    LinearGradient(colors: [.clear, Theme.cardBorder], startPoint: .leading, endPoint: .trailing)
                )
                .frame(height: 0.5)
            Text("NEW DROP")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(Theme.textTertiary)
                .tracking(3)
            Rectangle()
                .fill(
                    LinearGradient(colors: [Theme.cardBorder, .clear], startPoint: .leading, endPoint: .trailing)
                )
                .frame(height: 0.5)
        }
        .padding(.horizontal, Theme.pagePadding)
        .padding(.vertical, 28)
    }
}

// MARK: - No Briefing
struct NoBriefingView: View {
    @State private var pulse = false
    @State private var countdown = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var nextDropTime: Date {
        let cal = Calendar.current
        let now = Date()
        let dropHours = [7, 12, 17]
        for hour in dropHours {
            if let candidate = cal.date(bySettingHour: hour, minute: 0, second: 0, of: now),
               candidate > now {
                return candidate
            }
        }
        let tomorrow = cal.date(byAdding: .day, value: 1, to: now)!
        return cal.date(bySettingHour: 7, minute: 0, second: 0, of: tomorrow)!
    }

    private func updateCountdown() {
        let diff = nextDropTime.timeIntervalSince(Date())
        if diff <= 0 { countdown = "any moment now"; return }
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        let seconds = Int(diff) % 60
        if hours > 0 {
            countdown = "\(hours)h \(minutes)m \(seconds)s"
        } else {
            countdown = "\(minutes)m \(seconds)s"
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            AppLogoView(size: 80)
                .scaleEffect(pulse ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulse)

            VStack(spacing: 12) {
                Text("Your First Drop Is Brewing")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Fresh stories landing in")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                Text(countdown)
                    .font(.system(size: 28, weight: .bold).monospacedDigit())
                    .foregroundStyle(Theme.accent)

                Text("Pull down to refresh when it hits")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.top, 4)
            }
        }
        .onAppear {
            pulse = true
            updateCountdown()
        }
        .onReceive(timer) { _ in updateCountdown() }
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

    private var catColor: Color {
        Theme.categoryColor(for: story.category)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Hero image (full bleed)
                        if let imageUrl = story.imageUrl, let url = URL(string: imageUrl) {
                            ZStack(alignment: .bottomLeading) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 240)
                                            .clipped()
                                    case .failure:
                                        Rectangle()
                                            .fill(catColor.opacity(0.1))
                                            .frame(height: 240)
                                    default:
                                        Rectangle()
                                            .fill(Color.white.opacity(0.03))
                                            .frame(height: 240)
                                            .overlay(ProgressView().tint(.secondary))
                                    }
                                }

                                // Gradient overlay
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0.3),
                                        .init(color: .black, location: 1.0),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )

                                // Source credit
                                if let source = story.sourceName {
                                    Text(source)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.4))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.black.opacity(0.5))
                                        .clipShape(Capsule())
                                        .padding(12)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                }
                            }
                            .frame(height: 240)
                        }

                        // Content
                        VStack(alignment: .leading, spacing: 20) {
                            // Category + reading time
                            HStack {
                                CategoryPill(category: story.category, emoji: story.categoryEmoji)

                                Spacer()

                                Label("\(story.readingTimeMinutes) min read", systemImage: "clock")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Theme.textTertiary)
                            }

                            // Headline
                            Text(story.headline)
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)

                            // Body
                            Text(story.body)
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.88))
                                .lineSpacing(8)
                                .fixedSize(horizontal: false, vertical: true)

                            // TLDR
                            if let tldr = story.tldr {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("TLDR")
                                        .font(.caption.weight(.black))
                                        .foregroundStyle(catColor)
                                        .tracking(2)

                                    Text(tldr)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.75))
                                        .italic()
                                        .lineSpacing(4)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(catColor.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(catColor.opacity(0.15), lineWidth: 0.5)
                                )
                            }

                            // Reactions
                            GlassCard {
                                HStack(spacing: 0) {
                                    ForEach(reactions, id: \.key) { reaction in
                                        Button {
                                            handleReaction(reaction.key)
                                        } label: {
                                            VStack(spacing: 5) {
                                                Text(reaction.emoji)
                                                    .font(.title3)
                                                Text("\(reactionCounts[reaction.key] ?? 0)")
                                                    .font(.caption2.weight(.bold).monospacedDigit())
                                                    .foregroundStyle(userReaction == reaction.key ? .white : Theme.textTertiary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                userReaction == reaction.key
                                                    ? catColor.opacity(0.15)
                                                    : Color.clear
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            // Source + bookmark
                            HStack {
                                if let sourceName = story.sourceName {
                                    if let sourceUrl = story.sourceUrl, let url = URL(string: sourceUrl) {
                                        Link(destination: url) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "arrow.up.right.square")
                                                    .font(.caption)
                                                Text(sourceName)
                                                    .font(.caption.weight(.semibold))
                                            }
                                            .foregroundStyle(catColor.opacity(0.8))
                                        }
                                    } else {
                                        HStack(spacing: 6) {
                                            Image(systemName: "link")
                                                .font(.caption)
                                            Text("Source: \(sourceName)")
                                                .font(.caption)
                                        }
                                        .foregroundStyle(Theme.textTertiary)
                                    }
                                }

                                Spacer()

                                Button {
                                    handleBookmark()
                                } label: {
                                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                        .font(.title3)
                                        .foregroundStyle(isBookmarked ? catColor : Theme.textTertiary)
                                        .symbolEffect(.bounce, value: isBookmarked)
                                }
                            }

                            // Action buttons
                            HStack(spacing: 10) {
                                ShareLink(
                                    item: "\(story.headline)\n\nRead more on TheDailyPoop",
                                    subject: Text(story.headline),
                                    message: Text(story.tldr ?? story.headline)
                                ) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Share")
                                            .fontWeight(.bold)
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }

                                if story.bottomLine != nil || story.tldr != nil {
                                    Button {
                                        showingShareCard = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "photo")
                                            Text("Card")
                                                .fontWeight(.bold)
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Theme.elevatedBg)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Theme.cardBorder, lineWidth: 0.5)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(Theme.pagePadding)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial.opacity(0.5))
                            .clipShape(Circle())
                    }
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

        let impact = UIImpactFeedbackGenerator(style: wasSelected ? .light : .medium)
        impact.impactOccurred()

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

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(isBookmarked ? .warning : .success)

        isBookmarked.toggle()

        Task {
            let result = try? await SupabaseManager.shared.toggleBookmark(userId: user.id, storyId: story.id)
            if let result { isBookmarked = result }
        }
    }
}

// MARK: - Paywall
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var animate = false
    @State private var purchaseError: String?

    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: [
                        Color.black,
                        Theme.accent.opacity(0.2),
                        Color.black,
                    ],
                    startPoint: animate ? .topLeading : .bottomTrailing,
                    endPoint: animate ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animate)

                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 40)

                        // Logo
                        VStack(spacing: 16) {
                            AppLogoView(size: 72)

                            Text("Go Premium")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(.white)

                            Text("Unlock every story across all daily drops.\nNever miss the news that matters.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }

                        // Features
                        VStack(spacing: 14) {
                            PaywallFeature(icon: "newspaper.fill", text: "18 stories daily (3 drops)", color: Theme.accent)
                            PaywallFeature(icon: "bell.badge.fill", text: "Morning, midday & evening pushes", color: .orange)
                            PaywallFeature(icon: "archivebox.fill", text: "Full briefing archive", color: .cyan)
                            PaywallFeature(icon: "flame.fill", text: "Reading streak tracking", color: .red)
                            PaywallFeature(icon: "headphones", text: "Audio briefings", color: .purple)
                        }
                        .padding(.horizontal, 24)

                        // Pricing cards
                        VStack(spacing: 12) {
                            // Monthly
                            Button(action: { purchaseMonthly() }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Monthly")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text("Cancel anytime")
                                            .font(.caption)
                                            .foregroundStyle(Theme.textTertiary)
                                    }
                                    Spacer()
                                    Text("$7.99/mo")
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                }
                                .padding(18)
                                .background(Theme.elevatedBg)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Theme.cardBorder, lineWidth: 0.5)
                                )
                            }

                            // Annual (highlighted)
                            Button(action: { purchaseAnnual() }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text("Annual")
                                                .font(.headline)
                                            Text("SAVE 37%")
                                                .font(.system(size: 10, weight: .heavy))
                                                .foregroundStyle(.black)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Theme.accent)
                                                .clipShape(Capsule())
                                        }
                                        .foregroundStyle(.black)
                                        Text("$4.99/mo billed yearly")
                                            .font(.caption)
                                            .foregroundStyle(.black.opacity(0.6))
                                    }
                                    Spacer()
                                    Text("$59.99/yr")
                                        .font(.title3.bold())
                                        .foregroundStyle(.black)
                                }
                                .padding(18)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 24)

                        Button("Restore Purchases") {
                            restorePurchases()
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.textTertiary)

                        if subscriptionManager.isLoading {
                            ProgressView()
                                .tint(Theme.accent)
                        }

                        if let error = purchaseError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { animate = true }
        .disabled(subscriptionManager.isLoading)
    }

    private func purchaseMonthly() {
        purchaseError = nil
        Task {
            let success = await subscriptionManager.purchase(productID: SubscriptionManager.monthlyProductID)
            if success { dismiss() }
            else if !subscriptionManager.isLoading { purchaseError = "Purchase could not be completed." }
        }
    }

    private func purchaseAnnual() {
        purchaseError = nil
        Task {
            let success = await subscriptionManager.purchase(productID: SubscriptionManager.annualProductID)
            if success { dismiss() }
            else if !subscriptionManager.isLoading { purchaseError = "Purchase could not be completed." }
        }
    }

    private func restorePurchases() {
        purchaseError = nil
        Task {
            let success = await subscriptionManager.restorePurchases()
            if success { dismiss() }
            else { purchaseError = "No active subscription found." }
        }
    }
}

struct PaywallFeature: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 28)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green.opacity(0.6))
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accent)
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
            GeometryReader { geo in
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * audioManager.progress, height: 2)
            }
            .frame(height: 2)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    if audioManager.currentStoryIndex < stories.count {
                        Text(stories[audioManager.currentStoryIndex].headline)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    Text("Story \(audioManager.currentStoryIndex + 1) of \(stories.count)")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

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
                            .foregroundStyle(Theme.textTertiary)
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
