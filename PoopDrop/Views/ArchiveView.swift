import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var briefings: [Briefing] = []
    @State private var isLoading = true
    @State private var selectedBriefing: Briefing?
    @State private var showingPaywall = false

    private var isPremium: Bool {
        authManager.currentUser?.isPremium ?? false
    }

    private var archiveDaysLimit: Int {
        isPremium ? 10 : 3
    }

    private var filteredBriefings: [Briefing] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        let cutoff = Calendar.current.date(byAdding: .day, value: -archiveDaysLimit, to: Date()) ?? Date()
        return briefings.filter { briefing in
            guard let date = formatter.date(from: briefing.publishDate) else { return false }
            return date >= cutoff
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Text("Catch Up")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.top, 16)
                .padding(.bottom, 12)

                if isLoading {
                    Spacer()
                    ProgressView().tint(Theme.textSecondary)
                    Spacer()
                } else if filteredBriefings.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("\u{1F3C3}")
                            .font(.system(size: 52))
                        Text("You're All Caught Up")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Past drops will show up here.\nNever miss a story.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredBriefings) { briefing in
                                Button { selectedBriefing = briefing } label: {
                                    ArchiveRow(briefing: briefing)
                                }
                                .buttonStyle(PressableButtonStyle())
                            }

                            // Upsell for free users
                            if !isPremium {
                                Button { showingPaywall = true } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Theme.accent)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("See more with PRO")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                            Text("Upgrade for 10 days of archive")
                                                .font(.caption2)
                                                .foregroundStyle(Theme.textSecondary)
                                        }

                                        Spacer()

                                        Text("PRO")
                                            .font(.system(size: 10, weight: .heavy))
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Theme.accent)
                                            .clipShape(Capsule())
                                    }
                                    .padding(14)
                                    .background(Theme.accent.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Theme.accent.opacity(0.15), lineWidth: 0.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.pagePadding)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .task { await loadArchive() }
        .sheet(item: $selectedBriefing) { briefing in
            ArchiveBriefingView(briefing: briefing)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func loadArchive() async {
        do {
            briefings = try await SupabaseManager.shared.fetchRecentBriefings(limit: 30)
        } catch {
            print("Archive load error: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Archive Row
struct ArchiveRow: View {
    let briefing: Briefing

    private var dropColor: Color {
        Theme.dropColor(for: briefing.dropType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Text(briefing.dropEmoji)
                        .font(.caption)
                    Text(briefing.dropLabel)
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(0.5)
                        .foregroundStyle(dropColor)
                }

                Spacer()

                Text(formattedDate)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.textTertiary)

                Text("\(briefing.storyCount)")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.cardBg)
                    .clipShape(Capsule())
            }

            Text(briefing.headline)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let intro = briefing.introText {
                Text(intro)
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
        // Left accent bar
        .overlay(alignment: .leading) {
            dropColor
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: briefing.publishDate) {
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date)
        }
        return briefing.publishDate
    }
}

// MARK: - Archive Briefing View
struct ArchiveBriefingView: View {
    let briefing: Briefing
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var stories: [Story] = []
    @State private var isLoading = true
    @State private var selectedStory: Story?
    @State private var showingPaywall = false

    private var isPremium: Bool {
        authManager.currentUser?.isPremium ?? false
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(Theme.textSecondary)
                } else {
                    let freeStories = stories.filter { $0.isFree }
                    let premiumStories = stories.filter { !$0.isFree }

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            DropHeaderView(briefing: briefing, isFirst: true)

                            ForEach(freeStories) { story in
                                StoryCardView(
                                    story: story,
                                    isPremiumUser: isPremium,
                                    isRead: false,
                                    onTap: { selectedStory = story }
                                )
                            }

                            // Soft paywall after free stories
                            if !isPremium && !premiumStories.isEmpty {
                                InlinePaywallCard(
                                    remainingCount: premiumStories.count,
                                    onUpgrade: { showingPaywall = true }
                                )
                            }

                            // Premium stories only for subscribers
                            if isPremium {
                                ForEach(premiumStories) { story in
                                    StoryCardView(
                                        story: story,
                                        isPremiumUser: true,
                                        isRead: false,
                                        onTap: { selectedStory = story }
                                    )
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await loadStories() }
        .sheet(item: $selectedStory) { story in
            StoryDetailView(story: story)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func loadStories() async {
        do {
            stories = try await SupabaseManager.shared.fetchBriefingStories(briefingId: briefing.id)
        } catch {
            print("Archive stories error: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    ArchiveView()
        .environmentObject(AuthenticationManager())
}
