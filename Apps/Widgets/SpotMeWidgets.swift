import SwiftUI
import WidgetKit
import RepCoachCore

@main
struct SpotMeWidgets: WidgetBundle {
    var body: some Widget {
        StartWorkoutWidget()
    }
}

/// A watch face complication: today's session, and one tap to open SpotMe and start it.
struct StartWorkoutWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StartWorkout", provider: TodayProvider()) { entry in
            StartWorkoutView(entry: entry)
                .widgetURL(entry.url)
                .containerBackground(Theme.volt.gradient.opacity(0.3), for: .widget)
        }
        .configurationDisplayName("Start workout")
        .description("Today's session. Tap to start it.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline])
    }
}

/// An entry for now and one for each coming midnight: the plan day follows the weekday, nothing else.
struct TodayProvider: TimelineProvider {
    private static let plan = try? Plan.bundled().withoutRuns()

    func placeholder(in context: Context) -> TodayEntry {
        entry(on: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(entry(on: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let calendar = Calendar.current
        let midnights = (1...7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: .now))
        }
        completion(Timeline(entries: [entry(on: .now)] + midnights.map(entry(on:)), policy: .atEnd))
    }

    private func entry(on date: Date) -> TodayEntry {
        TodayEntry(date: date, day: Self.plan?.day(for: date))
    }
}
