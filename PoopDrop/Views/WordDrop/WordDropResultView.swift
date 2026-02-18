import SwiftUI

struct WordDropResultView: View {
    let result: WordGameSubmitResponse
    let game: WordGame
    let wordsFound: [String]
    let onDismiss: () -> Void

    @State private var animatedScore: Int = 0
    @State private var showConfetti = false
    @State private var showingLeaderboard = false
    @State private var showingShareCard = false
    @State private var contentAppeared = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    // Score
                    VStack(spacing: 8) {
                        Text("WORD DROP")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Theme.accent)
                            .tracking(3)

                        Text("\(animatedScore)")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())

                        Text("\(result.wordCount) of \(result.totalPossibleWords) words found")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)

                    // Key word result
                    Group {
                        if result.foundKeyWord {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(Theme.accent)
                                Text("Key word found: \(result.keyWord.uppercased())")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.accent)
                                Text("+50")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.accent)
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Theme.accent.opacity(0.3), lineWidth: 0.5)
                            )
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "star")
                                    .foregroundStyle(Theme.textTertiary)
                                Text("Key word was: \(result.keyWord.uppercased())")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)

                    // Story headline reveal
                    VStack(spacing: 8) {
                        Text("FROM TODAY'S TOP STORY")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(2)

                        Text(game.storyHeadline)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 24)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)

                    // Validated words
                    VStack(alignment: .leading, spacing: 10) {
                        Text("YOUR WORDS")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(2)

                        FlowLayout(spacing: 6) {
                            ForEach(result.validatedWords, id: \.self) { word in
                                let isKeyWord = word == result.keyWord
                                Text(word.uppercased())
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(isKeyWord ? .black : .white.opacity(0.8))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(isKeyWord ? Theme.accent : Theme.cardBg)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(
                                            isKeyWord ? Theme.accent : Theme.cardBorder,
                                            lineWidth: 0.5
                                        )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(contentAppeared ? 1 : 0)

                    // Action buttons
                    VStack(spacing: 10) {
                        Button {
                            showingLeaderboard = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trophy.fill")
                                Text("Leaderboard")
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        HStack(spacing: 10) {
                            Button {
                                showingShareCard = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                        .fontWeight(.bold)
                                }
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.elevatedBg)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Theme.cardBorder, lineWidth: 0.5)
                                )
                            }

                            Button(action: onDismiss) {
                                Text("Done")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Theme.elevatedBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Theme.cardBorder, lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(contentAppeared ? 1 : 0)

                    Spacer(minLength: 40)
                }
            }

            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedScore = result.score
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                contentAppeared = true
            }
            if result.foundKeyWord {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
        .sheet(isPresented: $showingLeaderboard) {
            WordDropLeaderboardView(date: game.publishDate, dropType: game.dropType)
        }
        .sheet(isPresented: $showingShareCard) {
            WordDropShareSheet(result: result, game: game, wordsFound: wordsFound)
        }
    }
}

// MARK: - Confetti Animation
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var timer: Timer?

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSince1970
                for particle in particles {
                    let elapsed = now - particle.startTime
                    guard elapsed < particle.lifetime else { continue }

                    let progress = elapsed / particle.lifetime
                    let x = particle.startX + particle.driftX * elapsed
                    let y = particle.startY + particle.speed * elapsed + 120 * elapsed * elapsed
                    let opacity = 1.0 - progress

                    guard y < size.height + 20 else { continue }

                    let rotation = Angle.degrees(particle.rotation + particle.rotationSpeed * elapsed)
                    let rect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)

                    context.opacity = opacity
                    context.fill(
                        Path(roundedRect: rect, cornerSize: CGSize(width: 2, height: 2))
                            .applying(CGAffineTransform(rotationAngle: rotation.radians)
                                .translatedBy(x: x, y: y)),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .onAppear {
            spawnBurst()
            // Second burst after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                spawnBurst()
            }
        }
    }

    private func spawnBurst() {
        let now = Date().timeIntervalSince1970
        let colors: [Color] = [
            Theme.accent,
            .yellow,
            .orange,
            .white,
            Color(red: 1, green: 0.84, blue: 0),
        ]

        for _ in 0..<40 {
            particles.append(ConfettiParticle(
                startX: CGFloat.random(in: 40...350),
                startY: CGFloat.random(in: -20...0),
                speed: CGFloat.random(in: 60...180),
                driftX: CGFloat.random(in: -40...40),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -200...200),
                lifetime: Double.random(in: 1.5...3.0),
                startTime: now,
                color: colors.randomElement()!
            ))
        }
    }
}

struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let speed: CGFloat
    let driftX: CGFloat
    let rotation: Double
    let rotationSpeed: Double
    let lifetime: Double
    let startTime: TimeInterval
    let color: Color
}

// MARK: - Flow Layout for word chips
struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
