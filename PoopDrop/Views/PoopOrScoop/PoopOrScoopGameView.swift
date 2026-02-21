import SwiftUI

struct PoopOrScoopGameView: View {
    let game: ScoopGame
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var answers: [(headline: String, guessedReal: Bool)] = []
    @State private var cardOffset: CGFloat = 0
    @State private var cardRotation: Double = 0
    @State private var showResult = false
    @State private var result: ScoopSubmitResponse?
    @State private var isSubmitting = false
    @State private var revealDirection: String? = nil

    private var headlines: [ScoopHeadline] {
        game.headlines
    }

    private var isGameOver: Bool {
        currentIndex >= headlines.count
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("POOP OR SCOOP")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(Color.pink)
                            .tracking(2)
                        Text("Real or fake headline?")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    Spacer()

                    // Progress
                    Text("\(currentIndex)/\(headlines.count)")
                        .font(.system(size: 15, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)

                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, Theme.pagePadding)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 3)
                        Rectangle()
                            .fill(Color.pink)
                            .frame(width: geo.size.width * CGFloat(currentIndex) / CGFloat(headlines.count), height: 3)
                            .animation(.spring(response: 0.3), value: currentIndex)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, Theme.pagePadding)

                Spacer()

                if showResult, let result {
                    resultView(result)
                } else if currentIndex < headlines.count {
                    cardView
                } else {
                    ProgressView()
                        .tint(.white)
                }

                Spacer()

                if !showResult && !isGameOver {
                    // Swipe hints
                    HStack(spacing: 40) {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color.red)
                            Text("POOP")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(Color.red)
                            Text("Fake")
                                .font(.caption2)
                                .foregroundStyle(Theme.textTertiary)
                        }

                        VStack(spacing: 6) {
                            Image(systemName: "arrow.right")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color.green)
                            Text("SCOOP")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(Color.green)
                            Text("Real")
                                .font(.caption2)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Card View
    private var cardView: some View {
        ZStack {
            // Poop/Scoop labels that appear during swipe
            if cardOffset < -30 {
                Text("\u{274C} POOP")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Color.red)
                    .opacity(min(1, Double(-cardOffset) / 100))
            }
            if cardOffset > 30 {
                Text("\u{2705} SCOOP")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Color.green)
                    .opacity(min(1, Double(cardOffset) / 100))
            }

            // Headline card
            VStack(spacing: 20) {
                Text("\u{1F4F0}")
                    .font(.system(size: 40))

                Text(headlines[currentIndex].headline)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Swipe to decide")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        cardOffset < -30 ? Color.red.opacity(0.4) :
                        cardOffset > 30 ? Color.green.opacity(0.4) :
                        Theme.cardBorder,
                        lineWidth: 1
                    )
            )
            .offset(x: cardOffset)
            .rotationEffect(.degrees(cardRotation))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        cardOffset = value.translation.width
                        cardRotation = Double(value.translation.width) / 20
                    }
                    .onEnded { value in
                        if value.translation.width > 100 {
                            // Swiped right = Scoop (real)
                            swipeCard(guessedReal: true)
                        } else if value.translation.width < -100 {
                            // Swiped left = Poop (fake)
                            swipeCard(guessedReal: false)
                        } else {
                            withAnimation(.spring(response: 0.3)) {
                                cardOffset = 0
                                cardRotation = 0
                            }
                        }
                    }
            )
            .padding(.horizontal, Theme.pagePadding)
        }
    }

    private func swipeCard(guessedReal: Bool) {
        let headline = headlines[currentIndex].headline

        withAnimation(.easeOut(duration: 0.3)) {
            cardOffset = guessedReal ? 500 : -500
            cardRotation = guessedReal ? 15 : -15
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        answers.append((headline: headline, guessedReal: guessedReal))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cardOffset = 0
            cardRotation = 0
            currentIndex += 1

            if isGameOver {
                submitGame()
            }
        }
    }

    private func submitGame() {
        guard let userId = authManager.currentUser?.id else { return }
        isSubmitting = true

        Task {
            do {
                let submitAnswers = answers.map { ["headline": $0.headline, "guessedReal": $0.guessedReal] as [String: Any] }
                result = try await SupabaseManager.shared.submitScoopGame(
                    userId: userId,
                    gameId: game.id,
                    answers: submitAnswers
                )
                showResult = true
            } catch {
                print("Scoop submit error: \(error)")
                // Show basic result even on error
                let score = answers.count // fallback
                result = ScoopSubmitResponse(
                    score: score,
                    total: answers.count,
                    answers: [],
                    allHeadlines: []
                )
                showResult = true
            }
            isSubmitting = false
        }
    }

    // MARK: - Result View
    private func resultView(_ result: ScoopSubmitResponse) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score
                VStack(spacing: 8) {
                    Text("\(result.score)/\(result.total)")
                        .font(.system(size: 56, weight: .black).monospacedDigit())
                        .foregroundStyle(.white)

                    Text(scoreLabel(result.score, total: result.total))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(scoreColor(result.score, total: result.total))

                    Text("You correctly identified \(result.score) headlines")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 20)

                // Share pattern (like Wordle)
                let pattern = result.answers.map { $0.correct ? "\u{2705}" : "\u{274C}" }.joined()
                VStack(spacing: 8) {
                    Text(pattern)
                        .font(.title2)

                    ShareLink(
                        item: "\u{1F4A9} Poop or Scoop \(result.score)/\(result.total)\n\(pattern)\n\nCan you spot the fake headline?\nTheDailyPoop \u{2014} news that hits different\nthedailypoop.app"
                    ) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Score")
                                .fontWeight(.bold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.pink)
                        .clipShape(Capsule())
                    }
                }

                // Reveal all headlines
                if !result.allHeadlines.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("THE ANSWERS")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(2)

                        ForEach(Array(result.allHeadlines.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 10) {
                                Text(item.isReal ? "\u{2705}" : "\u{274C}")
                                    .font(.body)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.headline)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
                                    Text(item.isReal ? "Real headline" : "We made this up")
                                        .font(.caption2)
                                        .foregroundStyle(item.isReal ? Color.green : Color.red)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.elevatedBg)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(.horizontal, Theme.pagePadding)
                }

                Button { dismiss() } label: {
                    Text("Done")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Theme.cardBorder, lineWidth: 0.5)
                        )
                }
                .padding(.horizontal, Theme.pagePadding)

                Spacer(minLength: 40)
            }
        }
    }

    private func scoreLabel(_ score: Int, total: Int) -> String {
        let pct = Double(score) / Double(total)
        if pct >= 0.9 { return "News Detective!" }
        if pct >= 0.7 { return "Sharp Eye!" }
        if pct >= 0.5 { return "Not Bad!" }
        return "Fooled Ya!"
    }

    private func scoreColor(_ score: Int, total: Int) -> Color {
        let pct = Double(score) / Double(total)
        if pct >= 0.7 { return .green }
        if pct >= 0.5 { return Theme.accent }
        return .red
    }
}
