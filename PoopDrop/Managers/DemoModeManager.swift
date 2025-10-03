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
        // Only 3 demo drops with specific songs
        let musicSamples: [(String, String, String, String?)] = [
            ("Despacito (feat. Justin Bieber) [Remix]", "Luis Fonsi", "https://music.apple.com/in/album/despacito-feat-justin-bieber-remix/1447401519?i=1447401626", nil),
            ("Wait", "Maroon 5", "https://music.apple.com/in/album/wait/1396381720?i=1396381964", nil),
            ("Slide Away (Remastered)", "Oasis", "https://music.apple.com/in/album/slide-away-remastered/828329184?i=828329204", nil)
        ]
        
        let captions = [
            "🎵 vibing to this banger while dropping 💩",
            "☕ morning coffee routine hits different",
            "🏆 legendary drop with a legendary song"
        ]
        
        // Scattered locations around San Francisco
        let locations = [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Downtown SF
            CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094), // North Beach area
            CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294)  // Mission area
        ]
        
        var drops: [Drop] = []
        
        // Create only 3 drops - one from each friend
        for i in 0..<3 {
            let friend = demoFriends[i]
            
            let drop = Drop(
                id: "demo_drop_\(i)",
                userID: friend.id,
                username: friend.username,
                location: locations[i],
                city: "San Francisco",
                country: "United States",
                continent: "North America",
                caption: captions[i],
                rating: [8, 7, 9][i],
                musicTitle: musicSamples[i].0,
                musicArtist: musicSamples[i].1,
                musicURL: musicSamples[i].2,
                musicCoverArt: nil
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

