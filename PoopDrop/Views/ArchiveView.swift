import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var briefings: [Briefing] = []
    @State private var isLoading = true
    @State private var selectedBriefing: Briefing?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Text("Archive")
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
                } else if briefings.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("📚")
                            .font(.system(size: 52))
                        Text("No Archives Yet")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Past briefings will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(briefings) { briefing in
                                Button { selectedBriefing = briefing } label: {
                                    ArchiveRow(briefing: briefing)
                                }
                                .buttonStyle(PressableButtonStyle())
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

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(Theme.textSecondary)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            DropHeaderView(briefing: briefing, isFirst: true)

                            ForEach(stories) { story in
                                StoryCardView(
                                    story: story,
                                    isPremiumUser: authManager.currentUser?.isPremium ?? false,
                                    isRead: false,
                                    onTap: {
                                        if story.isFree || (authManager.currentUser?.isPremium ?? false) {
                                            selectedStory = story
                                        }
                                    }
                                )
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
