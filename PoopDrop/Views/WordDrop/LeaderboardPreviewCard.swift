import SwiftUI

struct LeaderboardPreviewCard: View {
    let date: String
    let isPremium: Bool
    let onShowFull: () -> Void
    let onUpgrade: () -> Void

    @State private var topEntries: [DailyLeaderboardEntry] = []
    @State private var gamesAvailable = 0
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.accent)
                    Text("LEADERBOARD")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Theme.accent)
                        .tracking(1.5)
                }

                Spacer()

                Button(action: isPremium ? onShowFull : onUpgrade) {
                    Text(isPremium ? "See All" : "Upgrade")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isPremium ? Theme.accent : .black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(isPremium ? Theme.accent.opacity(0.15) : Theme.accent)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(Theme.textTertiary)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if topEntries.isEmpty {
                VStack(spacing: 6) {
                    Text("No scores yet today")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Play today's games to get on the board!")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(.vertical, 16)
            } else {
                // Top 3 entries
                VStack(spacing: 0) {
                    ForEach(topEntries.prefix(3)) { entry in
                        HStack(spacing: 12) {
                            // Rank medal
                            Text(rankEmoji(entry.rank))
                                .font(.system(size: 16))
                                .frame(width: 24)

                            // Avatar
                            if let avatarUrl = entry.avatarUrl, let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(Theme.elevatedBg)
                                }
                                .frame(width: 28, height: 28)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Theme.elevatedBg)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Text(String(entry.username.prefix(1)).uppercased())
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(Theme.textSecondary)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text("@\(entry.username)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text("\(entry.gamesPlayed)/\(gamesAvailable) games")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Theme.textTertiary)
                            }

                            Spacer()

                            Text("\(entry.score) pts")
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundStyle(Theme.accent)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                }
            }

            // Free user FOMO banner
            if !isPremium {
                Button(action: onUpgrade) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Upgrade to appear on the leaderboard")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.accent.opacity(0.08))
                }
            }
        }
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.accent.opacity(0.12), lineWidth: 0.5)
        )
        .task {
            do {
                let result = try await SupabaseManager.shared.fetchDailyLeaderboard(date: date)
                topEntries = result.entries
                gamesAvailable = result.gamesAvailable
            } catch {
                print("Leaderboard preview error: \(error)")
            }
            isLoading = false
        }
    }

    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "\u{1F947}"
        case 2: return "\u{1F948}"
        case 3: return "\u{1F949}"
        default: return "\(rank)"
        }
    }
}
