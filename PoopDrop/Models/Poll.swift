import Foundation
import CloudKit

// MARK: - Poll Model
struct Poll: Identifiable, Codable {
    let id: String
    let creatorID: String
    let creatorUsername: String
    let questionText: String
    let pollType: PollType
    let createdAt: Date
    let endsAt: Date // Midnight of the day it was created
    var isActive: Bool // Whether poll is still accepting votes
    var totalVotes: Int // How many people voted
    
    init(id: String = UUID().uuidString,
         creatorID: String,
         creatorUsername: String,
         questionText: String,
         pollType: PollType,
         createdAt: Date = Date(),
         endsAt: Date,
         isActive: Bool = true,
         totalVotes: Int = 0) {
        self.id = id
        self.creatorID = creatorID
        self.creatorUsername = creatorUsername
        self.questionText = questionText
        self.pollType = pollType
        self.createdAt = createdAt
        self.endsAt = endsAt
        self.isActive = isActive
        self.totalVotes = totalVotes
    }
}

enum PollType: String, Codable, CaseIterable {
    case prediction = "Prediction" // "Who is most likely to..."
    case battle = "Battle" // "Who would win: X vs Y"
    
    var emoji: String {
        switch self {
        case .prediction: return "🔮"
        case .battle: return "⚔️"
        }
    }
}

// MARK: - CloudKit Extensions
extension Poll {
    static let recordType = "Poll"
    
    init?(from record: CKRecord) {
        guard let creatorID = record["creatorID"] as? String,
              let creatorUsername = record["creatorUsername"] as? String,
              let questionText = record["questionText"] as? String,
              let pollTypeString = record["pollType"] as? String,
              let pollType = PollType(rawValue: pollTypeString),
              let createdAt = record["createdAt"] as? Date,
              let endsAt = record["endsAt"] as? Date else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.creatorID = creatorID
        self.creatorUsername = creatorUsername
        self.questionText = questionText
        self.pollType = pollType
        self.createdAt = createdAt
        self.endsAt = endsAt
        self.isActive = (record["isActive"] as? Int) == 1
        self.totalVotes = record["totalVotes"] as? Int ?? 0
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Poll.recordType, recordID: CKRecord.ID(recordName: id))
        record["creatorID"] = creatorID
        record["creatorUsername"] = creatorUsername
        record["questionText"] = questionText
        record["pollType"] = pollType.rawValue
        record["createdAt"] = createdAt
        record["endsAt"] = endsAt
        record["isActive"] = isActive ? 1 : 0
        record["totalVotes"] = totalVotes
        return record
    }
}

// MARK: - Poll Vote Model
struct PollVote: Identifiable, Codable {
    let id: String
    let pollID: String
    let voterID: String
    let voterUsername: String
    let votedForID: String // The friend they voted for
    let votedForUsername: String
    let timestamp: Date
    
    init(id: String = UUID().uuidString,
         pollID: String,
         voterID: String,
         voterUsername: String,
         votedForID: String,
         votedForUsername: String,
         timestamp: Date = Date()) {
        self.id = id
        self.pollID = pollID
        self.voterID = voterID
        self.voterUsername = voterUsername
        self.votedForID = votedForID
        self.votedForUsername = votedForUsername
        self.timestamp = timestamp
    }
}

// MARK: - CloudKit Extensions
extension PollVote {
    static let recordType = "PollVote"
    
    init?(from record: CKRecord) {
        guard let pollID = record["pollID"] as? String,
              let voterID = record["voterID"] as? String,
              let voterUsername = record["voterUsername"] as? String,
              let votedForID = record["votedForID"] as? String,
              let votedForUsername = record["votedForUsername"] as? String,
              let timestamp = record["timestamp"] as? Date else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.pollID = pollID
        self.voterID = voterID
        self.voterUsername = voterUsername
        self.votedForID = votedForID
        self.votedForUsername = votedForUsername
        self.timestamp = timestamp
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: PollVote.recordType, recordID: CKRecord.ID(recordName: id))
        record["pollID"] = pollID
        record["voterID"] = voterID
        record["voterUsername"] = voterUsername
        record["votedForID"] = votedForID
        record["votedForUsername"] = votedForUsername
        record["timestamp"] = timestamp
        return record
    }
}

// MARK: - Poll Reveal Purchase (for seeing who voted)
struct PollRevealPurchase: Identifiable, Codable {
    let id: String
    let pollID: String
    let userID: String // Who purchased the reveal
    let purchaseDate: Date
    
    init(id: String = UUID().uuidString,
         pollID: String,
         userID: String,
         purchaseDate: Date = Date()) {
        self.id = id
        self.pollID = pollID
        self.userID = userID
        self.purchaseDate = purchaseDate
    }
}

// MARK: - CloudKit Extensions
extension PollRevealPurchase {
    static let recordType = "PollRevealPurchase"
    
    init?(from record: CKRecord) {
        guard let pollID = record["pollID"] as? String,
              let userID = record["userID"] as? String,
              let purchaseDate = record["purchaseDate"] as? Date else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.pollID = pollID
        self.userID = userID
        self.purchaseDate = purchaseDate
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: PollRevealPurchase.recordType, recordID: CKRecord.ID(recordName: id))
        record["pollID"] = pollID
        record["userID"] = userID
        record["purchaseDate"] = purchaseDate
        return record
    }
}

// MARK: - Poll Results (aggregated)
struct PollResults: Identifiable {
    let id = UUID()
    let poll: Poll
    var voteCounts: [String: Int] // [userID: voteCount]
    var hasRevealedVoters: Bool
    var voters: [String] // List of userIDs who voted for you (if revealed)
    
    func topWinner() -> (userID: String, votes: Int)? {
        guard let winner = voteCounts.max(by: { $0.value < $1.value }) else {
            return nil
        }
        return (userID: winner.key, votes: winner.value)
    }
}

// MARK: - Pre-written Poll Questions
struct PollQuestionBank {
    static let predictions = [
        "Who's most likely to forget to flush? 🚽",
        "Who has the funniest bathroom stories? 😂",
        "Who spends the longest time on the toilet? ⏰",
        "Who's the poop champion? 👑",
        "Who would survive the longest without pooping? 💪",
        "Who's most likely to clog the toilet? 🚨",
        "Who poops at the most random places? 🗺️",
        "Who's most regular? 📅",
        "Who has the worst fart smell? 💨",
        "Who's most likely to ghost fart in public? 👻"
    ]
    
    static let battles = [
        "Fart loudness: Who wins? 💨⚡",
        "Most drops in a week: Who wins? 💩",
        "Toilet humor: Who's funnier? 😂",
        "Most likely to brag about poops: Who wins? 🏆",
        "Best bathroom music taste: Who wins? 🎵"
    ]
    
    static func randomQuestion(type: PollType) -> String {
        switch type {
        case .prediction:
            return predictions.randomElement() ?? predictions[0]
        case .battle:
            return battles.randomElement() ?? battles[0]
        }
    }
}

