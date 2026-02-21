import Foundation

struct WhoSaidItGame: Identifiable, Codable {
    let id: String
    let publishDate: String
    let rounds: [WhoSaidItRound]
    var played: Bool
    var userScore: WhoSaidItUserScore?
}

struct WhoSaidItRound: Codable {
    let quote: String
    let correctAnswer: String
    let options: [String]
}

struct WhoSaidItUserScore: Codable {
    let score: Int
    let total: Int
}

struct WhoSaidItSubmitResponse: Codable {
    let score: Int
    let total: Int
    let results: [WhoSaidItResult]
}

struct WhoSaidItResult: Codable {
    let quote: String
    let correctAnswer: String
    let userAnswer: String
    let correct: Bool
}
