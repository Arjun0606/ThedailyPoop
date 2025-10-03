import Foundation
import CoreLocation
import SwiftUI

@MainActor
class DemoModeManager: ObservableObject {
    static let shared = DemoModeManager()
    
    @Published var isDemoMode = false
    @Published var demoUser: User?
    @Published var demoDrops: [Drop] = []
    @Published var demoFriends: [User] = []
    
    // San Francisco coordinates (fixed for demo)
    let demoLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    
    private init() {}
    
    func enterDemoMode() {
        isDemoMode = true
        createDemoUser()
        createDemoFriends()
        createDemoDrops()
    }
    
    func exitDemoMode() {
        isDemoMode = false
        demoUser = nil
        demoDrops = []
        demoFriends = []
    }
    
    private func createDemoUser() {
        demoUser = User(
            id: "demo_user_main",
            username: "demo_reviewer",
            dateOfBirth: nil,
            gender: nil,
            appleUserID: "demo_apple_id",
            customGender: nil,
            avatarURL: nil,
            streak: 7
        )
        demoUser?.totalDrops = 15
        demoUser?.maxDropsInDay = 3
        demoUser?.countriesVisited = ["United States"]
        demoUser?.continentsVisited = ["North America"]
    }
    
    private func createDemoFriends() {
        let friend1 = User(
            id: "demo_friend_1",
            username: "friend_1",
            dateOfBirth: nil,
            gender: nil,
            appleUserID: "demo_friend_1_apple",
            streak: 5
        )
        var f1 = friend1
        f1.totalDrops = 8
        
        let friend2 = User(
            id: "demo_friend_2",
            username: "friend_2",
            dateOfBirth: nil,
            gender: nil,
            appleUserID: "demo_friend_2_apple",
            streak: 10
        )
        var f2 = friend2
        f2.totalDrops = 12
        
        let friend3 = User(
            id: "demo_friend_3",
            username: "friend_3",
            dateOfBirth: nil,
            gender: nil,
            appleUserID: "demo_friend_3_apple",
            streak: 3
        )
        var f3 = friend3
        f3.totalDrops = 6
        
        demoFriends = [f1, f2, f3]
    }
    
    private func createDemoDrops() {
        let calendar = Calendar.current
        let now = Date()
        
        // Demo music data
        let musicSamples: [(String, String, String, String?)] = [
            ("Blinding Lights", "The Weeknd", "https://open.spotify.com/track/0VjIjW4GlUZAMYd2vXMi3b", nil),
            ("Shape of You", "Ed Sheeran", "https://open.spotify.com/track/7qiZfU4dY1lWllzX7mPBI", nil),
            ("Bohemian Rhapsody", "Queen", "https://open.spotify.com/track/4u7EnebtmKWzUH433cf5Qv", nil),
            ("Anti-Hero", "Taylor Swift", "https://music.apple.com/us/album/anti-hero/1657389517?i=1657389520", nil),
            ("Heat Waves", "Glass Animals", "https://music.apple.com/us/album/heat-waves/1516582000?i=1516582341", nil)
        ]
        
        let captions = [
            "☕ coffee working its magic",
            "🌮 spicy burrito revenge",
            "🏆 legendary drop",
            "💯 feeling accomplished",
            "😅 not my best work",
            "🔥 chef's kiss",
            "⭐ solid effort",
            "💩 morning routine",
            "😬 regret last night's dinner",
            "✨ smooth operator",
            "🎯 mission accomplished",
            "📈 new personal record",
            "😴 half asleep",
            "🌶️ paid the price",
            "⚡ lightning fast"
        ]
        
        var drops: [Drop] = []
        
        // Create 15 drops (10 from main user, 5 from friends)
        for i in 0..<10 {
            var drop = Drop(
                id: "demo_drop_\(i)",
                userID: "demo_user_main",
                username: "demo_reviewer",
                location: demoLocation,
                city: "San Francisco",
                country: "United States",
                continent: "North America",
                caption: captions[i],
                rating: Int.random(in: 5...10),
                musicTitle: i < 5 ? musicSamples[i].0 : nil,
                musicArtist: i < 5 ? musicSamples[i].1 : nil,
                musicURL: i < 5 ? musicSamples[i].2 : nil,
                musicCoverArt: nil
            )
            // Adjust timestamp to simulate older drops
            let daysAgo = i / 2
            if daysAgo > 0, let oldDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) {
                // Create a new drop with adjusted timestamp
                drop = Drop(
                    id: drop.id,
                    userID: drop.userID,
                    username: drop.username,
                    location: drop.location,
                    city: drop.city,
                    country: drop.country,
                    continent: drop.continent,
                    caption: drop.caption,
                    rating: drop.rating,
                    musicTitle: drop.musicTitle,
                    musicArtist: drop.musicArtist,
                    musicURL: drop.musicURL,
                    musicCoverArt: drop.musicCoverArt
                )
            }
            drops.append(drop)
        }
        
        // Add 5 drops from friends
        for i in 0..<5 {
            let friendIndex = i % 3
            let friend = demoFriends[friendIndex]
            
            let drop = Drop(
                id: "demo_drop_friend_\(i)",
                userID: friend.id,
                username: friend.username,
                location: demoLocation,
                city: "San Francisco",
                country: "United States",
                continent: "North America",
                caption: captions[i + 10],
                rating: Int.random(in: 4...9)
            )
            drops.append(drop)
        }
        
        demoDrops = drops.sorted { $0.timestamp > $1.timestamp }
    }
    
    func addDemoDrop(caption: String, rating: Int, musicTitle: String? = nil, musicArtist: String? = nil, musicURL: String? = nil) {
        guard let user = demoUser else { return }
        
        let drop = Drop(
            id: "demo_drop_new_\(UUID().uuidString)",
            userID: user.id,
            username: user.username,
            location: demoLocation,
            city: "San Francisco",
            country: "United States",
            continent: "North America",
            caption: caption,
            rating: rating,
            musicTitle: musicTitle,
            musicArtist: musicArtist,
            musicURL: musicURL,
            musicCoverArt: nil
        )
        
        demoDrops.insert(drop, at: 0)
        demoUser?.totalDrops += 1
    }
}

