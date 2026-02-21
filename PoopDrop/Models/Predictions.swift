import Foundation

struct Prediction: Identifiable, Codable {
    let id: String
    let publishDate: String
    let question: String
    let context: String?
    let resolveBy: String
    let resolvedAnswer: Bool?
    var userBet: Bool?
}

struct PredictionBetResponse: Codable {
    let success: Bool
    let predictionId: String
    let bet: Bool
}

struct PredictionStats: Codable {
    let totalBets: Int
    let yesPct: Double
    let noPct: Double
}
