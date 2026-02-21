import SwiftUI

struct WhoSaidItCardView: View {
    let game: WhoSaidItGame?
    let isPremium: Bool
    let onPlay: () -> Void
    let onUpgrade: () -> Void

    private var isLocked: Bool { !isPremium }
    private let gameColor = Color.purple

    var body: some View {
        Button {
            if isLocked { onUpgrade() }
            else if game?.played == true { /* show score */ }
            else if game != nil { onPlay() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(gameColor.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Text("\u{201C}")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(gameColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("WHO SAID IT?")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(gameColor)
                            .tracking(1.5)
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(gameColor)
                        }
                    }

                    if let game, game.played, let score = game.userScore {
                        Text("\(score.score)/\(score.total) correct")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("CEO, dictator, or reality TV?")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    } else if isLocked {
                        Text("Who really said this?")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Text("CEO, dictator, or reality TV?")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    } else if game != nil {
                        Text("Who really said this?")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Text("5 quotes \u{00B7} 4 options each")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    } else if !isLocked {
                        Text("Coming soon...")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                if let game, game.played {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                } else if isLocked {
                    Text("PRO")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(gameColor)
                        .clipShape(Capsule())
                } else if game != nil {
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
                    .stroke(
                        (game?.played == true) ? .green.opacity(0.15) : gameColor.opacity(0.15),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isLocked && game == nil)
    }
}
