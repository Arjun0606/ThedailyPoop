import AVFoundation
import SwiftUI

@MainActor
class AudioBriefingManager: ObservableObject {
    static let shared = AudioBriefingManager()

    @Published var isPlaying = false
    @Published var currentStoryIndex = 0
    @Published var progress: Double = 0

    private let synthesizer = AVSpeechSynthesizer()
    private var delegate: SpeechDelegate?
    private var stories: [Story] = []
    private var totalUtterances = 0
    private var completedUtterances = 0

    private init() {
        let d = SpeechDelegate()
        self.delegate = d
        self.synthesizer.delegate = d

        d.onFinish = { [weak self] in
            Task { @MainActor in
                self?.handleUtteranceFinished()
            }
        }

        d.onCancel = { [weak self] in
            Task { @MainActor in
                self?.isPlaying = false
            }
        }
    }

    func startBriefing(stories: [Story]) {
        guard !stories.isEmpty else { return }
        stop()

        self.stories = stories
        self.currentStoryIndex = 0
        self.completedUtterances = 0
        self.totalUtterances = stories.count * 2 // headline + body per story
        self.isPlaying = true

        configureAudioSession()
        speakStory(at: 0)
    }

    func togglePlayPause() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPlaying = true
        } else if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
            isPlaying = false
        }
    }

    func skipForward() {
        guard currentStoryIndex < stories.count - 1 else {
            stop()
            return
        }
        synthesizer.stopSpeaking(at: .immediate)
        currentStoryIndex += 1
        completedUtterances = currentStoryIndex * 2
        speakStory(at: currentStoryIndex)
    }

    func skipBackward() {
        guard currentStoryIndex > 0 else {
            synthesizer.stopSpeaking(at: .immediate)
            speakStory(at: 0)
            return
        }
        synthesizer.stopSpeaking(at: .immediate)
        currentStoryIndex -= 1
        completedUtterances = currentStoryIndex * 2
        speakStory(at: currentStoryIndex)
    }

    func jumpToStory(at index: Int) {
        guard index < stories.count, !stories.isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        currentStoryIndex = index
        completedUtterances = index * 2
        speakStory(at: index)
        isPlaying = true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        currentStoryIndex = 0
        progress = 0
        stories = []
    }

    private func speakStory(at index: Int) {
        guard index < stories.count else {
            stop()
            return
        }

        let story = stories[index]

        // Speak headline with emphasis
        let headlineText = "Story \(index + 1). \(story.categoryLabel). \(story.headline)"
        let headlineUtterance = AVSpeechUtterance(string: headlineText)
        headlineUtterance.rate = 0.48
        headlineUtterance.pitchMultiplier = 1.1
        headlineUtterance.preUtteranceDelay = 0.3
        headlineUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        // Speak body
        let bodyUtterance = AVSpeechUtterance(string: story.bodyWithoutBottomLine)
        bodyUtterance.rate = 0.5
        bodyUtterance.pitchMultiplier = 1.0
        bodyUtterance.preUtteranceDelay = 0.5
        bodyUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        synthesizer.speak(headlineUtterance)
        synthesizer.speak(bodyUtterance)
    }

    private func handleUtteranceFinished() {
        completedUtterances += 1
        progress = Double(completedUtterances) / Double(max(1, totalUtterances))

        // Every 2 utterances = 1 story complete (headline + body)
        if completedUtterances % 2 == 0 {
            let nextIndex = completedUtterances / 2
            if nextIndex < stories.count {
                currentStoryIndex = nextIndex
                speakStory(at: nextIndex)
            } else {
                stop()
            }
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
}

// MARK: - Speech Delegate (non-MainActor)
private class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: (() -> Void)?
    var onCancel: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onCancel?()
    }
}
