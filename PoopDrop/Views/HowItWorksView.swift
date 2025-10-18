import SwiftUI

struct HowItWorksView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("💩 Welcome to TheDailyPoop")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("The fun way to track your bathroom habits and connect with friends!")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 8)
                        
                        // How It Works Sections
                        FeatureSection(
                            icon: "📍",
                            title: "1. Drop It Like It's Hot",
                            description: "Every time you poop, tap the big button and log it! Your location is automatically detected (city/state only for privacy). Rate your poop from 1-10 with our sliding poop emoji (it grows as you slide!), add what music you're listening to from Spotify or Apple Music, and include an optional caption."
                        )
                        
                        FeatureSection(
                            icon: "🗺️",
                            title: "2. Watch Your Poop Map Grow",
                            description: "See where you and your friends have pooped around the world! Your drops appear as emoji pins on a beautiful interactive map. Zoom in to see clusters, tap pins to view details and reactions."
                        )
                        
                        FeatureSection(
                            icon: "☕",
                            title: "3. Post Anonymous Gossip",
                            description: "Post anonymous gossip to the Gossip Feed! Share tea, call out friends, or start drama. Anyone can see it, but only YOU know you posted it... unless someone pays $1.99 to reveal your identity!"
                        )
                        
                        FeatureSection(
                            icon: "👥",
                            title: "4. Connect with Friends",
                            description: "Add friends to see their poops in your feed and on the map! React to their drops with emojis, see what music they're listening to while pooping, view their poop ratings, and compete on the leaderboard. Get notified when friends drop, post gossip, or accept your friend requests."
                        )
                        
                        FeatureSection(
                            icon: "🔍",
                            title: "5. React & Reply",
                            description: "React to any gossip post with emojis, and join the conversation by replying anonymously! Full threaded conversations keep the drama going. Every reply is anonymous too, so speak your mind!"
                        )
                        
                        FeatureSection(
                            icon: "🎖️",
                            title: "6. Track Your Journey",
                            description: "Earn badges for hitting milestones: 100 drops, visiting new countries, and more! Track your stats: total drops, max drops per day, countries visited, and continents explored."
                        )
                        
                        FeatureSection(
                            icon: "🎵",
                            title: "7. Music & Ratings",
                            description: "Rate each poop from 1-10 (watch the poop emoji grow!). Share what song you're jamming to by pasting a Spotify or Apple Music link. Friends can tap the music card to listen to the same song. Turn your bathroom breaks into a musical experience!"
                        )
                        
                        FeatureSection(
                            icon: "📱",
                            title: "8. Share Your Journey",
                            description: "Export your stats as a beautiful shareable image for Instagram, Twitter, or Stories. Show off your poop passport or your global heatmap!"
                        )
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.vertical, 8)
                        
                        // Privacy & Fun
                        VStack(alignment: .leading, spacing: 16) {
                            Text("🔒 Privacy First")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("We only show city/state, never your exact coordinates. Your drops expire after 3 days in the feed. You control who sees what!")
                                .font(.body)
                                .foregroundColor(.gray)
                            
                            Text("🎉 Why TheDailyPoop?")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            
                            Text("Because everyone poops! Track your regularity, compete with friends, and turn a daily routine into a hilarious social experience. It's Snapchat meets bathroom humor.")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct FeatureSection: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 32))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    HowItWorksView()
}
