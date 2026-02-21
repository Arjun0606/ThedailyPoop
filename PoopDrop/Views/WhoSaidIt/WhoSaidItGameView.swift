import SwiftUI

struct WhoSaidItGameView: View {
    let game: WhoSaidItGame
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentRound = 0
    @State private var answers: [String] = []
    @State private var selectedOption: String?
    @State private var showCorrect = false
    @State private var showResult = false
    @State private var result: WhoSaidItSubmitResponse?
    @State private var isSubmitting = false

    private var rounds: [WhoSaidItRound] { game.rounds }
    private var isGameOver: Bool { currentRound >= rounds.count }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WHO SAID IT?")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(Color.purple)
                            .tracking(2)
                        Text("CEO, dictator, cult leader, or reality TV?")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    Spacer()

                    Text("\(currentRound)/\(rounds.count)")
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
                        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 3)
                        Rectangle()
                            .fill(Color.purple)
                            .frame(width: geo.size.width * CGFloat(currentRound) / CGFloat(rounds.count), height: 3)
                            .animation(.spring(response: 0.3), value: currentRound)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, Theme.pagePadding)

                if showResult, let result {
                    resultView(result)
                } else if currentRound < rounds.count {
                    roundView
                } else {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Round View
    private var roundView: some View {
        let round = rounds[currentRound]

        return ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 30)

                // Quote card
                VStack(spacing: 16) {
                    Text("\u{201C}")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(Color.purple.opacity(0.5))

                    Text(round.quote)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\u{201D}")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(Color.purple.opacity(0.5))
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Theme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, Theme.pagePadding)

                // Options
                VStack(spacing: 10) {
                    ForEach(round.options, id: \.self) { option in
                        Button {
                            guard selectedOption == nil else { return }
                            selectAnswer(option, correct: round.correctAnswer)
                        } label: {
                            HStack {
                                Text(optionEmoji(option))
                                    .font(.title3)
                                Text(option)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()

                                if showCorrect {
                                    if option == round.correctAnswer {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else if option == selectedOption && option != round.correctAnswer {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                            .padding(16)
                            .background(optionBackground(option, correct: round.correctAnswer))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(optionBorder(option, correct: round.correctAnswer), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(showCorrect)
                    }
                }
                .padding(.horizontal, Theme.pagePadding)

                Spacer(minLength: 40)
            }
        }
    }

    private func optionEmoji(_ option: String) -> String {
        switch option.lowercased() {
        case let s where s.contains("ceo"): return "\u{1F454}"
        case let s where s.contains("dictator"): return "\u{1F3DB}"
        case let s where s.contains("cult"): return "\u{1F441}"
        case let s where s.contains("reality"): return "\u{1F4FA}"
        default: return "\u{2753}"
        }
    }

    private func optionBackground(_ option: String, correct: String) -> Color {
        guard showCorrect else { return Theme.cardBg }
        if option == correct { return Color.green.opacity(0.15) }
        if option == selectedOption { return Color.red.opacity(0.15) }
        return Theme.cardBg
    }

    private func optionBorder(_ option: String, correct: String) -> Color {
        guard showCorrect else { return Theme.cardBorder }
        if option == correct { return Color.green.opacity(0.4) }
        if option == selectedOption { return Color.red.opacity(0.4) }
        return Theme.cardBorder
    }

    private func selectAnswer(_ option: String, correct: String) {
        selectedOption = option

        let impact = UIImpactFeedbackGenerator(style: option == correct ? .light : .medium)
        impact.impactOccurred()

        withAnimation(.easeOut(duration: 0.2)) {
            showCorrect = true
        }

        answers.append(option)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            selectedOption = nil
            showCorrect = false
            currentRound += 1

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
                result = try await SupabaseManager.shared.submitWhoSaidIt(
                    userId: userId, gameId: game.id, answers: answers
                )
                showResult = true
            } catch {
                let score = zip(answers, rounds).filter { $0.0 == $0.1.correctAnswer }.count
                result = WhoSaidItSubmitResponse(score: score, total: rounds.count, results: [])
                showResult = true
            }
            isSubmitting = false
        }
    }

    // MARK: - Result View
    private func resultView(_ result: WhoSaidItSubmitResponse) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(result.score)/\(result.total)")
                        .font(.system(size: 56, weight: .black).monospacedDigit())
                        .foregroundStyle(.white)

                    Text(scoreLabel(result.score, total: result.total))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(result.score > result.total / 2 ? .green : Theme.accent)
                }
                .padding(.top, 20)

                // Share
                let pattern = result.results.isEmpty
                    ? zip(answers, rounds).map { $0.0 == $0.1.correctAnswer ? "\u{2705}" : "\u{274C}" }.joined()
                    : result.results.map { $0.correct ? "\u{2705}" : "\u{274C}" }.joined()

                ShareLink(
                    item: "\u{1F3A4} Who Said It? \(result.score)/\(result.total)\n\(pattern)\n\nCEO, dictator, cult leader, or reality TV star?\nTheDailyPoop \u{2014} news that hits different\nhttps://apps.apple.com/app/thedailypoop/id6743040953"
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
                    .background(Color.purple)
                    .clipShape(Capsule())
                }

                // Answer reveal
                if !result.results.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("THE ANSWERS")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(2)

                        ForEach(Array(result.results.enumerated()), id: \.offset) { _, item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\u{201C}\(item.quote)\u{201D}")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white)
                                    .lineLimit(3)

                                HStack(spacing: 6) {
                                    Text(item.correct ? "\u{2705}" : "\u{274C}")
                                    Text(item.correctAnswer)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(item.correct ? .green : .red)
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
        let pct = Double(score) / Double(max(total, 1))
        if pct >= 0.8 { return "Quote Master!" }
        if pct >= 0.6 { return "Sharp Ear!" }
        if pct >= 0.4 { return "Getting There!" }
        return "They All Sound Crazy!"
    }
}
