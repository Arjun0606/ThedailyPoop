import Foundation

struct HeadlineRouletteGame: Identifiable, Codable {
    let id: String
    let publishDate: String
    let headlines: [RouletteHeadline]
    var played: Bool
    var userScore: RouletteUserScore?
}

struct RouletteHeadline: Identifiable, Codable {
    let id: String
    let headline: String
    let insanityRank: Int
}

struct RouletteUserScore: Codable {
    let score: Int
    let maxScore: Int
}

struct RouletteSubmitResponse: Codable {
    let score: Int
    let maxScore: Int
    let correctOrder: [RouletteHeadline]
}
