import Foundation

extension String {
    /// Returns the word count of the string
    var wordCount: Int {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .split { $0 == " " || $0.isNewline || $0 == "\t" }.count
    }
    
    /// Truncates string to word limit (200 words for all users now)
    func truncatedToWordLimit(_ wordLimit: Int = 200) -> String {
        let words = trimmingCharacters(in: .whitespacesAndNewlines)
            .split { $0 == " " || $0.isNewline || $0 == "\t" }
        return words.count > wordLimit
            ? words.prefix(wordLimit).joined(separator: " ")
            : self
    }
    
    /// Validates if string is within word limit (200 words for all users)
    func isWithinWordLimit() -> Bool {
        wordCount <= Constants.wordLimit
    }
}

// MARK: - Constants
extension String {
    struct Constants {
        static let wordLimit = 200  // All users get 200 words now
    }
}

// MARK: - Emoji Utilities
extension String {
    /// Checks if string contains only emojis
    var isOnlyEmojis: Bool {
        return !isEmpty && !contains { !$0.isEmoji }
    }
    
    /// Extracts emojis from string
    var emojis: [String] {
        return compactMap { $0.isEmoji ? String($0) : nil }
    }
}

extension Character {
    /// Checks if character is an emoji
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}