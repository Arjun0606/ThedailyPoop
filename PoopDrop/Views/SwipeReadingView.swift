import SwiftUI

struct SwipeReadingView: View {
    let stories: [Story]
    @Binding var readStoryIDs: Set<String>
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0

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
            }

            // Top bar
            VStack {
                HStack {
                    // Progress dots
                    HStack(spacing: 4) {
                        ForEach(0..<stories.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentIndex ? Color.white : Color.white.opacity(0.2))
                                .frame(width: i == currentIndex ? 20 : 6, height: 4)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Spacer(minLength: 50)

                // Story number + category
                HStack {
                    Text("\(story.categoryEmoji) \(story.categoryLabel)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))

                    Spacer()

                    Text("\(index + 1)/\(total)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                // Headline
                Text(story.headline)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                // Reading time
                Label("\(story.readingTimeMinutes) min read", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isLocked {
                    // Locked state
                    VStack(spacing: 16) {
                        Spacer(minLength: 40)

                        Image(systemName: "lock.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.yellow)

                        Text("Premium Story")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("Upgrade to read all 10 stories")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 40)
                    }
                    .frame(maxWidth: .infinity)
                } else {
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

                    // Source
                    if let source = story.sourceName {
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.caption)
                            Text("Source: \(source)")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }

                    // Swipe hint
                    if index < total - 1 {
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Text("Swipe for next")
                                    .font(.caption)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.white.opacity(0.3))
                        }
                        .padding(.top, 8)
                    }
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
    }
}
