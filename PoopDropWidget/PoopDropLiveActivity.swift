import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Live Activity Widget (Dynamic Island + Lock Screen)

struct PoopDropLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PoopDropActivityAttributes.self) { context in
            // LOCK SCREEN banner
            LockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED view (long press / large state)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Text(PoopDropActivityAttributes.dropEmoji(for: context.state.dropType))
                            .font(.title3)
                        Text(PoopDropActivityAttributes.dropLabel(for: context.state.dropType))
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(1)
                            .foregroundStyle(dropColor(for: context.state.dropType))
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.storyCount)")
                        .font(.system(size: 20, weight: .black).monospacedDigit())
                        .foregroundStyle(.white)
                    +
                    Text(" stories")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        Text(context.state.headline)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            Text("Tap to read")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(dropColor(for: context.state.dropType))

                            Spacer()

                            Text(context.state.publishDate)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // COMPACT leading (small pill — left side)
                HStack(spacing: 4) {
                    Text(PoopDropActivityAttributes.dropEmoji(for: context.state.dropType))
                        .font(.system(size: 14))
                    Text("DROP")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(dropColor(for: context.state.dropType))
                }
            } compactTrailing: {
                // COMPACT trailing (small pill — right side)
                Text("\(context.state.storyCount)")
                    .font(.system(size: 14, weight: .bold).monospacedDigit())
                    .foregroundStyle(dropColor(for: context.state.dropType))
            } minimal: {
                // MINIMAL (tiny circle when another activity is present)
                Text("\u{1F4A9}")
                    .font(.system(size: 14))
            }
        }
    }

    private func dropColor(for dropType: String) -> Color {
        switch dropType {
        case "morning": return Color(red: 1.0, green: 0.76, blue: 0.28)
        case "midday": return Color(red: 1.0, green: 0.55, blue: 0.2)
        case "evening": return Color(red: 0.5, green: 0.4, blue: 1.0)
        default: return .white.opacity(0.6)
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    let state: PoopDropActivityAttributes.ContentState

    private var color: Color {
        switch state.dropType {
        case "morning": return Color(red: 1.0, green: 0.76, blue: 0.28)
        case "midday": return Color(red: 1.0, green: 0.55, blue: 0.2)
        case "evening": return Color(red: 0.5, green: 0.4, blue: 1.0)
        default: return .white.opacity(0.6)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Left accent
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {
                // Drop label
                HStack(spacing: 6) {
                    Text(PoopDropActivityAttributes.dropEmoji(for: state.dropType))
                        .font(.caption)
                    Text(PoopDropActivityAttributes.dropLabel(for: state.dropType))
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1)
                        .foregroundStyle(color)

                    Spacer()

                    Text("\(state.storyCount) stories")
                        .font(.system(size: 11, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Headline
                Text(state.headline)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    }
}
