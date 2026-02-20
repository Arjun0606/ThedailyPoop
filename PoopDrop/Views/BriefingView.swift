import ActivityKit
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
    @State private var now = Date()

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
            } else if !drops.isEmpty, let todayDrop = drops.first {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Briefing header
                        DropHeaderView(
                            briefing: todayDrop.briefing,
                            isFirst: true,
                            readCount: todayDrop.stories.filter { readStoryIDs.contains($0.id) }.count,
                            totalCount: todayDrop.stories.count
                        )

                        let isPremium = authManager.currentUser?.isPremium ?? false
                        let freeStories = todayDrop.stories.filter { $0.isFree }
                        let premiumStories = todayDrop.stories.filter { !$0.isFree }

                        // Free stories
                        ForEach(freeStories) { story in
                            StoryCardView(
                                story: story,
                                isPremiumUser: isPremium,
                                isRead: readStoryIDs.contains(story.id),
                                totalReactions: storyReactionCounts[story.id] ?? 0,
                                onTap: { handleStoryTap(story) }
                            )
                        }

                        // Soft paywall after free stories
                        if !isPremium && !premiumStories.isEmpty {
                            InlinePaywallCard(
                                remainingCount: premiumStories.count,
                                onUpgrade: { showingPaywall = true }
                            )
                        }

                        // Premium stories (visible to subscribers)
                        if isPremium {
                            ForEach(premiumStories) { story in
                                StoryCardView(
                                    story: story,
                                    isPremiumUser: true,
                                    isRead: readStoryIDs.contains(story.id),
                                    totalReactions: storyReactionCounts[story.id] ?? 0,
                                    onTap: { handleStoryTap(story) }
                                )
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
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TheDailyPoop")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Text(formattedToday)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Theme.textTertiary)
                    if let drop = nextDropInfo {
                        Text("·")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                        Text("\(drop.label) in \(drop.countdown)")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                now = Date()
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

                // Audio (premium only)
                Button {
                    if !(authManager.currentUser?.isPremium ?? false) {
                        showingPaywall = true
                    } else if audioManager.isPlaying {
                        audioManager.togglePlayPause()
                    } else {
                        audioManager.startBriefing(stories: allStories)
                    }
                } label: {
                    ZStack {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "headphones")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(audioManager.isPlaying ? Theme.accent : .white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(audioManager.isPlaying ? Theme.accentDim : Theme.cardBg)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(audioManager.isPlaying ? Theme.accent.opacity(0.3) : Theme.cardBorder, lineWidth: 0.5))

                        if !(authManager.currentUser?.isPremium ?? false) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(Color.pink)
                                .clipShape(Circle())
                                .offset(x: 12, y: -12)
                        }
                    }
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
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return formatter.string(from: Date())
    }

    // MARK: - Next Drop Timer

    private let dropTimesET: [(hour: Int, minute: Int, label: String)] = [
        (7, 0, "Morning drop"),
        (12, 0, "Midday drop"),
        (17, 0, "Evening drop"),
    ]

    private var nextDropInfo: (label: String, countdown: String)? {
        let et = TimeZone(identifier: "America/New_York")!
        var cal = Calendar.current
        cal.timeZone = et

        let comps = cal.dateComponents([.hour, .minute, .second], from: now)
        let nowMinutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)

        for drop in dropTimesET {
            let dropMinutes = drop.hour * 60 + drop.minute
            if nowMinutes < dropMinutes {
                var target = cal.dateComponents([.year, .month, .day], from: now)
                target.hour = drop.hour
                target.minute = drop.minute
                target.second = 0
                if let targetDate = cal.date(from: target) {
                    let diff = Int(targetDate.timeIntervalSince(now))
                    if diff > 0 {
                        let h = diff / 3600
                        let m = (diff % 3600) / 60
                        let s = diff % 60
                        let str = h > 0
                            ? String(format: "%d:%02d:%02d", h, m, s)
                            : String(format: "%d:%02d", m, s)
                        return (drop.label, str)
                    }
                }
            }
        }

        // After evening drop — show tomorrow morning
        var tomorrow = cal.dateComponents([.year, .month, .day], from: now)
        tomorrow.day = (tomorrow.day ?? 0) + 1
        tomorrow.hour = dropTimesET[0].hour
        tomorrow.minute = dropTimesET[0].minute
        tomorrow.second = 0
        if let targetDate = cal.date(from: tomorrow) {
            let diff = Int(targetDate.timeIntervalSince(now))
            if diff > 0 {
                let h = diff / 3600
                let m = (diff % 3600) / 60
                let s = diff % 60
                return (dropTimesET[0].label, String(format: "%d:%02d:%02d", h, m, s))
            }
        }
        return nil
    }

    // MARK: - Data
    private func loadBriefing() async {
        guard let user = authManager.currentUser else { return }
        do {
            let fetchedDrops = try await SupabaseManager.shared.fetchTodayDrops()
            drops = fetchedDrops

            if !fetchedDrops.isEmpty {
                let briefingIds = fetchedDrops.map { $0.briefing.id }
                readStoryIDs = try await SupabaseManager.shared.fetchReadStoryIDs(userID: user.id, briefingIds: briefingIds)

                let allIds = fetchedDrops.flatMap { $0.stories.map { $0.id } }
                storyReactionCounts = (try? await SupabaseManager.shared.fetchBulkReactionCounts(storyIds: allIds)) ?? [:]

                if let morningDrop = fetchedDrops.first {
                    updateWidgetData(briefing: morningDrop.briefing, stories: morningDrop.stories)

                    // Start Dynamic Island Live Activity for the latest drop
                    let latestDrop = fetchedDrops.last!
                    let topEmoji = latestDrop.stories.first?.categoryEmoji ?? "📰"
                    LiveActivityManager.shared.startDropActivity(
                        briefing: latestDrop.briefing,
                        storyCount: latestDrop.stories.count,
                        topStoryEmoji: topEmoji
                    )
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
                    if briefing.usesAppLogo {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    } else {
                        Text(briefing.dropEmoji)
                            .font(.caption)
                    }
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

                if !isFirst {
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
                    .lineLimit(3)
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
        // Daily briefing drops at 7 AM ET
        if let today7am = cal.date(bySettingHour: 7, minute: 0, second: 0, of: now),
           today7am > now {
            return today7am
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
                Text("Today's Briefing Is Brewing")
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
                                            .frame(width: UIScreen.main.bounds.width, height: 240)
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
                            .frame(width: UIScreen.main.bounds.width, height: 240)
                            .clipped()
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
                                    item: "\(story.headline)\n\n\(story.bottomLine ?? story.tldr ?? story.headline)\n\n— TheDailyPoop | thedailypoop.app",
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

// MARK: - Story Body View (rich rendering with signature elements)
struct StoryBodyView: View {
    let storyText: String
    let catColor: Color

    /// Splits body into segments: plain text, "Translation:" callouts, and "The Number:" callouts
    private var segments: [BodySegment] {
        var result: [BodySegment] = []
        let paragraphs = storyText.components(separatedBy: "\n\n")

        for paragraph in paragraphs {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            if trimmed.hasPrefix("Translation:") || trimmed.contains("\nTranslation:") {
                // Check if "Translation:" is inline within a larger paragraph
                if let range = trimmed.range(of: "Translation:", options: .caseInsensitive) {
                    let before = String(trimmed[trimmed.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let translationText = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !before.isEmpty {
                        result.append(.text(before))
                    }
                    if !translationText.isEmpty {
                        result.append(.translation(translationText))
                    }
                }
            } else if trimmed.lowercased().hasPrefix("the number:") {
                let content = String(trimmed.dropFirst("The Number:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                result.append(.theNumber(content))
            } else {
                result.append(.text(trimmed))
            }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let content):
                    Text(content)
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)

                case .translation(let content):
                    HStack(alignment: .top, spacing: 10) {
                        Rectangle()
                            .fill(catColor)
                            .frame(width: 3)
                            .clipShape(Capsule())

                        VStack(alignment: .leading, spacing: 4) {
                            Text("TRANSLATION")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(catColor)
                                .tracking(2)
                            Text(content)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white.opacity(0.95))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(catColor.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                case .theNumber(let content):
                    VStack(alignment: .leading, spacing: 6) {
                        Text("THE NUMBER")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Theme.accent)
                            .tracking(2)
                        Text(content)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.08), Theme.accent.opacity(0.02)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .leading) {
                        Theme.accent
                            .frame(width: 3)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private enum BodySegment {
        case text(String)
        case translation(String)
        case theNumber(String)
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
