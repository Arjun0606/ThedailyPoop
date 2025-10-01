import Foundation
import SwiftUI

// MARK: - Spotify API Client
class SpotifyAPIClient: ObservableObject {
    static let shared = SpotifyAPIClient()
    
    // MARK: - Spotify Developer credentials
    private let clientID = "3c060a8e9c39489f9928ee998a26b2de"
    private let clientSecret = "YOUR_CLIENT_SECRET" // ⚠️ Click "View client secret" in Spotify Dashboard and paste it here
    private let redirectURI = "thedailypoop://spotify-callback"
    
    // Authentication state
    @Published var accessToken: String?
    @Published var tokenExpirationDate: Date?
    @Published var isAuthenticated: Bool = false
    
    // Track cache
    private var trackCache: [String: SpotifyTrack] = [:]
    
    private init() {
        // Load token from UserDefaults if available
        if let token = UserDefaults.standard.string(forKey: "spotify_access_token"),
           let expirationDate = UserDefaults.standard.object(forKey: "spotify_token_expiration") as? Date,
           expirationDate > Date() {
            self.accessToken = token
            self.tokenExpirationDate = expirationDate
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Authentication
    
    /// Get Client Credentials token (limited access, no user auth needed)
    func getClientCredentialsToken() async throws {
        // Check if we already have a valid token
        if let expirationDate = tokenExpirationDate, expirationDate > Date(), accessToken != nil {
            return // Token still valid
        }
        
        // Prepare request for client credentials flow
        guard let url = URL(string: "https://accounts.spotify.com/api/token") else {
            throw SpotifyError.invalidURL
        }
        
        // Create the authorization header
        let authString = "\(clientID):\(clientSecret)"
        guard let authData = authString.data(using: .ascii) else {
            throw SpotifyError.authenticationFailed
        }
        
        let base64Auth = authData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SpotifyError.invalidResponse
        }
        
        // Parse the token response
        let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
        
        // Save the token
        self.accessToken = tokenResponse.access_token
        self.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
        self.isAuthenticated = true
        
        // Save to UserDefaults
        UserDefaults.standard.set(tokenResponse.access_token, forKey: "spotify_access_token")
        UserDefaults.standard.set(self.tokenExpirationDate, forKey: "spotify_token_expiration")
    }
    
    // MARK: - API Methods
    
    /// Search for tracks
    func searchTracks(query: String, limit: Int = 1) async throws -> [SpotifyTrack] {
        try await ensureValidToken()
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://api.spotify.com/v1/search?q=\(encodedQuery)&type=track&limit=\(limit)") else {
            throw SpotifyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SpotifyError.invalidResponse
        }
        
        let searchResponse = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
        
        // Cache tracks
        for track in searchResponse.tracks.items {
            trackCache[track.id] = track
        }
        
        return searchResponse.tracks.items
    }
    
    /// Get track by ID
    func getTrack(id: String) async throws -> SpotifyTrack {
        // Check cache first
        if let cachedTrack = trackCache[id] {
            return cachedTrack
        }
        
        try await ensureValidToken()
        
        guard let url = URL(string: "https://api.spotify.com/v1/tracks/\(id)") else {
            throw SpotifyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SpotifyError.invalidResponse
        }
        
        let track = try JSONDecoder().decode(SpotifyTrack.self, from: data)
        
        // Cache the track
        trackCache[track.id] = track
        
        return track
    }
    
    /// Extract track ID from Spotify URL
    func extractTrackId(from url: URL) -> String? {
        // Format: https://open.spotify.com/track/trackId?si=parameters
        if url.pathComponents.contains("track"), 
           let trackIndex = url.pathComponents.firstIndex(of: "track"), 
           trackIndex + 1 < url.pathComponents.count {
            return url.pathComponents[trackIndex + 1].split(separator: "?").first.map(String.init)
        }
        return nil
    }
    
    /// Parse a Spotify link and return track info
    func parseSpotifyLink(_ link: String) async throws -> MusicData {
        guard let url = URL(string: link) else {
            throw SpotifyError.invalidURL
        }
        
        // Try to extract track ID
        if let trackId = extractTrackId(from: url) {
            let track = try await getTrack(id: trackId)
            
            // Get largest available image
            let coverURL = track.album.images.sorted(by: { $0.width > $1.width }).first?.url
            
            return MusicData(
                title: track.name,
                artist: track.artists.map { $0.name }.joined(separator: ", "),
                url: track.external_urls.spotify,
                coverArtURL: coverURL
            )
        }
        
        // If we can't extract ID, try searching
        let searchTerm = url.lastPathComponent.replacingOccurrences(of: "-", with: " ")
        if !searchTerm.isEmpty {
            let searchResults = try await searchTracks(query: searchTerm)
            if let track = searchResults.first {
                let coverURL = track.album.images.sorted(by: { $0.width > $1.width }).first?.url
                
                return MusicData(
                    title: track.name,
                    artist: track.artists.map { $0.name }.joined(separator: ", "),
                    url: track.external_urls.spotify,
                    coverArtURL: coverURL
                )
            }
        }
        
        throw SpotifyError.trackNotFound
    }
    
    // MARK: - Helper Methods
    
    private func ensureValidToken() async throws {
        if let expirationDate = tokenExpirationDate, expirationDate > Date(), accessToken != nil {
            return // Token still valid
        }
        
        try await getClientCredentialsToken()
    }
}

// MARK: - Spotify Models

struct SpotifyTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

struct SpotifySearchResponse: Codable {
    let tracks: SpotifyTracks
}

struct SpotifyTracks: Codable {
    let items: [SpotifyTrack]
}

struct SpotifyTrack: Codable {
    let id: String
    let name: String
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
    let external_urls: SpotifyExternalURLs
    let preview_url: String?
}

struct SpotifyArtist: Codable {
    let id: String
    let name: String
}

struct SpotifyAlbum: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int
    let width: Int
}

struct SpotifyExternalURLs: Codable {
    let spotify: String
}

// MARK: - Errors

enum SpotifyError: Error {
    case invalidURL
    case authenticationFailed
    case invalidResponse
    case trackNotFound
}

// MARK: - MusicData Extension
extension MusicData {
    static func fromSpotifyTrack(_ track: SpotifyTrack) -> MusicData {
        let coverURL = track.album.images.sorted(by: { $0.width > $1.width }).first?.url
        
        return MusicData(
            title: track.name,
            artist: track.artists.map { $0.name }.joined(separator: ", "),
            url: track.external_urls.spotify,
            coverArtURL: coverURL
        )
    }
}
