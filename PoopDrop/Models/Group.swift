import Foundation

struct Group: Identifiable, Codable {
    let id: String
    var name: String
    var emoji: String
    var inviteCode: String
    var createdBy: String
    var maxMembers: Int
    var members: [User]?

    init(id: String = UUID().uuidString,
         name: String,
         emoji: String = "💩",
         inviteCode: String = "",
         createdBy: String,
         maxMembers: Int = 20,
         members: [User]? = nil) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.inviteCode = inviteCode
        self.createdBy = createdBy
        self.maxMembers = maxMembers
        self.members = members
    }
}

// MARK: - Sample Data
extension Group {
    static let sampleGroup = Group(
        name: "The Homies",
        emoji: "💩",
        inviteCode: "abc123",
        createdBy: "user123"
    )
}
