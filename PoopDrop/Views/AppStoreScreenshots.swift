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
            subtitle: "25 stories. 6 games. Fresh at 7 AM.",
            gradient: [brandDark, Color(red: 0.15, green: 0.1, blue: 0.02)]
        ) {
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TheDailyPoop")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.white)
                        Text("Friday, Feb 21")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    Spacer()
                    Circle()
                        .stroke(brandGold, lineWidth: 2)
                        .frame(width: 22, height: 22)
                        .overlay(Text("12").font(.system(size: 7, weight: .bold).monospacedDigit()).foregroundStyle(.white))
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

                    HStack {
                        Text("12/25 read")
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                        Spacer()
                        Text("Friday, Feb 21")
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }

                    Text("Everyone's Getting Sued and the Market Loves It")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .lineSpacing(2)

                    Text("Congress chose violence again, a crypto bro discovered what jail looks like, and Boeing somehow made it worse. It's a lot.")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineSpacing(3)
                }
                .padding(14)

                // Vibe pill
                HStack(spacing: 5) {
                    Text("\u{1F525}")
                        .font(.system(size: 8))
                    Text("TODAY'S VIBE: DUMPSTER FIRE")
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundStyle(.orange)
                        .tracking(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
                .padding(.bottom, 8)

                // Story cards
                VStack(spacing: 6) {
                    MockStoryCard(
                        category: "POLITICS",
                        emoji: "\u{1F3DB}\u{FE0F}",
                        headline: "Congress Chose Violence and the Budget Chose Death",
                        readTime: "2 min",
                        catColor: .red,
                        isRead: true
                    )
                    MockStoryCard(
                        category: "TECH",
                        emoji: "\u{1F916}",
                        headline: "AI Agents Just Stopped Being Tools and Started Having Opinions",
                        readTime: "1 min",
                        catColor: Color(red: 0.35, green: 0.78, blue: 1.0),
                        isRead: true
                    )
                    MockStoryCard(
                        category: "BUSINESS",
                        emoji: "\u{1F4B0}",
                        headline: "Wall Street Discovered Feelings and the Fed Is Not Amused",
                        readTime: "2 min",
                        catColor: brandGold,
                        isRead: false
                    )
                }
                .padding(.horizontal, 14)

                Spacer()
            }
            .background(Color.black)
        }
    }
}

// MARK: - Screenshot 2: Poop or Scoop Game

struct Screenshot_PoopOrScoop: View {
    var body: some View {
        ScreenshotFrame(
            headline: "Real headline\nor total BS?",
            subtitle: "Swipe right for real. Left for fake. Trust nobody.",
            gradient: [brandDark, Color(red: 0.15, green: 0.03, blue: 0.06)]
        ) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("POOP OR SCOOP")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.pink)
                            .tracking(1.5)
                        Text("Real or fake headline?")
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Text("6/10")
                        .font(.system(size: 10, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Spacer(minLength: 8)

                // Progress dots
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
                            Text("\u{1F4A9}")
                                .font(.system(size: 24))
                        }
                        Text("POOP")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(Color.red)
                            .tracking(1)
                    }

                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.12))
                                .frame(width: 56, height: 56)
                            Text("\u{1F4F0}")
                                .font(.system(size: 24))
                        }
                        Text("SCOOP")
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

// MARK: - Screenshot 3: Who Said It Game

struct Screenshot_WhoSaidIt: View {
    var body: some View {
        ScreenshotFrame(
            headline: "CEO, dictator,\nor cult leader?",
            subtitle: "6 daily games based on today's insane news.",
            gradient: [brandDark, Color(red: 0.08, green: 0.02, blue: 0.15)]
        ) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WHO SAID IT?")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.purple)
                            .tracking(1.5)
                        Text("Match the quote to the person")
                            .font(.system(size: 7, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Text("3/5")
                        .font(.system(size: 10, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 3)
                        Rectangle()
                            .fill(Color.purple)
                            .frame(width: geo.size.width * 0.6, height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 14)

                Spacer(minLength: 16)

                // Quote card
                VStack(spacing: 16) {
                    Text("\u{1F3A4}")
                        .font(.system(size: 32))

                    Text("\"Move fast and break things. Boundaries exist to be crossed.\"")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 12)

                    Text("Who said this?")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 14)

                Spacer(minLength: 16)

                // Options
                VStack(spacing: 8) {
                    ForEach(Array(["Elon Musk — CEO", "Jim Jones — Cult Leader", "Mark Zuckerberg — CEO", "Kim Jong-un — Dictator"].enumerated()), id: \.offset) { idx, option in
                        HStack(spacing: 10) {
                            Text(["A", "B", "C", "D"][idx])
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.purple)
                                .frame(width: 22, height: 22)
                                .background(Color.purple.opacity(0.15))
                                .clipShape(Circle())

                            Text(option)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white)

                            Spacer()
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                        )
                    }
                }
                .padding(.horizontal, 14)

                Spacer(minLength: 12)
            }
            .background(Color.black)
        }
    }
}

// MARK: - Screenshot 4: Story Reading Experience

struct Screenshot_Story: View {
    var body: some View {
        ScreenshotFrame(
            headline: "Written like your\ngroup chat.",
            subtitle: "Sourced like the NYT. Zero filler.",
            gradient: [brandDark, Color(red: 0.02, green: 0.08, blue: 0.15)]
        ) {
            VStack(alignment: .leading, spacing: 0) {
                // Category + meta
                HStack {
                    HStack(spacing: 4) {
                        Text("\u{1F4B0}")
                            .font(.system(size: 8))
                        Text("BUSINESS")
                            .font(.system(size: 7, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(brandGold)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(brandGold.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()

                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 6))
                        Text("1 min read")
                            .font(.system(size: 7, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.35))
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                // Headline
                Text("Wall Street Discovered Feelings and the Fed Is Not Amused")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                // Source
                HStack(spacing: 3) {
                    Image(systemName: "link")
                        .font(.system(size: 6))
                    Text("Bloomberg")
                        .font(.system(size: 7, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.3))
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .padding(.bottom, 12)

                // Body text
                VStack(alignment: .leading, spacing: 12) {
                    Text("S&P just cleared 7,000 and markets were acting like inflation was a Netflix show that got canceled after Season 1. Then the White House nominates Kevin Warsh to run the Fed and everything goes full horror-movie violin screech.")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineSpacing(4)

                    // Translation callout
                    HStack(alignment: .top, spacing: 8) {
                        Rectangle()
                            .fill(brandGold)
                            .frame(width: 2)
                            .clipShape(Capsule())

                        VStack(alignment: .leading, spacing: 3) {
                            Text("TRANSLATION")
                                .font(.system(size: 6, weight: .black))
                                .foregroundStyle(brandGold)
                                .tracking(1.5)
                            Text("\"The market is healthy\" means \"we're praying it doesn't crash before earnings.\"")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineSpacing(3)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(brandGold.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    // The Number callout
                    VStack(alignment: .leading, spacing: 3) {
                        Text("THE NUMBER")
                            .font(.system(size: 6, weight: .black))
                            .foregroundStyle(Color(red: 0.2, green: 0.78, blue: 0.35))
                            .tracking(1.5)
                        Text("$4.2 trillion — that's how much vanished from global markets in a single afternoon.")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .lineSpacing(3)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.78, blue: 0.35).opacity(0.08), Color(red: 0.2, green: 0.78, blue: 0.35).opacity(0.02)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(alignment: .leading) {
                        Color(red: 0.2, green: 0.78, blue: 0.35)
                            .frame(width: 2)
                            .clipShape(Capsule())
                    }

                    // Bottom Line
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(Color(red: 0.2, green: 0.78, blue: 0.35))
                                .frame(width: 2, height: 10)
                                .clipShape(Capsule())
                            Text("THE BOTTOM LINE")
                                .font(.system(size: 6, weight: .black))
                                .foregroundStyle(Color(red: 0.2, green: 0.78, blue: 0.35))
                                .tracking(1.5)
                        }
                        Text("The Fed pick matters more than the S&P number. Hawkish chair = rates stay high = your mortgage stays expensive.")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineSpacing(3)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.2, green: 0.78, blue: 0.35).opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(red: 0.2, green: 0.78, blue: 0.35).opacity(0.2), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 14)

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
                .padding(.vertical, 10)

                Spacer()
            }
            .background(Color.black)
        }
    }
}

// MARK: - Screenshot 5: Game Results & Share

struct Screenshot_GameResults: View {
    var body: some View {
        ScreenshotFrame(
            headline: "Flex your\nnews IQ.",
            subtitle: "Share scores. Challenge friends. Talk trash.",
            gradient: [brandDark, Color(red: 0.1, green: 0.04, blue: 0.15)]
        ) {
            VStack(spacing: 0) {
                Spacer(minLength: 16)

                // Score
                VStack(spacing: 8) {
                    Text("8/10")
                        .font(.system(size: 40, weight: .black).monospacedDigit())
                        .foregroundStyle(.white)

                    Text("Insanity Expert!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                }

                Spacer(minLength: 16)

                // Emoji pattern
                Text("\u{2705}\u{2705}\u{274C}\u{2705}\u{2705}\u{2705}\u{274C}\u{2705}\u{2705}\u{2705}")
                    .font(.system(size: 16))
                    .padding(.bottom, 12)

                // Share button
                HStack(spacing: 5) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 10, weight: .bold))
                    Text("Share Score")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(Color.pink)
                .clipShape(Capsule())
                .padding(.bottom, 20)

                // Share card preview
                VStack(alignment: .leading, spacing: 10) {
                    Text("WHAT YOUR FRIENDS SEE")
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.3))
                        .tracking(2)

                    VStack(alignment: .leading, spacing: 8) {
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
                        }

                        Text("\u{1F4A9} Poop or Scoop 8/10\n\u{2705}\u{2705}\u{274C}\u{2705}\u{2705}\u{2705}\u{274C}\u{2705}\u{2705}\u{2705}\n\nCan you spot the fake headline?\nTheDailyPoop \u{2014} news that hits different\nthedailypoop.app")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineSpacing(3)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.pink.opacity(0.2), lineWidth: 0.5)
                    )

                    // Other game scores
                    Text("TODAY'S GAMES")
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.3))
                        .tracking(2)
                        .padding(.top, 4)

                    HStack(spacing: 6) {
                        MiniGameScore(emoji: "\u{1F4A9}", name: "Poop or Scoop", score: "8/10", color: .pink)
                        MiniGameScore(emoji: "\u{1F3A4}", name: "Who Said It", score: "4/5", color: .purple)
                        MiniGameScore(emoji: "\u{1F92F}", name: "Headline Roulette", score: "18/25", color: .cyan)
                    }
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
            LinearGradient(
                colors: gradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                VStack(spacing: 10) {
                    Text(headline)
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(brandGold.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Spacer(minLength: 28)

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

private struct MockStoryCard: View {
    let category: String
    let emoji: String
    let headline: String
    let readTime: String
    let catColor: Color
    var isRead: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            catColor
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text(emoji).font(.system(size: 7))
                    Text(category).font(.system(size: 6, weight: .bold)).tracking(0.5)
                    Spacer()
                    if isRead {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 5, weight: .bold))
                            Text("Read")
                                .font(.system(size: 6, weight: .medium))
                        }
                        .foregroundStyle(.green.opacity(0.7))
                    }
                }
                .foregroundStyle(catColor)

                Text(headline)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 5))
                        Text(readTime)
                            .font(.system(size: 7, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.35))

                    Spacer()

                    HStack(spacing: 2) {
                        Text("\u{1F525}")
                            .font(.system(size: 6))
                        Text("\(Int.random(in: 8...42))")
                            .font(.system(size: 7, weight: .bold).monospacedDigit())
                            .foregroundStyle(.orange.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(isRead ? Color.white.opacity(0.02) : Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }
}

private struct MiniGameScore: View {
    let emoji: String
    let name: String
    let score: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 16))
            Text(score)
                .font(.system(size: 11, weight: .black).monospacedDigit())
                .foregroundStyle(.white)
            Text(name)
                .font(.system(size: 6, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(color.opacity(0.15), lineWidth: 0.5)
        )
    }
}

// MARK: - Previews

#Preview("1 — Feed") {
    Screenshot_Feed()
        .preferredColorScheme(.dark)
}

#Preview("2 — Poop or Scoop") {
    Screenshot_PoopOrScoop()
        .preferredColorScheme(.dark)
}

#Preview("3 — Who Said It") {
    Screenshot_WhoSaidIt()
        .preferredColorScheme(.dark)
}

#Preview("4 — Story") {
    Screenshot_Story()
        .preferredColorScheme(.dark)
}

#Preview("5 — Game Results") {
    Screenshot_GameResults()
        .preferredColorScheme(.dark)
}
