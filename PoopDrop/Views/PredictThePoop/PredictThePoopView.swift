import SwiftUI

struct PredictThePoopView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var predictions: [Prediction] = []
    @State private var isLoading = true
    @State private var submittingId: String?

    private let accentColor = Color.indigo

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PREDICT THE POOP")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(accentColor)
                            .tracking(2)
                        Text("Will it happen? You decide.")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    Spacer()

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
                .padding(.bottom, 16)

                if isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if predictions.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("\u{1F52E}")
                            .font(.system(size: 48))
                        Text("No predictions today")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Check back tomorrow")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                } else {
                    predictionsListView
                }
            }
        }
        .task { await loadPredictions() }
    }

    // MARK: - Predictions List
    private var predictionsListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(predictions) { prediction in
                    predictionCard(prediction)
                }

                // How it works
                VStack(spacing: 8) {
                    Text("HOW IT WORKS")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)

                    Text("Make your prediction. When the event resolves, see if you were right. Track your accuracy over time.")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                .padding(.horizontal, Theme.pagePadding)

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
    }

    private func predictionCard(_ prediction: Prediction) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Question
            Text(prediction.question)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            // Context
            if let context = prediction.context, !context.isEmpty {
                Text(context)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(3)
            }

            // Resolve by
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text("Resolves by \(prediction.resolveBy)")
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(Theme.textTertiary)

            // Vote buttons or result
            if let userBet = prediction.userBet {
                // Already voted
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: userBet ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(userBet ? .green : Theme.textTertiary)
                        Text("Yes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(userBet ? .green : Theme.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(userBet ? Color.green.opacity(0.12) : Theme.cardBg)
                    .clipShape(Capsule())

                    HStack(spacing: 6) {
                        Image(systemName: !userBet ? "xmark.circle.fill" : "circle")
                            .foregroundStyle(!userBet ? .red : Theme.textTertiary)
                        Text("No")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(!userBet ? .red : Theme.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(!userBet ? Color.red.opacity(0.12) : Theme.cardBg)
                    .clipShape(Capsule())

                    Spacer()

                    Text("Locked in")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            } else if let resolved = prediction.resolvedAnswer {
                // Resolved
                HStack(spacing: 8) {
                    Text(resolved ? "\u{2705} Yes" : "\u{274C} No")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(resolved ? .green : .red)
                    Text("(Resolved)")
                        .font(.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
            } else {
                // Not yet voted
                HStack(spacing: 12) {
                    Button {
                        submitBet(prediction: prediction, bet: true)
                    } label: {
                        Text("\u{1F44D} Yes")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 0.5))
                    }
                    .disabled(submittingId == prediction.id)

                    Button {
                        submitBet(prediction: prediction, bet: false)
                    } label: {
                        Text("\u{1F44E} No")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.2))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.red.opacity(0.3), lineWidth: 0.5))
                    }
                    .disabled(submittingId == prediction.id)

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(prediction.userBet != nil ? accentColor.opacity(0.15) : Theme.cardBorder, lineWidth: 0.5)
        )
        .padding(.horizontal, Theme.pagePadding)
    }

    private func submitBet(prediction: Prediction, bet: Bool) {
        guard let userId = authManager.currentUser?.id else { return }
        submittingId = prediction.id

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Task {
            do {
                _ = try await SupabaseManager.shared.submitPredictionBet(
                    userId: userId, predictionId: prediction.id, bet: bet
                )
                if let idx = predictions.firstIndex(where: { $0.id == prediction.id }) {
                    withAnimation(.spring(response: 0.3)) {
                        predictions[idx].userBet = bet
                    }
                }
            } catch {
                print("Prediction bet error: \(error)")
            }
            submittingId = nil
        }
    }

    private func loadPredictions() async {
        guard let user = authManager.currentUser else { return }
        do {
            predictions = try await SupabaseManager.shared.fetchTodayPredictions(userId: user.id)
        } catch {
            print("Load predictions error: \(error)")
        }
        isLoading = false
    }
}
