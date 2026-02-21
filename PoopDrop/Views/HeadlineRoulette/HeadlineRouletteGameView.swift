import SwiftUI

struct HeadlineRouletteGameView: View {
    let game: HeadlineRouletteGame
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var orderedHeadlines: [RouletteHeadline] = []
    @State private var showResult = false
    @State private var result: RouletteSubmitResponse?
    @State private var isSubmitting = false
    @State private var draggedItem: RouletteHeadline?

    private let accentColor = Color.cyan

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HEADLINE ROULETTE")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(accentColor)
                            .tracking(2)
                        Text("Rank most to least insane")
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

                if showResult, let result {
                    resultView(result)
                } else {
                    rankingView
                }
            }
        }
        .onAppear {
            orderedHeadlines = game.headlines.shuffled()
        }
    }

    // MARK: - Ranking View
    private var rankingView: some View {
        VStack(spacing: 16) {
            // Instructions
            VStack(spacing: 6) {
                Text("\u{1F92F} MOST INSANE")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(accentColor)
                    .tracking(1)

                Text("Drag to reorder")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }

            // Draggable headlines list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(orderedHeadlines.enumerated()), id: \.element.id) { index, headline in
                        HStack(spacing: 12) {
                            // Rank number
                            Text("#\(index + 1)")
                                .font(.system(size: 14, weight: .black).monospacedDigit())
                                .foregroundStyle(rankColor(index))
                                .frame(width: 32)

                            Text(headline.headline)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(14)
                        .background(Theme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.cardBorder, lineWidth: 0.5)
                        )
                        .onDrag {
                            draggedItem = headline
                            return NSItemProvider(object: headline.id as NSString)
                        }
                        .onDrop(of: [.text], delegate: HeadlineDropDelegate(
                            item: headline,
                            items: $orderedHeadlines,
                            draggedItem: $draggedItem
                        ))
                    }
                }
                .padding(.horizontal, Theme.pagePadding)
            }

            VStack(spacing: 6) {
                Text("\u{1F634} LEAST INSANE")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)
            }

            // Submit button
            Button {
                submitRanking()
            } label: {
                Text("Lock It In")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isSubmitting)
            .padding(.horizontal, Theme.pagePadding)
            .padding(.bottom, 20)
        }
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return .red
        case 1: return .orange
        case 2: return Theme.accent
        case 3: return .blue
        default: return Theme.textTertiary
        }
    }

    private func submitRanking() {
        guard let userId = authManager.currentUser?.id else { return }
        isSubmitting = true

        let ranking = orderedHeadlines.map { $0.id }

        Task {
            do {
                result = try await SupabaseManager.shared.submitHeadlineRoulette(
                    userId: userId, gameId: game.id, ranking: ranking
                )
                withAnimation { showResult = true }
            } catch {
                // Fallback: calculate score locally
                var score = 0
                for (idx, h) in orderedHeadlines.enumerated() {
                    let correctRank = h.insanityRank
                    let diff = abs((idx + 1) - correctRank)
                    score += max(0, 5 - diff)
                }
                result = RouletteSubmitResponse(
                    score: score,
                    maxScore: orderedHeadlines.count * 5,
                    correctOrder: game.headlines.sorted { $0.insanityRank < $1.insanityRank }
                )
                withAnimation { showResult = true }
            }
            isSubmitting = false
        }
    }

    // MARK: - Result View
    private func resultView(_ result: RouletteSubmitResponse) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(result.score)/\(result.maxScore)")
                        .font(.system(size: 56, weight: .black).monospacedDigit())
                        .foregroundStyle(.white)

                    let pct = Double(result.score) / Double(max(result.maxScore, 1))
                    Text(pct >= 0.8 ? "Insanity Expert!" : pct >= 0.5 ? "Good Instincts!" : "Wild Guesses!")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(pct >= 0.5 ? .green : accentColor)
                }
                .padding(.top, 20)

                ShareLink(
                    item: "Headline Roulette \(result.score)/\(result.maxScore)\n\nRank the insanity!\nTheDailyPoop"
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

                // Correct order reveal
                VStack(alignment: .leading, spacing: 12) {
                    Text("CORRECT ORDER")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(2)

                    ForEach(Array(result.correctOrder.enumerated()), id: \.element.id) { idx, headline in
                        HStack(spacing: 12) {
                            Text("#\(idx + 1)")
                                .font(.system(size: 14, weight: .black).monospacedDigit())
                                .foregroundStyle(rankColor(idx))
                                .frame(width: 32)

                            Text(headline.headline)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)

                            Spacer()
                        }
                        .padding(12)
                        .background(Theme.elevatedBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .padding(.horizontal, Theme.pagePadding)

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
}

// MARK: - Drop Delegate for drag-to-reorder
struct HeadlineDropDelegate: DropDelegate {
    let item: RouletteHeadline
    @Binding var items: [RouletteHeadline]
    @Binding var draggedItem: RouletteHeadline?

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem,
              draggedItem.id != item.id,
              let fromIndex = items.firstIndex(where: { $0.id == draggedItem.id }),
              let toIndex = items.firstIndex(where: { $0.id == item.id })
        else { return }

        withAnimation(.spring(response: 0.3)) {
            items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
