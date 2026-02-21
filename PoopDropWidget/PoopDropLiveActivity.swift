import ActivityKit
import SwiftUI
import WidgetKit

struct PoopDropLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PoopDropActivityAttributes.self) { context in
            LockScreenView(state: context.state)
        } dynamicIsland: { context in
            let state = context.state
            let color = dropColor(for: state.dropType)
            let progress = state.storyCount > 0
                ? Double(state.readCount) / Double(state.storyCount) : 0

            return DynamicIsland {
                // EXPANDED — long press on Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(PoopDropActivityAttributes.dropLabel(for: state.dropType))
                                .font(.system(size: 10, weight: .heavy))
                                .tracking(0.8)
                                .foregroundStyle(color)
                            Text(state.publishDate)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(state.readCount)/\(state.storyCount)")
                            .font(.system(size: 16, weight: .black).monospacedDigit())
                            .foregroundStyle(.white)
                        Text("read")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        // Read progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.08))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(color)
                                    .frame(width: max(geo.size.width * progress, 4), height: 4)
                            }
                        }
                        .frame(height: 4)

                        // Headline
                        Text(state.headline)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Bottom row: vibe + CTA
                        HStack {
                            if !state.vibeEmoji.isEmpty {
                                HStack(spacing: 4) {
                                    Text(state.vibeEmoji)
                                        .font(.system(size: 12))
                                    Text(state.vibeLabel)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }

                            Spacer()

                            Text(state.readCount == 0 ? "Tap to start reading" : "Continue reading")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(color)
                        }
                    }
                    .padding(.top, 2)
                }
            } compactLeading: {
                // COMPACT leading — logo + progress
                HStack(spacing: 4) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))

                    if state.readCount > 0 {
                        Text("\(state.readCount)/\(state.storyCount)")
                            .font(.system(size: 10, weight: .bold).monospacedDigit())
                            .foregroundStyle(color)
                    } else {
                        Text("NEW")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(color)
                    }
                }
            } compactTrailing: {
                // COMPACT trailing — vibe emoji or drop emoji
                Text(state.vibeEmoji.isEmpty
                    ? PoopDropActivityAttributes.dropEmoji(for: state.dropType)
                    : state.vibeEmoji)
                    .font(.system(size: 14))
            } minimal: {
                // MINIMAL — app logo
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
        }
    }

    private func dropColor(for dropType: String) -> Color {
        let rgb = PoopDropActivityAttributes.dropColorRGB(for: dropType)
        return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    let state: PoopDropActivityAttributes.ContentState

    private var color: Color {
        let rgb = PoopDropActivityAttributes.dropColorRGB(for: state.dropType)
        return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    private var progress: Double {
        state.storyCount > 0 ? Double(state.readCount) / Double(state.storyCount) : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar across the top
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.white.opacity(0.06))
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 3)

            HStack(spacing: 14) {
                // App logo
                Image("AppLogo")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    // Top row: label + read count
                    HStack(spacing: 6) {
                        Text(PoopDropActivityAttributes.dropLabel(for: state.dropType))
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1)
                            .foregroundStyle(color)

                        Spacer()

                        Text("\(state.readCount)/\(state.storyCount) read")
                            .font(.system(size: 11, weight: .bold).monospacedDigit())
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    // Headline
                    Text(state.headline)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    // Bottom: vibe + CTA
                    HStack {
                        if !state.vibeEmoji.isEmpty {
                            HStack(spacing: 3) {
                                Text(state.vibeEmoji)
                                    .font(.system(size: 11))
                                Text(state.vibeLabel)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }

                        Spacer()

                        Text(state.readCount == 0 ? "Tap to start" : "Continue")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(color)
                    }
                }
            }
            .padding(14)
        }
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    }
}
