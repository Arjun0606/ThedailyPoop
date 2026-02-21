import SwiftUI

struct TheRoastGameView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    @State private var roast: RoastPrompt?
    @State private var isLoading = true
    @State private var roastText = ""
    @State private var isSubmitting = false
    @State private var submitResult: RoastSubmitResponse?
    @State private var showingResult = false
    @State private var showError = false

    private let accentColor = Color.red
    private let maxChars = 280

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("THE ROAST")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(accentColor)
                            .tracking(2)
                        Text("Write the funniest one-liner")
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
                } else if let roast {
                    if showingResult, let submitResult {
                        resultView(submitResult)
                    } else if roast.userEntry != nil {
                        alreadySubmittedView(roast)
                    } else {
                        roastInputView(roast)
                    }
                } else {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("\u{1F525}")
                            .font(.system(size: 48))
                        Text("No roast today")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Check back tomorrow")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                }
            }
        }
        .task { await loadRoast() }
        .alert("Couldn't submit", isPresented: $showError) {
            Button("Try Again") { submitRoast() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Check your connection and try again.")
        }
    }

    // MARK: - Roast Input
    private func roastInputView(_ roast: RoastPrompt) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Story prompt
                VStack(spacing: 12) {
                    Text("\u{1F3AF} TODAY'S TARGET")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(accentColor)
                        .tracking(1.5)

                    Text(roast.storyHeadline)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text(roast.storySummary)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Theme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, Theme.pagePadding)

                // Input area
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR ROAST")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)

                    ZStack(alignment: .topLeading) {
                        if roastText.isEmpty {
                            Text("Write your funniest one-liner...")
                                .font(.body)
                                .foregroundStyle(Theme.textTertiary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }

                        TextEditor(text: $roastText)
                            .font(.body)
                            .foregroundStyle(.white)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80, maxHeight: 120)
                            .onChange(of: roastText) { _, newValue in
                                if newValue.count > maxChars {
                                    roastText = String(newValue.prefix(maxChars))
                                }
                            }
                    }
                    .padding(12)
                    .background(Theme.elevatedBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 0.5)
                    )

                    HStack {
                        Text("\(roastText.count)/\(maxChars)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(roastText.count > maxChars - 20 ? .orange : Theme.textTertiary)
                        Spacer()
                    }
                }
                .padding(.horizontal, Theme.pagePadding)

                // Submit
                Button {
                    submitRoast()
                } label: {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView().tint(.black)
                        }
                        Text(isSubmitting ? "Judging..." : "\u{1F525} Submit Roast")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(roastText.trimmingCharacters(in: .whitespaces).isEmpty ? accentColor.opacity(0.3) : accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(roastText.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                .padding(.horizontal, Theme.pagePadding)

                // Top roasts
                if let topEntries = roast.topEntries, !topEntries.isEmpty {
                    topRoastsSection(topEntries)
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Already Submitted
    private func alreadySubmittedView(_ roast: RoastPrompt) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // User's entry
                if let entry = roast.userEntry {
                    VStack(spacing: 12) {
                        Text("YOUR ROAST")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(accentColor)
                            .tracking(1.5)

                        Text("\u{201C}\(entry.text)\u{201D}")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        if let score = entry.aiScore {
                            HStack(spacing: 4) {
                                ForEach(0..<5) { i in
                                    Image(systemName: i < score ? "star.fill" : "star")
                                        .font(.caption)
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.caption2)
                            Text("\(entry.upvotes)")
                                .font(.caption.weight(.bold).monospacedDigit())
                        }
                        .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(accentColor.opacity(0.2), lineWidth: 0.5)
                    )
                    .padding(.horizontal, Theme.pagePadding)
                }

                // Top roasts
                if let topEntries = roast.topEntries, !topEntries.isEmpty {
                    topRoastsSection(topEntries)
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Top Roasts
    private func topRoastsSection(_ entries: [RoastEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\u{1F3C6} TOP ROASTS")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)
                Spacer()
            }

            ForEach(Array(entries.prefix(10).enumerated()), id: \.element.id) { idx, entry in
                HStack(alignment: .top, spacing: 12) {
                    Text("#\(idx + 1)")
                        .font(.system(size: 12, weight: .black).monospacedDigit())
                        .foregroundStyle(idx == 0 ? Theme.accent : Theme.textTertiary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.text)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)

                        HStack(spacing: 8) {
                            Text("@\(entry.username)")
                                .font(.caption2)
                                .foregroundStyle(Theme.textTertiary)

                            if let score = entry.aiScore {
                                HStack(spacing: 2) {
                                    ForEach(0..<min(score, 5), id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 7))
                                            .foregroundStyle(Theme.accent)
                                    }
                                }
                            }
                        }
                    }

                    Spacer()

                    Button {
                        guard let userId = authManager.currentUser?.id else { return }
                        Task {
                            try? await SupabaseManager.shared.upvoteRoast(userId: userId, entryId: entry.id)
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12, weight: .bold))
                            Text("\(entry.upvotes)")
                                .font(.caption2.weight(.bold).monospacedDigit())
                        }
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 36)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Theme.elevatedBg)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.horizontal, Theme.pagePadding)
    }

    // MARK: - Result View
    private func resultView(_ result: RoastSubmitResponse) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("\u{1F525}")
                        .font(.system(size: 56))

                    Text("\u{201C}\(result.entry.text)\u{201D}")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    // AI Score
                    HStack(spacing: 4) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < result.aiScore ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundStyle(Theme.accent)
                        }
                    }

                    Text(result.aiFeedback)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .padding(.top, 8)

                ShareLink(
                    item: "\u{1F525} The Roast \u{2014} \(result.aiScore)/5 \u{2B50}\n\n\u{201C}\(result.entry.text)\u{201D}\n\nCan you write a better one?\nTheDailyPoop \u{2014} news that hits different\nthedailypoop.app"
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Roast")
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(accentColor)
                    .clipShape(Capsule())
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

    // MARK: - Actions
    private func submitRoast() {
        guard let userId = authManager.currentUser?.id,
              let roastId = roast?.id else { return }
        isSubmitting = true

        Task {
            do {
                submitResult = try await SupabaseManager.shared.submitRoast(
                    userId: userId, roastId: roastId, text: roastText.trimmingCharacters(in: .whitespaces)
                )
                withAnimation { showingResult = true }
            } catch {
                withAnimation { showError = true }
            }
            isSubmitting = false
        }
    }

    private func loadRoast() async {
        guard let user = authManager.currentUser else { return }
        do {
            roast = try await SupabaseManager.shared.fetchTodayRoast(userId: user.id)
        } catch {
            print("Load roast error: \(error)")
        }
        isLoading = false
    }
}
