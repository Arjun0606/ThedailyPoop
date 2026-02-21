import Foundation

struct ExcuseGame: Identifiable, Codable {
    let id: String
    let publishDate: String
    let rounds: [ExcuseRound]
    var played: Bool
    var userScore: ExcuseUserScore?
}

struct ExcuseRound: Codable {
    let situation: String
    let correctExcuse: String
    let options: [String]
}

struct ExcuseUserScore: Codable {
    let score: Int
    let total: Int
}

struct ExcuseSubmitResponse: Codable {
    let score: Int
    let total: Int
    let results: [ExcuseResult]
}

struct ExcuseResult: Codable {
    let situation: String
    let correctExcuse: String
    let userAnswer: String
    let correct: Bool
}
