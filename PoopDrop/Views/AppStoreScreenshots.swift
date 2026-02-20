import SwiftUI

// MARK: - App Store Marketing Screenshots
// Open Xcode Preview canvas → capture each at 1290x2796 (6.7") for App Store

private let brandGold = Color(red: 1.0, green: 0.76, blue: 0.28)
private let brandDark = Color(red: 0.06, green: 0.06, blue: 0.08)

// MARK: - Screenshot 1: Hero — Daily Briefing Feed

struct Screenshot_Feed: View {
    var body: some View {
        ScreenshotFrame(
            headline: "News that\nhits different.",
            subtitle: "20 stories. Fresh every morning at 7 AM.",
            gradient: [brandDark, Color(red: 0.15, green: 0.1, blue: 0.02)]
        ) {
            // Simulated feed
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TheDailyPoop")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.white)
                        Text("Thursday, Feb 19")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    Spacer()
                    Circle()
                        .stroke(brandGold, lineWidth: 2)
                        .frame(width: 22, height: 22)
                        .overlay(Text("8").font(.system(size: 8, weight: .bold)).foregroundStyle(.white))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black)

                // Briefing header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                        Text("TODAY'S BRIEFING")
                            .font(.system(size: 7, weight: .heavy))
                            .tracking(1)
                    }
                    .foregroundStyle(brandGold)

                    Text("Markets are Sweating, AI Just Got a Promotion, and Congress Can't Agree on Lunch")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .lineSpacing(2)
                }
                .padding(14)

                // Game cards
                VStack(spacing: 6) {
                    MockGameCard(emoji: "", title: "POOP OR SCOOP", subtitle: "Real or fake headline?", accent: .pink, buttonText: "PLAY", useAppLogo: true)
                    MockGameCard(emoji: "Aa", title: "WORD DROP", subtitle: "Unscramble today's headline", accent: brandGold, buttonText: "PLAY")
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)

                // Story cards
                VStack(spacing: 6) {
                    MockStoryCard(
                        category: "BUSINESS",
                        emoji: "\u{1F4B0}",
                        headline: "Markets Got Jump-Scared by a Hawkish Fed Pick",
                        readTime: "8 min",
                        catColor: Color(red: 1.0, green: 0.76, blue: 0.28)
                    )
                    MockStoryCard(
                        category: "TECH",
                        emoji: "\u{1F916}",
                        headline: "AI Agents Just Stopped Being Tools",
                        readTime: "5 min",
                        catColor: Color(red: 0.35, green: 0.78, blue: 1.0)
                    )
                }
                .padding(.horizontal, 14)

                Spacer()
            }
            .background(Color.black)
        }
    }
}

// MARK: - Screenshot 2: Word Drop Game

struct Screenshot_WordDrop: View {
    var body: some View {
        ScreenshotFrame(
            headline: "90 seconds.\nHow many words?",
            subtitle: "Daily word game from today's top headline.",
            gradient: [brandDark, Color(red: 0.08, green: 0.12, blue: 0.02)]
        ) {
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white.opacity(0.5))
                        )
                    Spacer()
                    // Timer
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.06), lineWidth: 3)
                        Circle().trim(from: 0, to: 0.7).stroke(brandGold, style: StrokeStyle(lineWidth: 3, lineCap: .round)).rotationEffect(.degrees(-90))
                        Text("63").font(.system(size: 14, weight: .black).monospacedDigit()).foregroundStyle(.white)
                    }
                    .frame(width: 38, height: 38)
                    Spacer()
                    VStack(spacing: 1) {
                        Text("7").font(.system(size: 13, weight: .black)).foregroundStyle(.white)
                        Text("words").font(.system(size: 7, weight: .medium)).foregroundStyle(.white.opacity(0.35))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                Spacer(minLength: 8)

                // Key word hint
                HStack(spacing: 3) {
                    Image(systemName: "star.fill").font(.system(size: 7)).foregroundStyle(brandGold)
                    Text("Find the 6-letter key word for +50 bonus!")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(brandGold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(brandGold.opacity(0.1))
                .clipShape(Capsule())
                .padding(.bottom, 10)

                // Current word
                HStack(spacing: 3) {
                    ForEach(["T","R","A","D","E"], id: \.self) { letter in
                        Text(letter)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 30)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.bottom, 14)

                // Letter grid
                let letters = ["T","R","A","D","E","S","M","K","I"]
                let selected = [0,1,2,3,4]
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(0..<9, id: \.self) { i in
                        Text(letters[i])
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(selected.contains(i) ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(selected.contains(i) ? brandGold : Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 12)

                // Found words
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(["MARKETS","TRADE","MASK","RATE","DESK","ATE","SET"], id: \.self) { word in
                            Text(word)
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.04))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .padding(.bottom, 10)
            }
            .background(Color.black)
        }
    }
}

// MARK: - Screenshot 3: Poop or Scoop

struct Screenshot_PoopOrScoop: View {
    var body: some View {
        ScreenshotFrame(
            headline: "Real headline\nor total BS?",
            subtitle: "Swipe through 10 headlines. Trust nobody.",
            gradient: [brandDark, Color(red: 0.15, green: 0.03, blue: 0.06)]
        ) {
            VStack(spacing: 0) {
                Spacer(minLength: 12)

                // Score indicator
                HStack(spacing: 3) {
                    ForEach(0..<10, id: \.self) { i in
                        Capsule()
                            .fill(i < 5 ? .green : (i == 5 ? .white : Color.white.opacity(0.15)))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Card
                VStack(spacing: 20) {
                    Text("6 / 10")
                        .font(.system(size: 10, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.5))

                    Text("NASA Discovers New Planet Made Entirely of Cheese, Names It 'Gouda Prime'")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 16)

                    Text("Is this headline real or did we make it up?")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
                .padding(.horizontal, 14)

                Spacer(minLength: 20)

                // Swipe buttons
                HStack(spacing: 40) {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: "xmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Color.red)
                        }
                        Text("FAKE")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(Color.red)
                            .tracking(1)
                    }

                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.12))
                                .frame(width: 56, height: 56)
                            Text("\u{2705}")
                                .font(.system(size: 24))
                        }
                        Text("REAL")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(Color.green)
                            .tracking(1)
                    }
                }
                .padding(.bottom, 20)

                Spacer(minLength: 12)
            }
            .background(Color.black)
        }
    }
}

// MARK: - Screenshot 4: Story Deep Dive

struct Screenshot_Story: View {
    var body: some View {
        ScreenshotFrame(
            headline: "Deep dives that\ndon't put you to sleep.",
            subtitle: "Business bro energy meets real journalism.",
            gradient: [brandDark, Color(red: 0.02, green: 0.08, blue: 0.15)]
        ) {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image placeholder
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.15, blue: 0.1), Color(red: 0.1, green: 0.08, blue: 0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 140)

                    LinearGradient(
                        stops: [.init(color: .clear, location: 0.3), .init(color: .black, location: 1.0)],
                        startPoint: .top, endPoint: .bottom
                    )
                }
                .frame(height: 140)

                VStack(alignment: .leading, spacing: 12) {
                    // Category
                    HStack(spacing: 4) {
                        Text("\u{1F4B0}")
                            .font(.system(size: 8))
                        Text("BUSINESS")
                            .font(.system(size: 7, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(Color(red: 1.0, green: 0.76, blue: 0.28))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color(red: 1.0, green: 0.76, blue: 0.28).opacity(0.12))
                    .clipShape(Capsule())

                    Text("Markets Got Jump-Scared by a Hawkish Fed Pick (Yeah, That Matters)")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                        .lineSpacing(2)

                    Text("S&P just cleared 7,000 and markets were acting like inflation was a Netflix show that got canceled after Season 1.\n\nThen the White House nominates Kevin Warsh to run the Fed and everything goes full horror-movie violin screech.")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineSpacing(4)

                    // TLDR
                    VStack(alignment: .leading, spacing: 5) {
                        Text("TLDR")
                            .font(.system(size: 7, weight: .heavy))
                            .foregroundStyle(Color(red: 1.0, green: 0.76, blue: 0.28))
                            .tracking(1.5)
                        Text("The Fed pick matters more than the S&P number. Hawkish chair = rates stay high = your mortgage stays expensive.")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.75))
                            .italic()
                            .lineSpacing(3)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 1.0, green: 0.76, blue: 0.28).opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    // Reactions
                    HStack(spacing: 16) {
                        ForEach([("\u{1F525}", "24"), ("\u{1F480}", "18"), ("\u{1F602}", "7"), ("\u{1F92F}", "31")], id: \.0) { emoji, count in
                            VStack(spacing: 3) {
                                Text(emoji).font(.system(size: 16))
                                Text(count).font(.system(size: 8, weight: .bold).monospacedDigit()).foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .padding(14)

                Spacer()
            }
            .background(Color.black)
        }
    }
}

// MARK: - Screenshot 5: Leaderboard & Social

struct Screenshot_Social: View {
    var body: some View {
        ScreenshotFrame(
            headline: "Compete.\nShare. Flex.",
            subtitle: "Daily leaderboard. Premium bragging rights.",
            gradient: [brandDark, Color(red: 0.1, green: 0.04, blue: 0.15)]
        ) {
            VStack(spacing: 0) {
                // Leaderboard header
                HStack {
                    Text("Leaderboard")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("Today")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

                // Leaderboard rows
                VStack(spacing: 0) {
                    LeaderboardMockRow(rank: 1, name: "@tradebro99", score: 142, words: 18, medal: "\u{1F947}", found: true)
                    LeaderboardMockRow(rank: 2, name: "@newsqueen", score: 98, words: 14, medal: "\u{1F948}", found: true)
                    LeaderboardMockRow(rank: 3, name: "@wallstchad", score: 87, words: 12, medal: "\u{1F949}", found: false)
                    LeaderboardMockRow(rank: 4, name: "@cryptokid", score: 61, words: 9, medal: "", found: false)
                    LeaderboardMockRow(rank: 5, name: "@techgirlsf", score: 54, words: 8, medal: "", found: true)
                }

                Spacer(minLength: 12)

                // Share card mock
                VStack(spacing: 10) {
                    Text("SHARE YOUR SCORE")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.35))
                        .tracking(2)

                    // Mini share card
                    VStack(spacing: 8) {
                        HStack {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                            Text("TheDailyPoop")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("Feb 19")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                        }

                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("142")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundStyle(brandGold)
                                Text("18 words \u{00B7} Key word found \u{2B50}")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            Spacer()
                            Text("#1")
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(brandGold)
                        }

                        // Word grid
                        HStack(spacing: 3) {
                            ForEach(0..<12, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(i < 8 ? brandGold : Color.white.opacity(0.08))
                                    .frame(width: 14, height: 14)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(brandGold.opacity(0.2), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 14)

                Spacer(minLength: 12)
            }
            .background(Color.black)
        }
    }
}

// MARK: - Shared Frame

private struct ScreenshotFrame<Content: View>: View {
    let headline: String
    let subtitle: String
    let gradient: [Color]
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: gradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                // Marketing text
                VStack(spacing: 10) {
                    Text(headline)
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer(minLength: 28)

                // Device mockup
                content
                    .frame(maxWidth: .infinity)
                    .frame(height: 520)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
                    .padding(.horizontal, 24)

                Spacer(minLength: 24)
            }
        }
        .frame(width: 430, height: 932) // iPhone 15 Pro Max logical size
    }
}

// MARK: - Mock Components

private struct MockGameCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let accent: Color
    let buttonText: String
    var useAppLogo: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accent.opacity(0.15))
                    .frame(width: 36, height: 36)
                if useAppLogo {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                } else {
                    Text(emoji)
                        .font(.system(size: emoji.count > 2 ? 14 : 16, weight: .black, design: .rounded))
                        .foregroundStyle(accent)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 7, weight: .heavy))
                    .foregroundStyle(accent)
                    .tracking(1)
                Text(subtitle)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white)
            }

            Spacer()

            Text(buttonText)
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(accent)
                .clipShape(Capsule())
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.15), lineWidth: 0.5)
        )
    }
}

private struct MockStoryCard: View {
    let category: String
    let emoji: String
    let headline: String
    let readTime: String
    let catColor: Color

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text(emoji).font(.system(size: 7))
                    Text(category).font(.system(size: 6, weight: .bold)).tracking(0.5)
                }
                .foregroundStyle(catColor)

                Text(headline)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(readTime)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
            }
            Spacer()
            RoundedRectangle(cornerRadius: 8)
                .fill(catColor.opacity(0.1))
                .frame(width: 56, height: 56)
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }
}

private struct LeaderboardMockRow: View {
    let rank: Int
    let name: String
    let score: Int
    let words: Int
    let medal: String
    let found: Bool

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return .white.opacity(0.35)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(medal.isEmpty ? "\(rank)" : medal)
                .font(.system(size: medal.isEmpty ? 10 : 14))
                .frame(width: 20)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 24, height: 24)
                .overlay(
                    Text(String(name.dropFirst().prefix(1)).uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                )

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 3) {
                    Text(name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(brandGold)
                }
                HStack(spacing: 3) {
                    Text("\(words) words")
                        .font(.system(size: 7))
                        .foregroundStyle(.white.opacity(0.35))
                    if found {
                        Text("\u{2B50}")
                            .font(.system(size: 7))
                    }
                }
            }

            Spacer()

            Text("\(score)")
                .font(.system(size: 13, weight: .black).monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(rank <= 3 ? rankColor.opacity(0.05) : Color.clear)
    }
}

// MARK: - Previews

#Preview("1 — Feed") {
    Screenshot_Feed()
        .preferredColorScheme(.dark)
}

#Preview("2 — Word Drop") {
    Screenshot_WordDrop()
        .preferredColorScheme(.dark)
}

#Preview("3 — Poop or Scoop") {
    Screenshot_PoopOrScoop()
        .preferredColorScheme(.dark)
}

#Preview("4 — Story") {
    Screenshot_Story()
        .preferredColorScheme(.dark)
}

#Preview("5 — Social") {
    Screenshot_Social()
        .preferredColorScheme(.dark)
}
