import SwiftUI

// MARK: - Gossip Tease Card
// "Someone said something about you..." — blurred content, download CTA
// This is THE money card. Shared to IG Stories, creates massive curiosity gap.

struct GossipTeaseCard: View {
    let groupName: String
    let groupEmoji: String
    let previewSnippet: String // First ~40 chars of gossip, rest blurred

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "1a0a2e"), Color(hex: "0d0d0d")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                Spacer().frame(height: 120)

                // App branding
                VStack(spacing: 12) {
                    Text("💩")
                        .font(.system(size: 72))
                    Text("TheDailyPoop")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer().frame(height: 80)

                // The tease
                VStack(spacing: 24) {
                    // Group badge
                    HStack(spacing: 8) {
                        Text(groupEmoji)
                        Text(groupName)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)

                    // Anonymous avatar
                    Circle()
                        .fill(Color.purple.opacity(0.6))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                        )

                    Text("Someone posted anonymous gossip")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)

                    // Blurred gossip preview
                    ZStack {
                        Text(previewSnippet)
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(24)

                        // Blur overlay
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)

                        // Lock icon
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.yellow)
                            Text("$1.99 to reveal")
                                .font(.caption.bold())
                                .foregroundStyle(.yellow)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
                }

                Spacer()

                // CTA
                VStack(spacing: 16) {
                    Text("Find out who said it")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Download TheDailyPoop")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Color.yellow)
                        .cornerRadius(30)

                    Text("thedailypoop.app")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 100)
            }
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Drop Share Card
// Shows poop pin on dark map-like background with location teaser

struct DropShareCard: View {
    let username: String
    let locationName: String?
    let caption: String?
    let groupName: String
    let groupEmoji: String

    var body: some View {
        ZStack {
            // Dark map-like background
            LinearGradient(
                colors: [Color(hex: "0a1628"), Color(hex: "0d0d0d")],
                startPoint: .top,
                endPoint: .bottom
            )

            // Fake map grid lines
            VStack(spacing: 60) {
                ForEach(0..<8, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.03))
                        .frame(height: 1)
                }
            }
            HStack(spacing: 60) {
                ForEach(0..<6, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.03))
                        .frame(width: 1)
                }
            }

            VStack(spacing: 0) {
                Spacer().frame(height: 120)

                // App branding
                HStack(spacing: 12) {
                    Text("💩")
                        .font(.system(size: 36))
                    Text("TheDailyPoop")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer().frame(height: 80)

                // Giant poop pin
                VStack(spacing: 0) {
                    Text("💩")
                        .font(.system(size: 120))
                        .shadow(color: .brown.opacity(0.5), radius: 20)

                    // Pin shadow/dot
                    Ellipse()
                        .fill(Color.brown.opacity(0.3))
                        .frame(width: 60, height: 20)
                        .offset(y: -10)
                }

                Spacer().frame(height: 40)

                // Drop info
                VStack(spacing: 16) {
                    Text("@\(username) just dropped")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    if let location = locationName {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.green)
                            Text(location)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .font(.system(size: 18))
                    }

                    if let caption = caption, !caption.isEmpty {
                        Text("\"\(caption)\"")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .italic()
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 60)
                    }

                    // Group badge
                    HStack(spacing: 8) {
                        Text(groupEmoji)
                        Text(groupName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                }

                Spacer()

                // CTA
                VStack(spacing: 16) {
                    Text("Track your friends' drops")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Download TheDailyPoop")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(30)

                    Text("thedailypoop.app")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 100)
            }
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Group Invite Card
// Shareable invite with group emoji, name, member count, and join code

struct GroupInviteCard: View {
    let group: Group
    let inviterUsername: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1a0a2e"), Color(hex: "2d1b4e"), Color(hex: "0d0d0d")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                Spacer().frame(height: 140)

                // App branding
                VStack(spacing: 12) {
                    Text("💩")
                        .font(.system(size: 64))
                    Text("TheDailyPoop")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer().frame(height: 80)

                // Invite content
                VStack(spacing: 32) {
                    Text("@\(inviterUsername) invited you to")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.7))

                    // Group card
                    VStack(spacing: 20) {
                        Text(group.emoji)
                            .font(.system(size: 80))

                        Text(group.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)

                        if let members = group.members, !members.isEmpty {
                            Text("\(members.count) members already inside")
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal, 60)

                    // Join code
                    VStack(spacing: 8) {
                        Text("JOIN CODE")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .tracking(3)

                        Text(group.inviteCode)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundStyle(.yellow)
                            .tracking(8)
                    }
                }

                Spacer()

                // CTA
                VStack(spacing: 16) {
                    Text("Join the group")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Download TheDailyPoop")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Color.yellow)
                        .cornerRadius(30)

                    Text("thedailypoop.app/join/\(group.inviteCode)")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 100)
            }
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Gossip Reveal Share Card
// After revealing: "I just found out who posted anonymous gossip..."

struct GossipRevealShareCard: View {
    let groupName: String
    let groupEmoji: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "2d0a0a"), Color(hex: "0d0d0d")],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                Spacer().frame(height: 160)

                // App branding
                VStack(spacing: 12) {
                    Text("💩")
                        .font(.system(size: 64))
                    Text("TheDailyPoop")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer().frame(height: 100)

                // Content
                VStack(spacing: 32) {
                    // Shocked emoji
                    Text("😱")
                        .font(.system(size: 100))

                    Text("I just found out who\nposted anonymous gossip")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    // Group badge
                    HStack(spacing: 8) {
                        Text(groupEmoji)
                        Text("in \(groupName)")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .font(.system(size: 18))

                    // Redacted name
                    HStack(spacing: 4) {
                        Text("It was")
                            .foregroundStyle(.white.opacity(0.7))
                        Text("████████")
                            .foregroundStyle(.red)
                    }
                    .font(.system(size: 24, weight: .bold))
                }

                Spacer()

                // CTA
                VStack(spacing: 16) {
                    Text("Pay $1.99 to reveal who\nposted about YOU")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Download TheDailyPoop")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(30)

                    Text("thedailypoop.app")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 100)
            }
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Hex Color Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Drop Share Prompt (half-sheet after dropping)
// Nudges user to share their drop to IG Stories — the viral loop trigger

struct DropSharePrompt: View {
    let username: String
    let locationName: String?
    let caption: String?
    let group: Group?
    let onShare: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                // Celebration
                Text("💩")
                    .font(.system(size: 72))
                    .padding(.top, 20)

                Text("Drop Successful!")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                if let loc = locationName {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.green)
                        Text(loc)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .font(.subheadline)
                }

                // Share CTA
                VStack(spacing: 8) {
                    Text("Let your friends know")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Share to Stories & watch them download the app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Share button
                Button(action: onShare) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Share to Stories")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)

                // Skip
                Button(action: onSkip) {
                    Text("Maybe later")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
}

// MARK: - Gossip Share Prompt (half-sheet after reveal)

struct GossipRevealSharePrompt: View {
    let groupName: String
    let groupEmoji: String
    let onShare: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Text("😱")
                    .font(.system(size: 72))
                    .padding(.top, 20)

                Text("You Revealed the Sender!")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    Text("Make your friends jealous")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Share that you found out — they'll be dying to know too")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: onShare) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Share to Stories")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)

                Button(action: onSkip) {
                    Text("Maybe later")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
}

#Preview("Gossip Tease") {
    GossipTeaseCard(
        groupName: "The Homies",
        groupEmoji: "💩",
        previewSnippet: "Someone in this group was spotted at Olive Garden with someone who definitely wasn't their..."
    )
    .scaleEffect(0.35)
}

#Preview("Drop Share") {
    DropShareCard(
        username: "poopmaster",
        locationName: "Starbucks, Brooklyn",
        caption: "Post-coffee emergency",
        groupName: "NYC Squad",
        groupEmoji: "🗽"
    )
    .scaleEffect(0.35)
}

#Preview("Group Invite") {
    GroupInviteCard(
        group: Group(
            id: "1", name: "The Homies", emoji: "🔥",
            inviteCode: "ABC123", createdBy: "1", maxMembers: 20
        ),
        inviterUsername: "jake"
    )
    .scaleEffect(0.35)
}
