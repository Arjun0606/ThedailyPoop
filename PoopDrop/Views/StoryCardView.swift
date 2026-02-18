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

    private var catColor: Color {
        Theme.categoryColor(for: story.category)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image with gradient overlay
                if let imageUrl = story.imageUrl, let url = URL(string: imageUrl) {
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 180)
                                    .clipped()
                            case .failure:
                                imagePlaceholder
                            default:
                                imagePlaceholder
                            }
                        }

                        // Bottom gradient fade
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black.opacity(0.7), location: 0.7),
                                .init(color: .black.opacity(0.95), location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .frame(maxHeight: .infinity, alignment: .bottom)

                        // Category pill on image
                        HStack(spacing: 8) {
                            CategoryPill(category: story.category, emoji: story.categoryEmoji)

                            if isLocked {
                                HStack(spacing: 3) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8))
                                    Text("PRO")
                                        .font(.system(size: 9, weight: .heavy))
                                        .tracking(0.5)
                                }
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.accent)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(12)

                        // Source credit
                        if let source = story.sourceName {
                            Text(source)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.black.opacity(0.6))
                                .clipShape(Capsule())
                                .padding(10)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        }
                    }
                    .frame(height: 180)
                    .clipped()
                }

                // Content area
                VStack(alignment: .leading, spacing: 10) {
                    // No-image fallback: show category pill here
                    if story.imageUrl == nil {
                        HStack(spacing: 8) {
                            CategoryPill(category: story.category, emoji: story.categoryEmoji)

                            if isLocked {
                                HStack(spacing: 3) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8))
                                    Text("PRO")
                                        .font(.system(size: 9, weight: .heavy))
                                        .tracking(0.5)
                                }
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.accent)
                                .clipShape(Capsule())
                            }
                        }
                    }

                    // Headline
                    Text(story.headline)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)

                    // TLDR / body preview
                    if isLocked {
                        Text(story.body.prefix(100) + "...")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.4))
                            .lineLimit(2)
                            .blur(radius: 3)
                    } else if let tldr = story.tldr {
                        Text(tldr)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                    }

                    // Footer: meta info
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("\(story.readingTimeMinutes) min")
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(Theme.textTertiary)

                        if isRead {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                Text("Read")
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(.green.opacity(0.7))
                        }

                        Spacer()

                        if totalReactions > 0 {
                            HStack(spacing: 3) {
                                Text("\u{1F525}")
                                    .font(.caption2)
                                Text("\(totalReactions)")
                                    .font(.caption2.weight(.bold).monospacedDigit())
                                    .foregroundStyle(.orange.opacity(0.8))
                            }
                        }

                        Text("#\(story.sortOrder)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            // Left accent bar
            .overlay(alignment: .leading) {
                catColor
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            .background(isRead ? Color.white.opacity(0.02) : Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 0.5)
            )
            .padding(.horizontal, Theme.pagePadding)
            .padding(.vertical, 6)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [catColor.opacity(0.15), catColor.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 180)
            .overlay(
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(catColor.opacity(0.3))
            )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 0) {
                StoryCardView(
                    story: Story(
                        id: "1",
                        briefingId: "b1",
                        sortOrder: 1,
                        isFree: true,
                        category: "tech",
                        headline: "Apple Just Admitted Their AI Can't Count and Honestly, Same",
                        body: "In a breakthrough that surprised absolutely no one...",
                        tldr: "Apple fixed basic math in their AI. Progress.",
                        sourceUrl: nil,
                        sourceName: "TechCrunch",
                        imageUrl: nil,
                        emoji: "📱",
                        createdAt: Date()
                    ),
                    isPremiumUser: false,
                    isRead: true,
                    totalReactions: 42,
                    onTap: {}
                )

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
}
