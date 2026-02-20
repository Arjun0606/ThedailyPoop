import SwiftUI

struct PlayTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var wordGames: [WordGame] = []
    @State private var scoopGame: ScoopGame?
    @State private var selectedWordGame: WordGame?
    @State private var showingScoopGame = false
    @State private var showingLeaderboard = false
    @State private var showingPaywall = false
    @State private var isLoading = true

    private var streak: Int {
        authManager.currentUser?.streakCount ?? 0
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0) {
                    // MARK: - Streak + Stats Header
                    VStack(spacing: 20) {
                        // Streak ring
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.06), lineWidth: 5)
                                    .frame(width: 80, height: 80)
                                Circle()
                                    .trim(from: 0, to: min(Double(streak) / 7.0, 1.0))
                                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))

                                VStack(spacing: 0) {
                                    Text("\(streak)")
                                        .font(.system(size: 28, weight: .black).monospacedDigit())
                                        .foregroundStyle(.white)
                                    Text("day streak")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(Theme.textTertiary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                }
                            }

                            if streak > 0 {
                                Text(streakMessage)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .padding(.top, 12)

                        // Stats row
                        HStack(spacing: 12) {
                            statPill(
                                value: "\(authManager.currentUser?.highestWordScore ?? 0)",
                                label: "Best Score",
                                icon: "trophy.fill"
                            )
                            statPill(
                                value: "\(gamesPlayedToday)",
                                label: "Played Today",
                                icon: "checkmark.circle.fill"
                            )
                        }
                        .padding(.horizontal, Theme.pagePadding)
                    }
                    .padding(.bottom, 20)

                    // MARK: - Today's Games
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TODAY'S GAMES")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1.5)
                            .padding(.horizontal, Theme.pagePadding)

                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView().tint(Theme.textTertiary)
                                Spacer()
                            }
                            .padding(.vertical, 30)
                        } else {
                            VStack(spacing: 8) {
                                // Poop or Scoop
                                PoopOrScoopCardView(
                                    game: scoopGame,
                                    isPremium: authManager.currentUser?.isPremium ?? false,
                                    onPlay: { showingScoopGame = true },
                                    onUpgrade: { showingPaywall = true }
                                )

                                // Word Drop games
                                ForEach(wordGames, id: \.id) { game in
                                    WordDropCardView(
                                        game: game,
                                        isPremium: authManager.currentUser?.isPremium ?? false,
                                        onPlay: { selectedWordGame = game },
                                        onUpgrade: { showingPaywall = true }
                                    )
                                }
                            }
                            .padding(.horizontal, Theme.pagePadding)
                        }
                    }
                    .padding(.bottom, 24)

                    // MARK: - Leaderboard
                    if let date = wordGames.first?.publishDate ?? todayDateString {
                        LeaderboardPreviewCard(
                            date: date,
                            isPremium: authManager.currentUser?.isPremium ?? false,
                            onShowFull: { showingLeaderboard = true },
                            onUpgrade: { showingPaywall = true }
                        )
                        .padding(.horizontal, Theme.pagePadding)
                        .padding(.bottom, 24)
                    }

                    // MARK: - Premium Upsell (free users)
                    if !(authManager.currentUser?.isPremium ?? false) {
                        Button { showingPaywall = true } label: {
                            VStack(spacing: 8) {
                                Text("Unlock All Games")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("3 Word Drop games daily + Poop or Scoop + Leaderboard")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Theme.accent.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Theme.accent.opacity(0.2), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Theme.pagePadding)
                        .padding(.bottom, 24)
                    }

                    Spacer(minLength: 120)
                }
            }
            .refreshable { await loadGames() }
        }
        .safeAreaInset(edge: .top) {
            topBar
        }
        .task { await loadGames() }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingLeaderboard) {
            if let date = wordGames.first?.publishDate {
                WordDropLeaderboardView(date: date, dropType: "morning")
                    .environmentObject(authManager)
            }
        }
        .fullScreenCover(item: $selectedWordGame) { game in
            WordDropGameView(game: game)
                .environmentObject(authManager)
                .onDisappear {
                    Task {
                        if let user = authManager.currentUser {
                            wordGames = (try? await SupabaseManager.shared.fetchTodayGames(userId: user.id)) ?? wordGames
                        }
                    }
                }
        }
        .fullScreenCover(isPresented: $showingScoopGame) {
            if let game = scoopGame {
                PoopOrScoopGameView(game: game)
                    .environmentObject(authManager)
                    .onDisappear {
                        Task {
                            if let user = authManager.currentUser {
                                scoopGame = try? await SupabaseManager.shared.fetchTodayScoopGame(userId: user.id)
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Text("Play")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)

            Spacer()

            if streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                    Text("\(streak)")
                        .font(.system(size: 16, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, Theme.pagePadding)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Rectangle().fill(Color.black.opacity(0.6)))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5)
                }
        )
    }

    // MARK: - Helpers

    private var gamesPlayedToday: Int {
        var count = 0
        if scoopGame?.played == true { count += 1 }
        count += wordGames.filter { $0.played }.count
        return count
    }

    private var streakMessage: String {
        switch streak {
        case 1: return "You're on a roll!"
        case 2...4: return "Keep it going!"
        case 5...6: return "Almost a full week!"
        case 7: return "One full week!"
        case 8...13: return "Unstoppable!"
        case 14: return "Two weeks strong!"
        case 15...29: return "Legend status!"
        case 30...: return "Absolute menace!"
        default: return ""
        }
    }

    private var todayDateString: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return formatter.string(from: Date())
    }

    private func statPill(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.accent)
                .frame(width: 32, height: 32)
                .background(Theme.accent.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 17, weight: .bold).monospacedDigit())
                    .foregroundStyle(.white)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()
        }
        .padding(12)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
    }

    private func loadGames() async {
        guard let user = authManager.currentUser else { return }
        do {
            async let games = SupabaseManager.shared.fetchTodayGames(userId: user.id)
            async let scoop = SupabaseManager.shared.fetchTodayScoopGame(userId: user.id)

            wordGames = (try? await games) ?? []
            scoopGame = try? await scoop
        }
        isLoading = false
    }
}
