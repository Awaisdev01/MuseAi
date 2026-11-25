import WidgetKit
import SwiftUI

struct ArtWidgetProvider: AppIntentTimelineProvider {

    private let dailyPrompts = [
        "A magical forest with glowing mushrooms at twilight",
        "Astronaut painting on a canvas floating in space",
        "Cozy bookshop on a rainy London street",
        "Crystal dragon perched on a mountain peak",
        "Underwater temple with bioluminescent coral",
        "Robot gardener tending to a rooftop garden at sunset"
    ]

    func placeholder(in context: Context) -> ArtWidgetEntry {
        ArtWidgetEntry(date: Date(), prompt: "A serene Japanese garden at sunset", configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> ArtWidgetEntry {
        ArtWidgetEntry(
            date: Date(),
            prompt: dailyPrompts.randomElement() ?? "Create something beautiful today",
            configuration: configuration
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<ArtWidgetEntry> {
        var entries: [ArtWidgetEntry] = []
        let currentDate = Date()

        for hourOffset in 0..<6 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset * 4, to: currentDate)!
            let prompt = dailyPrompts[hourOffset % dailyPrompts.count]
            entries.append(ArtWidgetEntry(date: entryDate, prompt: prompt, configuration: configuration))
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct ArtWidgetEntry: TimelineEntry {
    let date: Date
    let prompt: String
    let configuration: ConfigurationAppIntent
}

// MARK: - Widget Definition
struct ArtGeneratorWidget: Widget {
    let kind: String = "ArtGeneratorWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: ArtWidgetProvider()) { entry in
            ArtGeneratorWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Muse AI Inspiration")
        .description("Daily prompt ideas from Muse AI.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Views
struct ArtGeneratorWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ArtWidgetProvider.Entry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: ArtWidgetEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.45, blue: 0.71),
                    Color(red: 0.88, green: 0.11, blue: 0.45)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.white)

                Spacer()

                Text(entry.prompt)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)

                Text("Tap to create")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(14)
        }
    }
}

struct MediumWidgetView: View {
    let entry: ArtWidgetEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.45, blue: 0.71),
                    Color(red: 0.88, green: 0.11, blue: 0.45)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.headline)
                        Text("Muse AI")
                            .font(.headline)
                    }
                    .foregroundColor(.white)

                    Spacer()

                    Text(entry.prompt)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)

                    Text("Tap to generate this image →")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 100)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.3))
                    )
            }
            .padding(16)
        }
    }
}

#Preview(as: .systemSmall) {
    ArtGeneratorWidget()
} timeline: {
    ArtWidgetEntry(date: .now, prompt: "A magical forest with glowing mushrooms", configuration: ConfigurationAppIntent())
}

#Preview(as: .systemMedium) {
    ArtGeneratorWidget()
} timeline: {
    ArtWidgetEntry(date: .now, prompt: "Astronaut painting on a canvas floating in space", configuration: ConfigurationAppIntent())
}
