import SwiftUI

struct SpinTheExcuseGameView: View {
    let game: ExcuseGame
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentRound = 0
    @State private var answers: [String] = []
    @State private var selectedOption: String?
    @State private var showCorrect = false
    @State private var showResult = false
    @State private var result: ExcuseSubmitResponse?
    @State private var isSubmitting = false

    private var rounds: [ExcuseRound] { game.rounds }
    private var isGameOver: Bool { currentRound >= rounds.count }

    private let accentColor = Color.orange

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SPIN THE EXCUSE")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(accentColor)
                            .tracking(2)
                        Text("Pick the real PR excuse")
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
                            .fill(accentColor)
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
            VStack(spacing: 20) {
                Spacer(minLength: 20)

                // Situation card
                VStack(spacing: 12) {
                    Text("\u{1F6A8}")
                        .font(.system(size: 36))

                    Text("WHAT HAPPENED")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(accentColor)
                        .tracking(1.5)

                    Text(round.situation)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("What was their actual excuse?")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Theme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, Theme.pagePadding)

                // Options
                VStack(spacing: 10) {
                    ForEach(Array(round.options.enumerated()), id: \.offset) { idx, option in
                        Button {
                            guard selectedOption == nil else { return }
                            selectAnswer(option, correct: round.correctExcuse)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(["A", "B", "C", "D"][min(idx, 3)])")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundStyle(accentColor)
                                    .frame(width: 28, height: 28)
                                    .background(accentColor.opacity(0.15))
                                    .clipShape(Circle())

                                Text(option)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer()

                                if showCorrect {
                                    if option == round.correctExcuse {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else if option == selectedOption {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                            .padding(14)
                            .background(excuseOptionBg(option, correct: round.correctExcuse))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(excuseOptionBorder(option, correct: round.correctExcuse), lineWidth: 0.5)
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

    private func excuseOptionBg(_ option: String, correct: String) -> Color {
        guard showCorrect else { return Theme.cardBg }
        if option == correct { return Color.green.opacity(0.15) }
        if option == selectedOption { return Color.red.opacity(0.15) }
        return Theme.cardBg
    }

    private func excuseOptionBorder(_ option: String, correct: String) -> Color {
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
                result = try await SupabaseManager.shared.submitExcuseGame(
                    userId: userId, gameId: game.id, answers: answers
                )
                showResult = true
            } catch {
                let score = zip(answers, rounds).filter { $0.0 == $0.1.correctExcuse }.count
                result = ExcuseSubmitResponse(score: score, total: rounds.count, results: [])
                showResult = true
            }
            isSubmitting = false
        }
    }

    // MARK: - Result View
    private func resultView(_ result: ExcuseSubmitResponse) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(result.score)/\(result.total)")
                        .font(.system(size: 56, weight: .black).monospacedDigit())
                        .foregroundStyle(.white)

                    Text(scoreLabel(result.score, total: result.total))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(result.score > result.total / 2 ? .green : accentColor)
                }
                .padding(.top, 20)

                let pattern = result.results.isEmpty
                    ? zip(answers, rounds).map { $0.0 == $0.1.correctExcuse ? "\u{2705}" : "\u{274C}" }.joined()
                    : result.results.map { $0.correct ? "\u{2705}" : "\u{274C}" }.joined()

                ShareLink(
                    item: "Spin the Excuse \(result.score)/\(result.total)\n\(pattern)\n\nCan you spot the real PR excuse?\nTheDailyPoop"
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
                    .background(accentColor)
                    .clipShape(Capsule())
                }

                if !result.results.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("THE ANSWERS")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(2)

                        ForEach(Array(result.results.enumerated()), id: \.offset) { _, item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.situation)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Theme.textSecondary)

                                HStack(spacing: 6) {
                                    Text(item.correct ? "\u{2705}" : "\u{274C}")
                                    Text(item.correctExcuse)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
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
        if pct >= 0.8 { return "PR Detector!" }
        if pct >= 0.6 { return "Spin Doctor!" }
        if pct >= 0.4 { return "Almost Had It!" }
        return "They Got You!"
    }
}
