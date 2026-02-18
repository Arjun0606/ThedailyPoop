import SwiftUI

@MainActor
class WordDropManager: ObservableObject {
    @Published var currentGame: WordGame?
    @Published var selectedIndices: [Int] = []
    @Published var currentWord: String = ""
    @Published var foundWords: [String] = []
    @Published var score: Int = 0
    @Published var timeRemaining: Int = 90
    @Published var isPlaying: Bool = false
    @Published var isGameOver: Bool = false
    @Published var submitResult: WordGameSubmitResponse?
    @Published var invalidWordShake: Bool = false
    @Published var duplicateWordShake: Bool = false
    @Published private(set) var shuffledLetters: [String] = []

    private var timer: Timer?

    func startGame(game: WordGame) {
        currentGame = game
        shuffledLetters = game.letters.shuffled()
        selectedIndices = []
        currentWord = ""
        foundWords = []
        score = 0
        timeRemaining = 90
        isPlaying = true
        isGameOver = false
        submitResult = nil
        startTimer()
    }

    func selectLetter(at index: Int) {
        guard isPlaying, index < shuffledLetters.count else { return }

        // Tap selected letter to deselect it (and all after it)
        if let pos = selectedIndices.firstIndex(of: index) {
            selectedIndices.removeSubrange(pos...)
            currentWord = selectedIndices.map { shuffledLetters[$0] }.joined()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        selectedIndices.append(index)
        currentWord = selectedIndices.map { shuffledLetters[$0] }.joined()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func deselectLastLetter() {
        guard !selectedIndices.isEmpty else { return }
        selectedIndices.removeLast()
        currentWord = selectedIndices.map { shuffledLetters[$0] }.joined()
    }

    func clearCurrentWord() {
        selectedIndices = []
        currentWord = ""
    }

    func submitWord() {
        let word = currentWord.lowercased()
        guard word.count >= 3 else {
            invalidWordShake = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.invalidWordShake = false }
            return
        }

        if foundWords.contains(word) {
            duplicateWordShake = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.duplicateWordShake = false }
            clearCurrentWord()
            return
        }

        foundWords.append(word)
        clearCurrentWord()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func shuffleLetters() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            shuffledLetters.shuffle()
        }
        clearCurrentWord()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    if self.timeRemaining <= 10 && self.timeRemaining > 0 {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    }
                } else {
                    self.endGame()
                }
            }
        }
    }

    func endGame() {
        isPlaying = false
        isGameOver = true
        timer?.invalidate()
        timer = nil
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    func submitToServer(userId: String) async {
        guard let game = currentGame else { return }
        do {
            let result = try await SupabaseManager.shared.submitGameScore(
                userId: userId,
                gameId: game.id,
                wordsFound: foundWords,
                timeRemaining: timeRemaining
            )
            submitResult = result
            score = result.score
        } catch {
            print("Failed to submit game: \(error)")
            // Build a local fallback result so the user still sees their words
            submitResult = WordGameSubmitResponse(
                score: 0,
                wordCount: foundWords.count,
                validatedWords: foundWords,
                foundKeyWord: false,
                keyWord: "???",
                totalPossibleWords: 0,
                totalPossibleScore: 0
            )
        }
    }

    func cleanup() {
        timer?.invalidate()
        timer = nil
    }
}
