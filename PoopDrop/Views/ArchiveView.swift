import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var briefings: [Briefing] = []
    @State private var isLoading = true
    @State private var selectedBriefing: Briefing?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.white)
                } else if briefings.isEmpty {
                    VStack(spacing: 20) {
                        Text("📚")
                            .font(.system(size: 60))
                        Text("No Archives Yet")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("Past briefings will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(briefings) { briefing in
                            Button(action: { selectedBriefing = briefing }) {
                                ArchiveRow(briefing: briefing)
                            }
                            .listRowBackground(Color.white.opacity(0.03))
                            .listRowSeparatorTint(Color.white.opacity(0.06))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Archive")
            .navigationBarTitleDisplayMode(.large)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formattedDate)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.brown)

                Spacer()

                Text("\(briefing.storyCount) stories")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(briefing.headline)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)

            if let intro = briefing.introText {
                Text(intro)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
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

// MARK: - Archive Briefing View (reuses story loading)
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
                    ProgressView().tint(.white)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            BriefingHeaderView(briefing: briefing)

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

                                if story.id != stories.last?.id {
                                    Divider()
                                        .background(Color.white.opacity(0.06))
                                        .padding(.horizontal, 20)
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
                        .foregroundStyle(.white)
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
