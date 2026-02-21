import SwiftUI

struct TheRoastCardView: View {
    let isPremium: Bool
    let onPlay: () -> Void
    let onUpgrade: () -> Void

    private var isLocked: Bool { !isPremium }
    private let gameColor = Color.red

    var body: some View {
        Button {
            if isLocked { onUpgrade() }
            else { onPlay() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(gameColor.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Text("\u{1F525}")
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("THE ROAST")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(gameColor)
                            .tracking(1.5)
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(gameColor)
                        }
                    }

                    if isLocked {
                        Text("Roast today's news")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Text("AI judges \u{00B7} community votes \u{00B7} daily winner")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    } else {
                        Text("Roast today's news")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Text("AI judges \u{00B7} community votes \u{00B7} daily winner")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Spacer()

                if isLocked {
                    Text("PRO")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(gameColor)
                        .clipShape(Capsule())
                } else {
                    Text("PLAY")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(gameColor)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(gameColor.opacity(0.15), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
