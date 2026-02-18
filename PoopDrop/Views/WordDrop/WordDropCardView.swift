import SwiftUI

struct WordDropCardView: View {
    let game: WordGame
    let isPremium: Bool
    let onPlay: () -> Void
    let onUpgrade: () -> Void

    @State private var showingLeaderboard = false
    @EnvironmentObject var authManager: AuthenticationManager

    private var isLocked: Bool {
        !isPremium && game.dropType != "morning"
    }

    var body: some View {
        Button {
            if isLocked {
                onUpgrade()
            } else if game.played {
                showingLeaderboard = true
            } else {
                onPlay()
            }
        } label: {
            HStack(spacing: 14) {
                // Game icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.3), Theme.accent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Text("Aa")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("WORD DROP")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Theme.accent)
                            .tracking(1.5)

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Theme.accent)
                        }
                    }

                    if game.played, let userScore = game.userScore {
                        Text("Score: \(userScore.score) pts")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("\(userScore.wordCount) words found\(userScore.foundKeyWord ? " \u{2B50}" : "") \u{00B7} View leaderboard")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    } else if isLocked {
                        Text("Upgrade to play")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Text("Premium members get all 3 daily games")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    } else {
                        Text("Unscramble today's headline")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Text("90 seconds \u{00B7} \(game.letters.count) letters")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Spacer()

                if game.played {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                } else if isLocked {
                    Text("PRO")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.accent)
                        .clipShape(Capsule())
                } else {
                    Text("PLAY")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.accent)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(game.played ? .green.opacity(0.15) : Theme.accent.opacity(0.15), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingLeaderboard) {
            WordDropLeaderboardView(date: game.publishDate, dropType: game.dropType)
                .environmentObject(authManager)
        }
    }
}
