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
                            icon: "🔥",
                            title: "3. Build Your Streak",
                            description: "Log at least one poop per day to maintain your streak! The longer your streak, the more bragging rights. Miss a day? Your streak resets. We also track your 'constipated counter' 😵‍💫 if you haven't pooped in 24+ hours."
                        )
                        
                        FeatureSection(
                            icon: "👥",
                            title: "4. Connect with Friends",
                            description: "Add friends to see their poops in your feed and on the map! React to their drops with emojis, see what music they're listening to while pooping, view their poop ratings, check their stats, and compete on the leaderboard. Get notified when friends drop, break streaks, or accept your friend requests."
                        )
                        
                        FeatureSection(
                            icon: "👻",
                            title: "5. Ghost Attacks!",
                            description: "Send anonymous fart attacks to your friends! They'll hear a hilarious fart sound and have ONE guess to figure out who sent it. Guess wrong? You can pay $0.99 to reveal the sender, or leave it a mystery forever! It's the ultimate prank feature with real stakes."
                        )
                        
                        FeatureSection(
                            icon: "📊",
                            title: "6. Daily Polls",
                            description: "Vote in daily polls created by your friends! Questions like 'Who's the funniest?' or 'Who poops the most?' You get to vote for 1 friend. After voting, see the leaderboard showing the top 3 winners. You'll see ONE person who voted for you, but to see everyone, pay $0.99 to unlock all voters. The competitive messages tell you how many votes you need to climb the leaderboard!"
                        )
                        
                        FeatureSection(
                            icon: "🏆",
                            title: "7. Daily Rankings",
                            description: "Earn points for everything you do! Drop a poop (+10), react to friends (+5), send ghost attacks (+15), get attacked (+20), and win polls (+25). Compete on the daily leaderboard that resets at midnight. Buy a 2X Points Boost ($1.99) to double your points for 24 hours and climb to #1 faster!"
                        )
                        
                        FeatureSection(
                            icon: "🎖️",
                            title: "8. Unlock Achievements",
                            description: "Earn badges for hitting milestones: 7-day streaks, 100 drops, visiting new countries, and more! Track your stats: total drops, max drops per day, longest no-poop streak, countries visited, and continents explored."
                        )
                        
                        FeatureSection(
                            icon: "🎵",
                            title: "9. Music & Ratings",
                            description: "Rate each poop from 1-10 (watch the poop emoji grow!). Share what song you're jamming to by pasting a Spotify or Apple Music link. Friends can tap the music card to listen to the same song. Turn your bathroom breaks into a musical experience!"
                        )
                        
                        FeatureSection(
                            icon: "📱",
                            title: "10. Share Your Journey",
                            description: "Export your stats as a beautiful shareable image for Instagram, Twitter, or Stories. Show off your streak, your poop passport, or your global heatmap!"
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
