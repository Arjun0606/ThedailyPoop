import SwiftUI

struct WordDropLeaderboardView: View {
    let date: String
    let dropType: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true

    private var isPremium: Bool {
        authManager.currentUser?.isPremium ?? false
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(Theme.accent)
                } else if entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy")
                            .font(.system(size: 40))
                            .foregroundStyle(Theme.textTertiary)
                        Text("No scores yet")
                            .font(.headline)
                            .foregroundStyle(Theme.textSecondary)
                        Text("Be the first to play today's Word Drop!")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textTertiary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Upgrade CTA for free users
                            if !isPremium {
                                HStack(spacing: 10) {
                                    Image(systemName: "crown.fill")
                                        .foregroundStyle(Theme.accent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Go Premium to compete")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(.white)
                                        Text("Your scores won't appear until you upgrade")
                                            .font(.caption2)
                                            .foregroundStyle(Theme.textTertiary)
                                    }
                                    Spacer()
                                }
                                .padding(14)
                                .background(Theme.accent.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Theme.accent.opacity(0.2), lineWidth: 0.5)
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }

                            ForEach(entries) { entry in
                                LeaderboardRow(entry: entry)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            do {
                entries = try await SupabaseManager.shared.fetchLeaderboard(date: date, dropType: dropType)
            } catch {
                print("Leaderboard error: \(error)")
            }
            isLoading = false
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)    // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.78)   // Silver
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)   // Bronze
        default: return Theme.textTertiary
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Rank
            Text("\(entry.rank)")
                .font(.system(size: entry.rank <= 3 ? 18 : 14, weight: .black).monospacedDigit())
                .foregroundStyle(rankColor)
                .frame(width: 32)

            // Avatar
            if let avatarUrl = entry.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Theme.elevatedBg)
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Theme.elevatedBg)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(entry.username.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textSecondary)
                    )
            }

            // Name + words
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("@\(entry.username)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    if entry.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(Theme.accent)
                    }
                }
                HStack(spacing: 4) {
                    Text("\(entry.wordCount) words")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                    if entry.foundKeyWord {
                        Text("\u{2B50}")
                            .font(.system(size: 10))
                    }
                }
            }

            Spacer()

            // Score
            Text("\(entry.score)")
                .font(.system(size: 18, weight: .black).monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(entry.rank <= 3 ? rankColor.opacity(0.05) : Color.clear)
    }
}
