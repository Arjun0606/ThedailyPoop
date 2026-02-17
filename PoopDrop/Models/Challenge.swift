import Foundation

struct Challenge: Identifiable, Codable {
    let id: String
    let groupID: String
    let prompt: String
    let challengeType: String
    let options: [String]?

    init(id: String = UUID().uuidString,
         groupID: String,
         prompt: String,
         challengeType: String = "vote",
         options: [String]? = nil) {
        self.id = id
        self.groupID = groupID
        self.prompt = prompt
        self.challengeType = challengeType
        self.options = options
    }
}
