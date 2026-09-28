import SwiftUI
import WidgetKit
import RepCoachCore

/// What the Start workout complication shows: today's plan day, straight from the bundled plan.
struct TodayEntry: TimelineEntry {
    let date: Date
    /// "Pull A", or "Rest day".
    let name: String
    /// "Strength & Thickness", when the focus has one.
    let detail: String?
    /// Nothing to lift today.
    let isRest: Bool

    init(date: Date, day: PlanDay?) {
        self.date = date
        let parts = (day?.focus ?? "SpotMe").components(separatedBy: " · ")
        isRest = !(day?.items.contains { $0.kind != .checklist } ?? false)
        name = isRest ? "Rest day" : parts[0]
        detail = isRest || parts.count < 2 ? nil : parts.dropFirst().joined(separator: " · ")
    }

    /// Short enough for the circle: "Pull A", "Legs", "Mobility".
    var badge: String { isRest ? "Rest" : name.components(separatedBy: " + ")[0] }

    /// Taps open SpotMe on today; on a training day they start the workout too.
    var url: URL { URL(string: isRest ? "spotme://today" : "spotme://start")! }
}

/// The Start workout complication in whichever slot the watch face gives it.
struct StartWorkoutView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodayEntry

    var body: some View {
        switch family {
        case .accessoryCircular: StartCircular(entry: entry)
        case .accessoryCorner: StartCorner(entry: entry)
        case .accessoryInline: StartInline(entry: entry)
        default: StartRectangular(entry: entry)
        }
    }
}

struct StartCircular: View {
    let entry: TodayEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                MarkImage().frame(width: 22, height: 22)
                Text(entry.badge)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 4)
        }
    }
}

struct StartCorner: View {
    let entry: TodayEntry

    var body: some View {
        MarkImage()
            .padding(5)
            .widgetLabel { Text(entry.isRest ? "Rest day" : "Start \(entry.badge)") }
    }
}

struct StartRectangular: View {
    let entry: TodayEntry

    var body: some View {
        HStack(spacing: 8) {
            MarkImage().frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.isRest ? "SpotMe" : "Start workout")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.volt)
                    .widgetAccentable()
                Text(entry.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(entry.detail ?? (entry.isRest ? "Recovery day" : "Today"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }
}

struct StartInline: View {
    let entry: TodayEntry

    var body: some View {
        Text("SpotMe · \(entry.name)")
    }
}

/// The Cradle mark in volt, or in the watch face's tint where the face asks for one.
struct MarkImage: View {
    var body: some View {
        Image("Mark")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Theme.volt)
            .widgetAccentable()
    }
}
