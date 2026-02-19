import Foundation

struct ScoopGame: Identifiable, Codable {
    let id: String
    let publishDate: String
    let headlines: [ScoopHeadline]
    let headlineCount: Int
    var played: Bool
    var userScore: ScoopUserScore?
}

struct ScoopHeadline: Codable {
    let headline: String
}

struct ScoopUserScore: Codable {
    let score: Int
    let total: Int
    let answers: [ScoopAnswer]
}

struct ScoopAnswer: Codable {
    let headline: String
    let guessedReal: Bool
    let wasReal: Bool
    let correct: Bool
}

struct ScoopSubmitResponse: Codable {
    let score: Int
    let total: Int
    let answers: [ScoopAnswer]
    let allHeadlines: [ScoopRevealedHeadline]
}

struct ScoopRevealedHeadline: Codable {
    let headline: String
    let isReal: Bool
}
