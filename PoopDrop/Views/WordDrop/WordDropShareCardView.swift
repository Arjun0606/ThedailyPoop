import SwiftUI

// MARK: - Word Drop Share Card
struct WordDropShareCardView: View {
    let result: WordGameSubmitResponse
    let game: WordGame
    let wordsFound: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Text("Aa")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.accent)
                    Text("WORD DROP")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Theme.accent)
                        .tracking(1.5)
                }

                Spacer()

                Text(game.publishDate)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.4))
            }

            // Score
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(result.score)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("pts")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
            }

            // Stats row
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("\(result.wordCount)")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                    Text("of \(result.totalPossibleWords) words")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Theme.textTertiary)
                }

                if result.foundKeyWord {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.accent)
                        Text("KEY WORD")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Theme.accent)
                            .tracking(1)
                    }
                }
            }

            // Divider
            Rectangle()
                .fill(Theme.accent.opacity(0.3))
                .frame(height: 1)

            // Word grid
            FlowLayout(spacing: 5) {
                ForEach(result.validatedWords, id: \.self) { word in
                    let isKeyWord = word == result.keyWord
                    Text(word.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(isKeyWord ? .black : .white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isKeyWord ? Theme.accent : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
            }

            // Footer
            HStack {
                Text("\u{1f4a9}")
                    .font(.caption)
                Text("thedailypoop.app")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(24)
        .frame(width: 360)
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.08), Color(red: 0.12, green: 0.1, blue: 0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Share Card Renderer
@MainActor
struct WordDropShareRenderer {
    @MainActor
    static func renderImage(result: WordGameSubmitResponse, game: WordGame, wordsFound: [String]) -> UIImage? {
        let view = WordDropShareCardView(result: result, game: game, wordsFound: wordsFound)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}

// MARK: - Share Card Sheet
struct WordDropShareSheet: View {
    let result: WordGameSubmitResponse
    let game: WordGame
    let wordsFound: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Share Your Score")
                        .font(.headline)
                        .foregroundStyle(.white)

                    WordDropShareCardView(result: result, game: game, wordsFound: wordsFound)
                        .padding(.horizontal, 20)

                    if let image = shareImage {
                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview("Word Drop - \(result.score) pts", image: Image(uiImage: image))
                        ) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Card")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.accent)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                    }

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            shareImage = WordDropShareRenderer.renderImage(result: result, game: game, wordsFound: wordsFound)
        }
    }
}
