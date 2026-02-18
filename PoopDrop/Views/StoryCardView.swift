import SwiftUI

struct StoryCardView: View {
    let story: Story
    let isPremiumUser: Bool
    let isRead: Bool
    var totalReactions: Int = 0
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

                // Hero image
                if let imageUrl = story.imageUrl, let url = URL(string: imageUrl) {
                    ZStack(alignment: .bottomTrailing) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 160)
                                    .clipped()
                            case .failure:
                                EmptyView()
                            default:
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.05))
                                    .frame(height: 160)
                                    .overlay(
                                        ProgressView()
                                            .tint(.secondary)
                                    )
                            }
                        }

                        if let source = story.sourceName {
                            Text("📷 \(source)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.black.opacity(0.5))
                                .cornerRadius(4)
                                .padding(6)
                        }
                    }
                    .cornerRadius(10)
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

                // Source + reactions
                if !isLocked {
                    HStack(spacing: 10) {
                        if let source = story.sourceName {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.caption2)
                                Text(source)
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if totalReactions > 0 {
                            HStack(spacing: 3) {
                                Text("\u{1F525}")
                                    .font(.caption2)
                                Text("\(totalReactions)")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.orange.opacity(0.8))
                            }
                        }
                    }
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
                    imageUrl: nil,
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
                    imageUrl: nil,
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
