import Foundation

// MARK: - Gossip Post (Anonymous, group-scoped, 24h expiry)
struct GossipPost: Identifiable, Codable {
    let id: String
    let authorID: String      // Hidden until revealed via $1.99 purchase
    let groupID: String
    let content: String
    let createdAt: Date
    let expiresAt: Date

    var isExpired: Bool { Date() > expiresAt }

    init(id: String = UUID().uuidString,
         authorID: String,
         groupID: String,
         content: String,
         createdAt: Date = Date(),
         expiresAt: Date = Date().addingTimeInterval(86400)) {
        self.id = id
        self.authorID = authorID
        self.groupID = groupID
        self.content = content
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}

// MARK: - Gossip Reveal ($1.99 to find out who posted)
struct GossipReveal: Identifiable, Codable {
    let id: String
    let gossipID: String
    let revealedBy: String
    let priceCents: Int
    let revealedAt: Date

    init(id: String = UUID().uuidString,
         gossipID: String,
         revealedBy: String,
         priceCents: Int = 199,
         revealedAt: Date = Date()) {
        self.id = id
        self.gossipID = gossipID
        self.revealedBy = revealedBy
        self.priceCents = priceCents
        self.revealedAt = revealedAt
    }
}

// MARK: - Helper
extension Date {
    func timeAgoString() -> String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 { return "Just now" }
        else if interval < 3600 { return "\(Int(interval / 60))m ago" }
        else if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        else { return "\(Int(interval / 86400))d ago" }
    }
}
