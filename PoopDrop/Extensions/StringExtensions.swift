import Foundation

extension String {
    /// Returns the word count of the string
    var wordCount: Int {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .split { $0 == " " || $0.isNewline || $0 == "\t" }.count
    }
    
    /// Truncates string to character limit (for Free users)
    func truncatedToCharacterLimit(_ limit: Int) -> String {
        count <= limit ? self : String(prefix(limit))
    }
    
    /// Truncates string to word limit (for Pro users)
    func truncatedToWordLimit(_ wordLimit: Int) -> String {
        let words = trimmingCharacters(in: .whitespacesAndNewlines)
            .split { $0 == " " || $0.isNewline || $0 == "\t" }
        return words.count > wordLimit
            ? words.prefix(wordLimit).joined(separator: " ")
            : self
    }
    
    /// Validates if string is within Free user character limit
    func isWithinFreeCharacterLimit() -> Bool {
        count <= Constants.freeCharacterLimit
    }
    
    /// Validates if string is within Pro user word limit
    func isWithinProWordLimit() -> Bool {
        wordCount <= Constants.proWordLimit
    }
}

// MARK: - Constants
extension String {
    struct Constants {
        static let freeCharacterLimit = 50
        static let proWordLimit = 200
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
extension String {
    /// Returns the word count of the string
    var wordCount: Int {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .split { $0 == " " || $0.isNewline || $0 == "\t" }.count
    }
    
    /// Truncates string to character limit (for Free users)
    func truncatedToCharacterLimit(_ limit: Int) -> String {
        count <= limit ? self : String(prefix(limit))
    }
    
    /// Truncates string to word limit (for Pro users)
    func truncatedToWordLimit(_ wordLimit: Int) -> String {
        let words = trimmingCharacters(in: .whitespacesAndNewlines)
            .split { $0 == " " || $0.isNewline || $0 == "\t" }
        return words.count > wordLimit
            ? words.prefix(wordLimit).joined(separator: " ")
            : self
    }
    
    /// Validates if string is within Free user character limit
    func isWithinFreeCharacterLimit() -> Bool {
        count <= Constants.freeCharacterLimit
    }
    
    /// Validates if string is within Pro user word limit
    func isWithinProWordLimit() -> Bool {
        wordCount <= Constants.proWordLimit
    }
}

// MARK: - Constants
extension String {
    struct Constants {
        static let freeCharacterLimit = 50
        static let proWordLimit = 200
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
