import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

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

    func signInWithApple(idToken: String, nonce: String) async throws -> User {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        let uid = session.user.id.uuidString

        if let existing = try await fetchUser(id: uid) {
            return existing
        }

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
            let is_premium: Bool
            let streak_count: Int
        }

        let row = UserRow(
            id: user.id,
            username: user.username,
            display_name: user.displayName,
            avatar_url: user.avatarURL?.absoluteString,
            apple_user_id: user.appleUserID,
            is_premium: user.isPremium,
            streak_count: user.streakCount
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
            let is_premium: Bool?
            let streak_count: Int?
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
            appleUserID: row.apple_user_id,
            isPremium: row.is_premium ?? false,
            streakCount: row.streak_count ?? 0
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

    // MARK: - Briefings

    func fetchTodayBriefing() async throws -> Briefing? {
        let today = dateString(for: Date())

        let rows: [Briefing] = try await client.from("briefings")
            .select()
            .eq("publish_date", value: today)
            .eq("status", value: "published")
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    func fetchBriefingByDate(date: Date) async throws -> Briefing? {
        let dateStr = dateString(for: date)

        let rows: [Briefing] = try await client.from("briefings")
            .select()
            .eq("publish_date", value: dateStr)
            .eq("status", value: "published")
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    func fetchRecentBriefings(limit: Int = 30) async throws -> [Briefing] {
        let rows: [Briefing] = try await client.from("briefings")
            .select()
            .eq("status", value: "published")
            .order("publish_date", ascending: false)
            .limit(limit)
            .execute()
            .value

        return rows
    }

    // MARK: - Stories

    func fetchBriefingStories(briefingId: String) async throws -> [Story] {
        let rows: [Story] = try await client.from("stories")
            .select()
            .eq("briefing_id", value: briefingId)
            .order("sort_order", ascending: true)
            .execute()
            .value

        return rows
    }

    // MARK: - Reading Tracking

    func markStoryRead(userID: String, storyID: String) async throws {
        struct ReadInsert: Encodable {
            let user_id: String
            let story_id: String
        }

        try await client.from("user_reads")
            .upsert(ReadInsert(user_id: userID, story_id: storyID))
            .execute()
    }

    func fetchReadStoryIDs(userID: String, briefingId: String) async throws -> Set<String> {
        struct ReadRow: Decodable {
            let story_id: String
        }

        // Get story IDs for this briefing, then filter reads
        let storyRows: [Story] = try await client.from("stories")
            .select()
            .eq("briefing_id", value: briefingId)
            .execute()
            .value

        let storyIds = storyRows.map { $0.id }
        guard !storyIds.isEmpty else { return [] }

        let readRows: [ReadRow] = try await client.from("user_reads")
            .select("story_id")
            .eq("user_id", value: userID)
            .in("story_id", values: storyIds)
            .execute()
            .value

        return Set(readRows.map { $0.story_id })
    }

    // MARK: - Reader Globe (Live)

    private var readerChannel: RealtimeChannelV2?

    func pingReaderLocation(userId: String, storyId: String, username: String, storyHeadline: String) async throws {
        guard let url = URL(string: "\(Config.apiServerURL)/api/reader-ping") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "userId": userId,
            "storyId": storyId,
            "username": username,
            "storyHeadline": storyHeadline
        ])

        let (_, _) = try await URLSession.shared.data(for: request)
    }

    func fetchRecentReaderSessions(minutes: Int = 5) async throws -> [ReaderSession] {
        let cutoff = Date().addingTimeInterval(-Double(minutes * 60))
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let rows: [ReaderSession] = try await client.from("reader_sessions")
            .select()
            .gt("created_at", value: formatter.string(from: cutoff))
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value

        return rows
    }

    func subscribeToReaderSessions(onInsert: @escaping @Sendable (ReaderSession) -> Void) async {
        let channel = client.realtimeV2.channel("reader_sessions")

        let insertions = channel.postgresChange(InsertAction.self, table: "reader_sessions")

        try? await channel.subscribeWithError()

        self.readerChannel = channel

        Task {
            for await insertion in insertions {
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .iso8601
                    let session = try insertion.decodeRecord(as: ReaderSession.self, decoder: decoder)
                    onInsert(session)
                } catch {
                    print("Failed to decode reader session: \(error)")
                }
            }
        }
    }

    func unsubscribeFromReaderSessions() async {
        if let channel = readerChannel {
            await client.realtimeV2.removeChannel(channel)
            readerChannel = nil
        }
    }

    // MARK: - Reactions

    func fetchReactionCounts(storyId: String) async throws -> [String: Int] {
        struct ReactionRow: Decodable {
            let reaction: String
        }

        let rows: [ReactionRow] = try await client.from("story_reactions")
            .select("reaction")
            .eq("story_id", value: storyId)
            .execute()
            .value

        var counts: [String: Int] = [:]
        for row in rows {
            counts[row.reaction, default: 0] += 1
        }
        return counts
    }

    func fetchBulkReactionCounts(storyIds: [String]) async throws -> [String: Int] {
        struct ReactionRow: Decodable {
            let story_id: String
        }

        guard !storyIds.isEmpty else { return [:] }

        let rows: [ReactionRow] = try await client.from("story_reactions")
            .select("story_id")
            .in("story_id", values: storyIds)
            .execute()
            .value

        var counts: [String: Int] = [:]
        for row in rows {
            counts[row.story_id, default: 0] += 1
        }
        return counts
    }

    func fetchUserReaction(userId: String, storyId: String) async throws -> String? {
        struct ReactionRow: Decodable {
            let reaction: String
        }

        let rows: [ReactionRow] = try await client.from("story_reactions")
            .select("reaction")
            .eq("user_id", value: userId)
            .eq("story_id", value: storyId)
            .limit(1)
            .execute()
            .value

        return rows.first?.reaction
    }

    func toggleReaction(userId: String, storyId: String, reaction: String) async throws {
        // Check existing
        let existing = try await fetchUserReaction(userId: userId, storyId: storyId)

        if existing == reaction {
            // Remove reaction
            try await client.from("story_reactions")
                .delete()
                .eq("user_id", value: userId)
                .eq("story_id", value: storyId)
                .execute()
        } else if existing != nil {
            // Update to new reaction
            struct ReactionUpdate: Encodable {
                let reaction: String
            }
            try await client.from("story_reactions")
                .update(ReactionUpdate(reaction: reaction))
                .eq("user_id", value: userId)
                .eq("story_id", value: storyId)
                .execute()
        } else {
            // Insert new reaction
            struct ReactionInsert: Encodable {
                let user_id: String
                let story_id: String
                let reaction: String
            }
            try await client.from("story_reactions")
                .insert(ReactionInsert(user_id: userId, story_id: storyId, reaction: reaction))
                .execute()
        }
    }

    // MARK: - Bookmarks

    func isBookmarked(userId: String, storyId: String) async throws -> Bool {
        struct BookmarkRow: Decodable { let id: String }

        let rows: [BookmarkRow] = try await client.from("story_bookmarks")
            .select("id")
            .eq("user_id", value: userId)
            .eq("story_id", value: storyId)
            .limit(1)
            .execute()
            .value

        return !rows.isEmpty
    }

    func toggleBookmark(userId: String, storyId: String) async throws -> Bool {
        let bookmarked = try await isBookmarked(userId: userId, storyId: storyId)

        if bookmarked {
            try await client.from("story_bookmarks")
                .delete()
                .eq("user_id", value: userId)
                .eq("story_id", value: storyId)
                .execute()
            return false
        } else {
            struct BookmarkInsert: Encodable {
                let user_id: String
                let story_id: String
            }
            try await client.from("story_bookmarks")
                .insert(BookmarkInsert(user_id: userId, story_id: storyId))
                .execute()
            return true
        }
    }

    func fetchBookmarkedStories(userId: String) async throws -> [Story] {
        struct BookmarkRow: Decodable {
            let story_id: String
        }

        let bookmarks: [BookmarkRow] = try await client.from("story_bookmarks")
            .select("story_id")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        guard !bookmarks.isEmpty else { return [] }
        let storyIds = bookmarks.map { $0.story_id }

        let stories: [Story] = try await client.from("stories")
            .select()
            .in("id", values: storyIds)
            .execute()
            .value

        // Maintain bookmark order
        let storyMap = Dictionary(uniqueKeysWithValues: stories.map { ($0.id, $0) })
        return storyIds.compactMap { storyMap[$0] }
    }

    // MARK: - Avatar Upload (Supabase Storage)

    func uploadAvatar(userID: String, imageData: Data) async throws -> URL {
        let fileName = "\(userID).jpg"

        try await client.storage.from("avatars").upload(
            fileName,
            data: imageData,
            options: .init(contentType: "image/jpeg", upsert: true)
        )

        let publicURL = try client.storage.from("avatars").getPublicURL(path: fileName)
        return publicURL
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
        // Delete user reads
        try await client.from("user_reads")
            .delete()
            .eq("user_id", value: userID)
            .execute()

        // Delete preferences
        try await client.from("user_preferences")
            .delete()
            .eq("user_id", value: userID)
            .execute()

        // Delete device tokens
        try await client.from("device_tokens")
            .delete()
            .eq("user_id", value: userID)
            .execute()

        // Delete user profile
        try await client.from("users")
            .delete()
            .eq("id", value: userID)
            .execute()
    }

    // MARK: - Helpers

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        return formatter.string(from: date)
    }
}

// MARK: - Errors
enum SupabaseError: LocalizedError {
    case noData

    var errorDescription: String? {
        switch self {
        case .noData: return "No data returned"
        }
    }
}

// MARK: - Config
enum Config {
    static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
    static let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
    static let apiServerURL = Bundle.main.object(forInfoDictionaryKey: "API_SERVER_URL") as? String ?? "https://thedailypoop-api.vercel.app"
}
