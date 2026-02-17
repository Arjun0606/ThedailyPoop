import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct BriefingEntry: TimelineEntry {
    let date: Date
    let headline: String
    let storyCount: Int
    let topStories: [WidgetStory]
    let isPlaceholder: Bool

    static var placeholder: BriefingEntry {
        BriefingEntry(
            date: Date(),
            headline: "Today's Briefing",
            storyCount: 10,
            topStories: [
                WidgetStory(emoji: "\ud83d\udcb0", headline: "Markets rally on tech earnings"),
                WidgetStory(emoji: "\ud83d\udcf1", headline: "Apple unveils new AI features"),
                WidgetStory(emoji: "\ud83c\udfac", headline: "Oscar nominations announced")
            ],
            isPlaceholder: true
        )
    }
}

struct WidgetStory {
    let emoji: String
    let headline: String
}

// MARK: - Timeline Provider
struct BriefingProvider: TimelineProvider {
    func placeholder(in context: Context) -> BriefingEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BriefingEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        loadEntry { entry in
            completion(entry ?? .placeholder)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BriefingEntry>) -> Void) {
        loadEntry { entry in
            let current = entry ?? .placeholder
            // Refresh every 30 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
            let timeline = Timeline(entries: [current], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func loadEntry(completion: @escaping (BriefingEntry?) -> Void) {
        // Read from shared UserDefaults (App Group)
        guard let defaults = UserDefaults(suiteName: "group.com.thedailypoop.app") else {
            completion(nil)
            return
        }

        let headline = defaults.string(forKey: "widget_headline") ?? "No briefing yet"
        let storyCount = defaults.integer(forKey: "widget_story_count")
        let storiesData = defaults.array(forKey: "widget_stories") as? [[String: String]] ?? []

        let stories = storiesData.prefix(3).map { dict in
            WidgetStory(
                emoji: dict["emoji"] ?? "\ud83d\udcf0",
                headline: dict["headline"] ?? ""
            )
        }

        let entry = BriefingEntry(
            date: Date(),
            headline: headline,
            storyCount: storyCount > 0 ? storyCount : 10,
            topStories: stories,
            isPlaceholder: stories.isEmpty
        )
        completion(entry)
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: BriefingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\u{1f4a9}")
                    .font(.title3)
                Text("TODAY")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.brown)
                    .tracking(1)
            }

            if let first = entry.topStories.first {
                Text(first.headline)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Text("\(entry.storyCount) stories")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: BriefingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Text("\u{1f4a9}")
                        .font(.subheadline)
                    Text("TheDailyPoop")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(entry.topStories.prefix(3).enumerated()), id: \.offset) { _, story in
                HStack(spacing: 8) {
                    Text(story.emoji)
                        .font(.caption)
                    Text(story.headline)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }

            if entry.topStories.count < entry.storyCount {
                Text("+\(entry.storyCount - entry.topStories.count) more stories")
                    .font(.caption2)
                    .foregroundStyle(.brown)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }
}

// MARK: - Widget Configuration
struct PoopDropWidget: Widget {
    let kind = "PoopDropWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BriefingProvider()) { entry in
            if #available(iOS 17.0, *) {
                WidgetContent(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WidgetContent(entry: entry)
            }
        }
        .configurationDisplayName("Daily Briefing")
        .description("Today's top stories at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetContent: View {
    @Environment(\.widgetFamily) var family
    let entry: BriefingEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle
@main
struct PoopDropWidgetBundle: WidgetBundle {
    var body: some Widget {
        PoopDropWidget()
    }
}
