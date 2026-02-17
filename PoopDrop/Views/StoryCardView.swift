import SwiftUI

struct StoryCardView: View {
    let story: Story
    let isPremiumUser: Bool
    let isRead: Bool
    let onTap: () -> Void

    private var isLocked: Bool {
        !story.isFree && !isPremiumUser
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Category + story number
                HStack {
                    Text("\(story.categoryEmoji) \(story.categoryLabel)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))

                    Spacer()

                    HStack(spacing: 6) {
                        if isRead {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }

                        Text("\(story.readingTimeMinutes) min")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("#\(story.sortOrder)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }

                // Headline
                Text(story.headline)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                // Body preview or blur
                if isLocked {
                    // Blurred preview for locked stories
                    Text(story.body.prefix(120) + "...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(3)
                        .blur(radius: 4)
                        .overlay(
                            VStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                    .font(.title3)
                                Text("Premium")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(.yellow)
                        )
                } else {
                    // TLDR for unlocked stories
                    if let tldr = story.tldr {
                        Text(tldr)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(2)
                    }
                }

                // Source
                if let source = story.sourceName, !isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption2)
                        Text(source)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .background(isRead ? Color.white.opacity(0.02) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 0) {
            StoryCardView(
                story: Story(
                    id: "1",
                    briefingId: "b1",
                    sortOrder: 1,
                    isFree: true,
                    category: "tech",
                    headline: "Apple's New AI Can Finally Count to Ten",
                    body: "In a breakthrough that surprised absolutely no one...",
                    tldr: "Apple fixed basic math in their AI. Progress.",
                    sourceUrl: nil,
                    sourceName: "TechCrunch",
                    emoji: "📱",
                    createdAt: Date()
                ),
                isPremiumUser: false,
                isRead: false,
                onTap: {}
            )

            Divider().background(Color.white.opacity(0.06))

            StoryCardView(
                story: Story(
                    id: "2",
                    briefingId: "b1",
                    sortOrder: 4,
                    isFree: false,
                    category: "business",
                    headline: "Wall Street Discovers That Money Can Buy Happiness",
                    body: "A new study from Goldman Sachs reveals...",
                    tldr: nil,
                    sourceUrl: nil,
                    sourceName: "WSJ",
                    emoji: "💰",
                    createdAt: Date()
                ),
                isPremiumUser: false,
                isRead: false,
                onTap: {}
            )
        }
    }
}
