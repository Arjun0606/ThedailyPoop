import SwiftUI

struct PoopOrScoopCardView: View {
    let game: ScoopGame?
    let isPremium: Bool
    let onPlay: () -> Void
    let onUpgrade: () -> Void

    private var isLocked: Bool {
        !isPremium && game?.played != true
    }

    var body: some View {
        Button {
            if isLocked {
                onUpgrade()
            } else if game?.played == true {
                // Already played — just show score
            } else if game != nil {
                onPlay()
            }
        } label: {
            HStack(spacing: 14) {
                // Game icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.pink.opacity(0.3), Color.green.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("POOP OR SCOOP")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Color.pink)
                            .tracking(1.5)

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.pink)
                        }
                    }

                    if let game, game.played, let userScore = game.userScore {
                        Text("\(userScore.score)/\(userScore.total) correct")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Real or fake? You figured it out")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    } else if isLocked {
                        Text("Upgrade to play")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Text("Real or fake headlines — PRO only")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    } else if game != nil {
                        Text("Real or fake headline?")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Text("Swipe to guess \u{00B7} 10 headlines")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    } else {
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
                        .background(Color.pink)
                        .clipShape(Capsule())
                } else if game != nil {
                    Text("PLAY")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.pink)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        (game?.played == true) ? .green.opacity(0.15) : Color.pink.opacity(0.15),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(game == nil)
    }
}
