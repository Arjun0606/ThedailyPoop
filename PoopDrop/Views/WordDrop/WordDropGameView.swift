import SwiftUI

struct WordDropGameView: View {
    let game: WordGame
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var manager = WordDropManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showResult = false
    @State private var lastWordFlash = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showResult, let result = manager.submitResult {
                WordDropResultView(
                    result: result,
                    game: game,
                    wordsFound: manager.foundWords,
                    onDismiss: { dismiss() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                gameContent
            }
        }
        .onAppear {
            manager.startGame(game: game)
        }
        .onDisappear {
            manager.cleanup()
        }
        .onChange(of: manager.isGameOver) { _, isOver in
            if isOver {
                Task {
                    if let userId = authManager.currentUser?.id {
                        await manager.submitToServer(userId: userId)
                    }
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showResult = true
                    }
                }
            }
        }
        .onChange(of: manager.foundWords.count) { _, _ in
            // Flash the word count when a new word is found
            withAnimation(.easeOut(duration: 0.15)) { lastWordFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeIn(duration: 0.15)) { lastWordFlash = false }
            }
        }
    }

    private var gameContent: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button {
                    manager.cleanup()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(Theme.cardBg)
                        .clipShape(Circle())
                }

                Spacer()

                // Timer
                timerView

                Spacer()

                // Word count
                VStack(spacing: 2) {
                    Text("\(manager.foundWords.count)")
                        .font(.system(size: 18, weight: .black).monospacedDigit())
                        .foregroundStyle(.white)
                        .scaleEffect(lastWordFlash ? 1.3 : 1.0)
                        .contentTransition(.numericText())
                    Text("words")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()

            // Key word hint
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.accent)
                Text("Find the \(game.keyWordLength)-letter key word for +50 bonus!")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.accent.opacity(0.1))
            .clipShape(Capsule())
            .padding(.bottom, 16)

            // Current word display
            currentWordView
                .padding(.bottom, 24)

            // Letter tiles grid
            letterGrid
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    manager.clearCurrentWord()
                } label: {
                    Label("Clear", systemImage: "delete.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.cardBorder, lineWidth: 0.5)
                        )
                }

                Button {
                    manager.shuffleLetters()
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.cardBorder, lineWidth: 0.5)
                        )
                }

                Button {
                    manager.submitWord()
                } label: {
                    Text("Submit")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(manager.currentWord.count >= 3 ? Theme.accent : Theme.accent.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(manager.currentWord.count < 3)
            }
            .padding(.horizontal, 20)

            // Found words
            foundWordsList
                .padding(.top, 12)

            Spacer(minLength: 20)
        }
    }

    // MARK: - Timer

    private var timerView: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 4)
            Circle()
                .trim(from: 0, to: Double(manager.timeRemaining) / 90.0)
                .stroke(
                    manager.timeRemaining <= 10 ? Color.red : Theme.accent,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: manager.timeRemaining)
            Text("\(manager.timeRemaining)")
                .font(.system(size: 20, weight: .black).monospacedDigit())
                .foregroundStyle(manager.timeRemaining <= 10 ? .red : .white)
        }
        .frame(width: 52, height: 52)
        .scaleEffect(manager.timeRemaining <= 10 && manager.timeRemaining > 0 && manager.timeRemaining % 2 == 0 ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: manager.timeRemaining)
    }

    // MARK: - Current Word

    private var currentWordView: some View {
        HStack(spacing: 4) {
            if manager.currentWord.isEmpty {
                Text("Tap letters to build a word")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
            } else {
                ForEach(Array(manager.currentWord.uppercased().enumerated()), id: \.offset) { index, char in
                    Text(String(char))
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 42)
                        .background(Theme.elevatedBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(height: 48)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: manager.currentWord)
        .offset(x: manager.invalidWordShake || manager.duplicateWordShake ? -8 : 0)
        .animation(
            .default.repeatCount(3, autoreverses: true).speed(6),
            value: manager.invalidWordShake || manager.duplicateWordShake
        )
    }

    // MARK: - Letter Grid

    private var letterGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(manager.shuffledLetters.enumerated()), id: \.offset) { index, letter in
                LetterTileView(
                    letter: letter,
                    isSelected: manager.selectedIndices.contains(index),
                    onTap: { manager.selectLetter(at: index) }
                )
            }
        }
    }

    // MARK: - Found Words

    private var foundWordsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(manager.foundWords.reversed(), id: \.self) { word in
                    Text(word.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Theme.cardBg)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Theme.cardBorder, lineWidth: 0.5)
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .animation(.spring(response: 0.3), value: manager.foundWords.count)
        }
        .frame(height: 36)
    }
}
