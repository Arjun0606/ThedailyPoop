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
            VStack(alignment: .leading, spacing: 10) {
                // Category + PRO badge
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Text(story.categoryEmoji)
                            .font(.caption)
                        Text(story.categoryLabel.uppercased())
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(catColor)
                            .tracking(1)
                    }

                    if isLocked {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 7))
                            Text("PRO")
                                .font(.system(size: 8, weight: .heavy))
                                .tracking(0.5)
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.accent)
                        .clipShape(Capsule())
                    }

                    Spacer()

                    Text("#\(story.sortOrder)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Theme.textTertiary)
                }

                // Headline
                Text(story.headline)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isLocked ? .white.opacity(0.5) : .white)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                    .lineLimit(3)

                // TLDR / body preview
                if isLocked {
                    Text(story.body.prefix(80) + "...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.25))
                        .lineLimit(2)
                        .blur(radius: 2)
                } else if let tldr = story.tldr {
                    Text(tldr)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                        .lineSpacing(2)
                }

                // Footer: meta info
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text("\(story.readingTimeMinutes) min")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(Theme.textTertiary)

                    if isRead {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                            Text("Read")
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(.green.opacity(0.7))
                    }

                    Spacer()

                    if totalReactions > 0 {
                        HStack(spacing: 3) {
                            Text("\u{1F525}")
                                .font(.system(size: 10))
                            Text("\(totalReactions)")
                                .font(.caption2.weight(.bold).monospacedDigit())
                                .foregroundStyle(.orange.opacity(0.8))
                        }
                    }

                    if let source = story.sourceName {
                        Text(source)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Theme.textTertiary.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
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
            .padding(.vertical, 4)
        }
        .buttonStyle(PressableButtonStyle())
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
                        emoji: nil,
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
                        emoji: nil,
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
