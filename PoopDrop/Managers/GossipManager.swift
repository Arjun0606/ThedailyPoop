import Foundation
import CloudKit

@MainActor
class GossipManager: ObservableObject {
    static let shared = GossipManager()
    
    @Published var todaysGossip: [GossipPost] = []
    @Published var myReveals: [String: GossipReveal] = [:] // [gossipID: reveal]
    @Published var isLoading = false
    
    private let cloudKitManager = CloudKitManager.shared
    
    private init() {}
    
    // MARK: - Load Today's Gossip
    
    func loadTodaysGossip() async {
        isLoading = true
        
        // Get start of today (last 24 hours)
        let yesterday = Date().addingTimeInterval(-86400)
        
        // Fetch all gossip from last 24 hours
        let predicate = NSPredicate(format: "createdAt >= %@", yesterday as NSDate)
        let query = CKQuery(recordType: "GossipPost", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            let results = try await database.records(matching: query, resultsLimit: 100)
            
            var gossipPosts: [GossipPost] = []
            for result in results.matchResults {
                if let record = try? result.1.get(), let gossip = GossipPost(from: record) {
                    // Only show non-expired gossip
                    if gossip.expiresAt > Date() {
                        gossipPosts.append(gossip)
                    }
                }
            }
            
            self.todaysGossip = gossipPosts
            print("📰 Loaded \(gossipPosts.count) gossip posts")
        } catch {
            print("❌ Error loading gossip: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Post Gossip
    
    func postGossip(text: String, poster: User, mentionedFriends: [User]) async {
        // Detect mentions
        let mentionedUserIDs = mentionedFriends.map { $0.id }
        let mentionedUsernames = mentionedFriends.map { $0.username }
        
        let gossip = GossipPost(
            posterID: poster.id,
            posterUsername: poster.username,
            text: text,
            mentionedUserIDs: mentionedUserIDs,
            mentionedUsernames: mentionedUsernames
        )
        
        do {
            let record = gossip.toCKRecord()
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            _ = try await database.save(record)
            
            // Add to local array
            self.todaysGossip.insert(gossip, at: 0)
            print("✅ Posted gossip: \(text)")
            
            // 📢 ENGAGEMENT HOOK: Notify mentioned users
            if !mentionedFriends.isEmpty {
                await NotificationManager.shared.sendGossipMentionNotification(
                    gossipText: text,
                    to: mentionedFriends
                )
            }
            
            // Notify all friends about new gossip
            do {
                let friends = try await CloudKitManager.shared.fetchFriends(for: poster)
                await NotificationManager.shared.sendNewGossipNotification(
                    gossipText: text,
                    to: friends
                )
            } catch {
                print("⚠️ Failed to notify friends of new gossip: \(error)")
            }
        } catch {
            print("❌ Error posting gossip: \(error)")
        }
    }
    
    // MARK: - Add Reaction
    
    func addReaction(to gossipID: String, emoji: String) async {
        guard let index = todaysGossip.firstIndex(where: { $0.id == gossipID }) else { return }
        
        var gossip = todaysGossip[index]
        gossip.reactions[emoji, default: 0] += 1
        
        // Update in CloudKit
        do {
            let record = gossip.toCKRecord()
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            _ = try await database.save(record)
            
            // Update local array
            todaysGossip[index] = gossip
            print("✅ Added reaction \(emoji) to gossip")
        } catch {
            print("❌ Error adding reaction: \(error)")
        }
    }
    
    // MARK: - Post Reply
    
    func postReply(to gossipID: String, replyText: String, replier: User, isAnonymous: Bool) async {
        let reply = GossipReply(
            originalGossipID: gossipID,
            replyText: replyText,
            replierID: replier.id,
            replierUsername: replier.username,
            isAnonymous: isAnonymous
        )
        
        do {
            let record = reply.toCKRecord()
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            _ = try await database.save(record)
            
            // Update reply count on original gossip
            if let index = todaysGossip.firstIndex(where: { $0.id == gossipID }) {
                var gossip = todaysGossip[index]
                gossip.replyCount += 1
                
                let gossipRecord = gossip.toCKRecord()
                _ = try await database.save(gossipRecord)
                todaysGossip[index] = gossip
            }
            
            print("✅ Posted reply: \(replyText)")
        } catch {
            print("❌ Error posting reply: \(error)")
        }
    }
    
    // MARK: - Load Replies
    
    func loadReplies(for gossipID: String) async -> [GossipReply] {
        let predicate = NSPredicate(format: "originalGossipID == %@", gossipID)
        let query = CKQuery(recordType: "GossipReply", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        do {
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            let results = try await database.records(matching: query)
            
            var replies: [GossipReply] = []
            for result in results.matchResults {
                if let record = try? result.1.get(), let reply = GossipReply(from: record) {
                    replies.append(reply)
                }
            }
            
            print("✅ Loaded \(replies.count) replies")
            return replies
        } catch {
            print("❌ Error loading replies: \(error)")
            return []
        }
    }
    
    // MARK: - Reveal Sender (IAP)
    
    func revealSender(gossipID: String, currentUser: User) async -> (revealed: Bool, sender: String?) {
        // Check if already revealed
        if let existingReveal = myReveals[gossipID] {
            return (true, existingReveal.revealedPosterUsername)
        }
        
        // Find the gossip
        guard let gossip = todaysGossip.first(where: { $0.id == gossipID }) else {
            return (false, nil)
        }
        
        // Create reveal record
        let reveal = GossipReveal(
            gossipID: gossipID,
            revealedToUserID: currentUser.id,
            revealedPosterID: gossip.posterID,
            revealedPosterUsername: gossip.posterUsername,
            paidAmount: 1.99
        )
        
        do {
            let record = reveal.toCKRecord()
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            _ = try await database.save(record)
            
            // Save locally
            myReveals[gossipID] = reveal
            
            print("✅ Revealed sender: \(gossip.posterUsername)")
            return (true, gossip.posterUsername)
        } catch {
            print("❌ Error saving reveal: \(error)")
            return (false, nil)
        }
    }
    
    // MARK: - Load My Reveals
    
    func loadMyReveals(for userID: String) async {
        let predicate = NSPredicate(format: "revealedToUserID == %@", userID)
        let query = CKQuery(recordType: "GossipReveal", predicate: predicate)
        
        do {
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            let results = try await database.records(matching: query)
            
            var reveals: [String: GossipReveal] = [:]
            for result in results.matchResults {
                if let record = try? result.1.get(), let reveal = GossipReveal(from: record) {
                    reveals[reveal.gossipID] = reveal
                }
            }
            
            self.myReveals = reveals
            print("✅ Loaded \(reveals.count) reveals")
        } catch {
            print("❌ Error loading reveals: \(error)")
        }
    }
    
    // MARK: - Increment View Count
    
    func incrementViewCount(for gossipID: String) async {
        guard let index = todaysGossip.firstIndex(where: { $0.id == gossipID }) else { return }
        
        var gossip = todaysGossip[index]
        gossip.viewCount += 1
        
        do {
            let record = gossip.toCKRecord()
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            _ = try await database.save(record)
            
            todaysGossip[index] = gossip
        } catch {
            print("❌ Error incrementing view count: \(error)")
        }
    }
    
    // MARK: - Detect Mentions
    
    func detectMentions(in text: String, from friends: [User]) -> [User] {
        var mentionedFriends: [User] = []
        
        for friend in friends {
            if text.contains("@\(friend.username)") {
                mentionedFriends.append(friend)
            }
        }
        
        return mentionedFriends
    }
}

