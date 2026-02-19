import Foundation

struct WordGame: Identifiable, Codable {
    let id: String
    let briefingId: String
    let dropType: String
    let publishDate: String
    let letters: [String]
    let keyWordLength: Int
    let validWords: [String]?
    let storyHeadline: String
    let storyId: String?
    var played: Bool
    var userScore: WordGameUserScore?

    /// Set of valid words for instant client-side validation
    var validWordSet: Set<String> {
        Set(validWords ?? [])
    }
}

struct WordGameUserScore: Codable {
    let score: Int
    let wordsFound: [String]
    let wordCount: Int
    let foundKeyWord: Bool
}

struct WordGameSubmitResponse: Codable {
    let score: Int
    let wordCount: Int
    let validatedWords: [String]
    let foundKeyWord: Bool
    let keyWord: String
    let totalPossibleWords: Int
    let totalPossibleScore: Int
}

struct LeaderboardEntry: Identifiable, Codable {
    var id: String { "\(rank)-\(username)" }
    let rank: Int
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let score: Int
    let wordCount: Int
    let foundKeyWord: Bool
    let isPremium: Bool
}
