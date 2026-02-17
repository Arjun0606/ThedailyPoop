import Foundation
import Supabase
import CoreLocation

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    @Published var drops: [Drop] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: Config.supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Config.supabaseAnonKey
        )
    }

    // MARK: - Auth

    /// Sign in with Apple via Supabase Auth
    func signInWithApple(idToken: String, nonce: String) async throws -> User {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        let uid = session.user.id.uuidString

        // Check if user profile exists
        if let existing = try await fetchUser(id: uid) {
            return existing
        }

        // Create new user profile (username will be set in profile setup)
        let newUser = User(id: uid, username: "", appleUserID: uid)
        try await saveUser(newUser)
        return newUser
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func getCurrentSession() async -> Supabase.Session? {
        try? await client.auth.session
    }

    // MARK: - Users

    func saveUser(_ user: User) async throws {
        struct UserRow: Encodable {
            let id: String
            let username: String
            let display_name: String?
            let avatar_url: String?
            let apple_user_id: String
            let total_drops: Int
        }

        let row = UserRow(
            id: user.id,
            username: user.username,
            display_name: user.displayName,
            avatar_url: user.avatarURL?.absoluteString,
            apple_user_id: user.appleUserID,
            total_drops: user.totalDrops
        )

        try await client.from("users")
            .upsert(row)
            .execute()
    }

    func fetchUser(id: String) async throws -> User? {
        struct UserRow: Decodable {
            let id: String
            let username: String
            let display_name: String?
            let avatar_url: String?
            let apple_user_id: String
            let total_drops: Int
            let created_at: String
        }

        let rows: [UserRow] = try await client.from("users")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value

        guard let row = rows.first else { return nil }
        return User(
            id: row.id,
            username: row.username,
            displayName: row.display_name,
            avatarURL: row.avatar_url.flatMap { URL(string: $0) },
            appleUserID: row.apple_user_id
        )
    }

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        struct CountRow: Decodable { let id: String }
        let rows: [CountRow] = try await client.from("users")
            .select("id")
            .eq("username", value: username)
            .limit(1)
            .execute()
            .value
        return rows.isEmpty
    }

    // MARK: - Groups

    func createGroup(name: String, emoji: String, createdBy: String) async throws -> Group {
        struct GroupInsert: Encodable {
            let name: String
            let emoji: String
            let created_by: String
        }

        struct GroupRow: Decodable {
            let id: String
            let name: String
            let emoji: String
            let created_by: String
            let invite_code: String
            let max_members: Int
            let created_at: String
        }

        let rows: [GroupRow] = try await client.from("groups")
            .insert(GroupInsert(name: name, emoji: emoji, created_by: createdBy))
            .select()
            .execute()
            .value

        guard let row = rows.first else { throw SupabaseError.noData }

        // Auto-join as admin
        try await joinGroup(groupID: row.id, userID: createdBy, role: "admin")

        return Group(
            id: row.id,
            name: row.name,
            emoji: row.emoji,
            inviteCode: row.invite_code,
            createdBy: row.created_by,
            maxMembers: row.max_members
        )
    }

    func joinGroup(groupID: String, userID: String, role: String = "member") async throws {
        struct MemberInsert: Encodable {
            let group_id: String
            let user_id: String
            let role: String
        }

        try await client.from("group_members")
            .insert(MemberInsert(group_id: groupID, user_id: userID, role: role))
            .execute()
    }

    func joinGroupByInviteCode(_ code: String, userID: String) async throws -> Group {
        struct GroupRow: Decodable {
            let id: String
            let name: String
            let emoji: String
            let invite_code: String
            let created_by: String
            let max_members: Int
        }

        let rows: [GroupRow] = try await client.from("groups")
            .select()
            .eq("invite_code", value: code.lowercased())
            .limit(1)
            .execute()
            .value

        guard let row = rows.first else { throw SupabaseError.groupNotFound }

        try await joinGroup(groupID: row.id, userID: userID)

        return Group(
            id: row.id,
            name: row.name,
            emoji: row.emoji,
            inviteCode: row.invite_code,
            createdBy: row.created_by,
            maxMembers: row.max_members
        )
    }

    func fetchMyGroups(userID: String) async throws -> [Group] {
        struct MemberRow: Decodable {
            let group_id: String
            let groups: GroupRow

            struct GroupRow: Decodable {
                let id: String
                let name: String
                let emoji: String
                let invite_code: String
                let created_by: String
                let max_members: Int
            }
        }

        let rows: [MemberRow] = try await client.from("group_members")
            .select("group_id, groups(id, name, emoji, invite_code, created_by, max_members)")
            .eq("user_id", value: userID)
            .execute()
            .value

        return rows.map { row in
            Group(
                id: row.groups.id,
                name: row.groups.name,
                emoji: row.groups.emoji,
                inviteCode: row.groups.invite_code,
                createdBy: row.groups.created_by,
                maxMembers: row.groups.max_members
            )
        }
    }

    func fetchGroupMembers(groupID: String) async throws -> [User] {
        struct MemberRow: Decodable {
            let users: UserRow

            struct UserRow: Decodable {
                let id: String
                let username: String
                let display_name: String?
                let avatar_url: String?
                let apple_user_id: String
                let total_drops: Int
            }
        }

        let rows: [MemberRow] = try await client.from("group_members")
            .select("users(id, username, display_name, avatar_url, apple_user_id, total_drops)")
            .eq("group_id", value: groupID)
            .execute()
            .value

        return rows.map { row in
            User(
                id: row.users.id,
                username: row.users.username,
                displayName: row.users.display_name,
                avatarURL: row.users.avatar_url.flatMap { URL(string: $0) },
                appleUserID: row.users.apple_user_id
            )
        }
    }

    func leaveGroup(groupID: String, userID: String) async throws {
        try await client.from("group_members")
            .delete()
            .eq("group_id", value: groupID)
            .eq("user_id", value: userID)
            .execute()
    }

    // MARK: - Drops (Core Feature)

    func saveDrop(_ drop: Drop) async throws {
        struct DropInsert: Encodable {
            let user_id: String
            let group_id: String?
            let caption: String?
            let latitude: Double
            let longitude: Double
            let location_name: String?
        }

        guard let coord = drop.location else { throw SupabaseError.noLocation }

        try await client.from("drops")
            .insert(DropInsert(
                user_id: drop.userID,
                group_id: drop.groupID,
                caption: drop.caption,
                latitude: coord.latitude,
                longitude: coord.longitude,
                location_name: drop.locationName
            ))
            .execute()

        // Update local array
        drops.insert(drop, at: 0)
    }

    func fetchDrops(groupID: String, limit: Int = 100) async throws -> [Drop] {
        struct DropRow: Decodable {
            let id: String
            let user_id: String
            let group_id: String?
            let caption: String?
            let latitude: Double
            let longitude: Double
            let location_name: String?
            let reactions: [String: Int]?
            let created_at: String
            let users: UserRef?

            struct UserRef: Decodable {
                let username: String
            }
        }

        let rows: [DropRow] = try await client.from("drops")
            .select("*, users(username)")
            .eq("group_id", value: groupID)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        let fetched = rows.map { row in
            Drop(
                id: row.id,
                userID: row.user_id,
                username: row.users?.username ?? "unknown",
                location: CLLocationCoordinate2D(latitude: row.latitude, longitude: row.longitude),
                locationName: row.location_name,
                caption: row.caption,
                groupID: row.group_id
            )
        }

        drops = fetched
        return fetched
    }

    func fetchAllDropsForUser(userID: String) async throws -> [Drop] {
        // Fetch drops across all groups the user is in
        struct DropRow: Decodable {
            let id: String
            let user_id: String
            let group_id: String?
            let caption: String?
            let latitude: Double
            let longitude: Double
            let location_name: String?
            let created_at: String
            let users: UserRef?

            struct UserRef: Decodable {
                let username: String
            }
        }

        let rows: [DropRow] = try await client.from("drops")
            .select("*, users(username)")
            .order("created_at", ascending: false)
            .limit(500)
            .execute()
            .value

        return rows.map { row in
            Drop(
                id: row.id,
                userID: row.user_id,
                username: row.users?.username ?? "unknown",
                location: CLLocationCoordinate2D(latitude: row.latitude, longitude: row.longitude),
                locationName: row.location_name,
                caption: row.caption,
                groupID: row.group_id
            )
        }
    }

    // MARK: - Gossip

    func postGossip(authorID: String, groupID: String, content: String) async throws {
        struct GossipInsert: Encodable {
            let author_id: String
            let group_id: String
            let content: String
        }

        try await client.from("gossip")
            .insert(GossipInsert(author_id: authorID, group_id: groupID, content: content))
            .execute()
    }

    func fetchGossip(groupID: String) async throws -> [GossipPost] {
        struct GossipRow: Decodable {
            let id: String
            let author_id: String
            let group_id: String
            let content: String
            let expires_at: String
            let created_at: String
        }

        let rows: [GossipRow] = try await client.from("gossip")
            .select()
            .eq("group_id", value: groupID)
            .gt("expires_at", value: ISO8601DateFormatter().string(from: Date()))
            .order("created_at", ascending: false)
            .execute()
            .value

        return rows.map { row in
            GossipPost(
                id: row.id,
                authorID: row.author_id,
                groupID: row.group_id,
                content: row.content,
                createdAt: ISO8601DateFormatter().date(from: row.created_at) ?? Date(),
                expiresAt: ISO8601DateFormatter().date(from: row.expires_at) ?? Date()
            )
        }
    }

    func revealGossip(gossipID: String, revealedBy userID: String) async throws -> String {
        // Insert reveal record
        struct RevealInsert: Encodable {
            let gossip_id: String
            let revealed_by: String
            let price_cents: Int
        }

        try await client.from("gossip_reveals")
            .insert(RevealInsert(gossip_id: gossipID, revealed_by: userID, price_cents: 199))
            .execute()

        // Fetch the author
        struct GossipRow: Decodable {
            let author_id: String
            let users: UserRef?
            struct UserRef: Decodable { let username: String }
        }

        let rows: [GossipRow] = try await client.from("gossip")
            .select("author_id, users:author_id(username)")
            .eq("id", value: gossipID)
            .limit(1)
            .execute()
            .value

        return rows.first?.users?.username ?? "unknown"
    }

    func hasRevealedGossip(gossipID: String, userID: String) async throws -> Bool {
        struct RevealRow: Decodable { let id: String }
        let rows: [RevealRow] = try await client.from("gossip_reveals")
            .select("id")
            .eq("gossip_id", value: gossipID)
            .eq("revealed_by", value: userID)
            .limit(1)
            .execute()
            .value
        return !rows.isEmpty
    }

    // MARK: - Challenges

    func fetchTodayChallenge(groupID: String) async throws -> Challenge? {
        struct ChallengeRow: Decodable {
            let id: String
            let group_id: String
            let prompt: String
            let challenge_type: String?
            let options: [String]?
            let expires_at: String
            let created_at: String
        }

        let today = Calendar.current.startOfDay(for: Date())

        let rows: [ChallengeRow] = try await client.from("challenges")
            .select()
            .eq("group_id", value: groupID)
            .gte("created_at", value: ISO8601DateFormatter().string(from: today))
            .neq("challenge_type", value: "weekly_recap")
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value

        guard let row = rows.first else { return nil }
        return Challenge(
            id: row.id,
            groupID: row.group_id,
            prompt: row.prompt,
            challengeType: row.challenge_type ?? "vote",
            options: row.options
        )
    }

    func respondToChallenge(challengeID: String, userID: String, response: String, votedFor: String? = nil) async throws {
        struct ResponseInsert: Encodable {
            let challenge_id: String
            let user_id: String
            let response: String
            let voted_for: String?
        }

        try await client.from("challenge_responses")
            .insert(ResponseInsert(
                challenge_id: challengeID,
                user_id: userID,
                response: response,
                voted_for: votedFor
            ))
            .execute()
    }

    // MARK: - Realtime

    func subscribeToDrops(groupID: String, onInsert: @escaping (Drop) -> Void) async {
        let channel = client.realtimeV2.channel("drops-\(groupID)")

        let insertions = channel.postgresChange(InsertAction.self, table: "drops")

        await channel.subscribe()

        Task {
            for await insert in insertions {
                guard let record = insert.record as? [String: Any],
                      let id = record["id"] as? String,
                      let userID = record["user_id"] as? String,
                      let lat = record["latitude"] as? Double,
                      let lon = record["longitude"] as? Double else { continue }

                let drop = Drop(
                    id: id,
                    userID: userID,
                    username: "friend", // Will be resolved on next fetch
                    location: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    locationName: record["location_name"] as? String,
                    caption: record["caption"] as? String,
                    groupID: record["group_id"] as? String
                )
                await MainActor.run { onInsert(drop) }
            }
        }
    }

    func subscribeToGossip(groupID: String, onInsert: @escaping (GossipPost) -> Void) async {
        let channel = client.realtimeV2.channel("gossip-\(groupID)")

        let insertions = channel.postgresChange(InsertAction.self, table: "gossip")

        await channel.subscribe()

        Task {
            for await insert in insertions {
                guard let record = insert.record as? [String: Any],
                      let id = record["id"] as? String,
                      let authorID = record["author_id"] as? String,
                      let content = record["content"] as? String else { continue }

                let post = GossipPost(
                    id: id,
                    authorID: authorID,
                    groupID: record["group_id"] as? String ?? groupID,
                    content: content
                )
                await MainActor.run { onInsert(post) }
            }
        }
    }

    // MARK: - Waitlist

    struct WaitlistResult {
        let position: Int
        let totalWaiting: Int
    }

    func joinWaitlist(userID: String, schoolName: String) async throws -> WaitlistResult {
        struct WaitlistInsert: Encodable {
            let user_id: String
            let school_name: String
        }

        try await client.from("waitlist")
            .upsert(WaitlistInsert(user_id: userID, school_name: schoolName))
            .execute()

        // Get position
        struct WaitlistRow: Decodable {
            let id: String
        }

        let all: [WaitlistRow] = try await client.from("waitlist")
            .select("id")
            .eq("school_name", value: schoolName)
            .execute()
            .value

        return WaitlistResult(position: max(1, all.count), totalWaiting: all.count)
    }

    // MARK: - Device Tokens (Push Notifications)

    func registerDeviceToken(userID: String, token: String) async throws {
        struct TokenInsert: Encodable {
            let user_id: String
            let token: String
            let platform: String
        }

        try await client.from("device_tokens")
            .upsert(TokenInsert(user_id: userID, token: token, platform: "ios"))
            .execute()
    }

    // MARK: - Account Deletion

    func deleteAccount(userID: String) async throws {
        // Delete drops
        try await client.from("drops")
            .delete()
            .eq("user_id", value: userID)
            .execute()

        // Delete gossip
        try await client.from("gossip")
            .delete()
            .eq("author_id", value: userID)
            .execute()

        // Leave all groups
        try await client.from("group_members")
            .delete()
            .eq("user_id", value: userID)
            .execute()

        // Delete user profile
        try await client.from("users")
            .delete()
            .eq("id", value: userID)
            .execute()
    }
}

// MARK: - Errors
enum SupabaseError: LocalizedError {
    case noData
    case groupNotFound
    case noLocation

    var errorDescription: String? {
        switch self {
        case .noData: return "No data returned"
        case .groupNotFound: return "Group not found. Check your invite code."
        case .noLocation: return "Location required to drop"
        }
    }
}

// MARK: - Config
enum Config {
    static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
    static let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
}
