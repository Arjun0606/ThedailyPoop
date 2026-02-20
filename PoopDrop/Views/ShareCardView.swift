import SwiftUI

// MARK: - Bottom Line Share Card
struct BottomLineCardView: View {
    let story: Story

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category
            HStack {
                Text("\(story.categoryEmoji) \(story.categoryLabel)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(0.5)

                Spacer()

                Text("TheDailyPoop")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.accent)
                    .tracking(1)
            }

            // Headline
            Text(story.headline)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            // Divider
            Rectangle()
                .fill(Theme.accent.opacity(0.3))
                .frame(height: 1)

            // Bottom Line
            if let bottomLine = story.bottomLine {
                VStack(alignment: .leading, spacing: 6) {
                    Text("THE BOTTOM LINE")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Theme.accent)
                        .tracking(2)

                    Text(bottomLine)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if let tldr = story.tldr {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TLDR")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Theme.accent)
                        .tracking(2)

                    Text(tldr)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Footer
            HStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                Text("thedailypoop.app")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
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

// MARK: - Card Image Renderer
@MainActor
struct ShareCardRenderer {
    @MainActor
    static func renderImage(for story: Story) -> UIImage? {
        let view = BottomLineCardView(story: story)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0 // Retina
        return renderer.uiImage
    }
}

// MARK: - Share Card Sheet
struct ShareCardSheet: View {
    let story: Story
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Share This Take")
                        .font(.headline)
                        .foregroundStyle(.white)

                    BottomLineCardView(story: story)
                        .padding(.horizontal, 20)

                    if let image = shareImage {
                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview(story.headline, image: Image(uiImage: image))
                        ) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Card")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
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
            shareImage = ShareCardRenderer.renderImage(for: story)
        }
    }
}
