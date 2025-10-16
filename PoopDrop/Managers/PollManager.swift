import Foundation
import CloudKit

@MainActor
class PollManager: ObservableObject {
    static let shared = PollManager()
    
    @Published var todaysPoll: Poll?
    @Published var myVotes: [PollVote] = []
    @Published var hasVotedToday = false
    
    private let cloudKitManager = CloudKitManager.shared
    
    private init() {}
    
    // MARK: - Load Today's Poll
    
    func loadTodaysPoll(for user: User) async {
        // Get start of today
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        // Fetch today's poll
        let predicate = NSPredicate(format: "createdAt >= %@ AND isActive == 1", startOfToday as NSDate)
        let query = CKQuery(recordType: "Poll", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            let results = try await database.records(matching: query, resultsLimit: 1)
            
            if let record = try? results.matchResults.first?.1.get(), let poll = Poll(from: record) {
                self.todaysPoll = poll
                print("📊 Loaded today's poll: \(poll.questionText)")
                
                // Check if user has voted
                await checkIfUserVoted(userID: user.id, pollID: poll.id)
            } else {
                // No poll today - users can create one
                print("📊 No poll found for today")
            }
        } catch {
            print("❌ Error loading today's poll: \(error)")
        }
    }
    
    // MARK: - Create User Poll
    
    func createPoll(creator: User, questionText: String) async {
        // Calculate end of day
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date()) ?? Date()
        
        let poll = Poll(
            creatorID: creator.id,
            creatorUsername: creator.username,
            questionText: questionText,
            pollType: .prediction,
            endsAt: endOfDay
        )
        
        do {
            let record = poll.toCKRecord()
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            _ = try await database.save(record)
            
            self.todaysPoll = poll
            print("✅ Created poll by \(creator.username): \(questionText)")
            
            // 📊 ENGAGEMENT HOOK: Notify friends about the new poll
            do {
                let friends = try await CloudKitManager.shared.fetchFriends(for: creator)
                await NotificationManager.shared.sendNewPollNotification(
                    creator: creator,
                    pollQuestion: questionText,
                    to: friends
                )
            } catch {
                print("⚠️ Failed to notify friends of new poll: \(error)")
            }
        } catch {
            print("❌ Error creating poll: \(error)")
        }
    }
    
    // MARK: - Vote on Poll
    
    func vote(pollID: String, friend: User, voter: User) async {
        let vote = PollVote(
            pollID: pollID,
            voterID: voter.id,
            voterUsername: voter.username,
            votedForID: friend.id,
            votedForUsername: friend.username
        )
        
        do {
            let record = vote.toCKRecord()
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            _ = try await database.save(record)
            
            myVotes.append(vote)
            print("✅ Voted for friend: \(friend.username)")
            
            // Check if we've voted 3 times
            if myVotes.count >= 3 {
                hasVotedToday = true
            }
        } catch {
            print("❌ Error saving vote: \(error)")
        }
    }
    
    // MARK: - Check If User Voted
    
    func checkIfUserVoted(userID: String, pollID: String) async {
        let predicate = NSPredicate(format: "voterID == %@ AND pollID == %@", userID, pollID)
        let query = CKQuery(recordType: "PollVote", predicate: predicate)
        
        do {
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            let results = try await database.records(matching: query)
            
            let votes = results.matchResults.compactMap { try? $0.1.get() }.compactMap { PollVote(from: $0) }
            self.myVotes = votes
            self.hasVotedToday = votes.count >= 3
            
            print("📊 User has \(votes.count) votes for this poll")
        } catch {
            print("❌ Error checking votes: \(error)")
        }
    }
    
    // MARK: - Get Poll Results
    
    func getPollResults(pollID: String) async -> [(userID: String, votes: Int)] {
        let predicate = NSPredicate(format: "pollID == %@", pollID)
        let query = CKQuery(recordType: "PollVote", predicate: predicate)
        
        do {
            let container = CKContainer(identifier: "iCloud.com.poopdrop.app")
            let database = container.publicCloudDatabase
            let results = try await database.records(matching: query)
            
            let votes = results.matchResults.compactMap { try? $0.1.get() }.compactMap { PollVote(from: $0) }
            
            // Count votes per user
            var voteCounts: [String: Int] = [:]
            for vote in votes {
                voteCounts[vote.votedForID, default: 0] += 1
            }
            
            // Sort by vote count
            let sorted = voteCounts.sorted { $0.value > $1.value }
            print("📊 Poll results: \(sorted.count) users received votes")
            
            return sorted.map { (userID: $0.key, votes: $0.value) }
        } catch {
            print("❌ Error getting poll results: \(error)")
            return []
        }
    }
}

