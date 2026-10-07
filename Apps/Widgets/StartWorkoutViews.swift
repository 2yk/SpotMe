import SwiftUI
import WidgetKit
import RepCoachCore

/// What the Start workout complication shows: today's plan day from the bundled plan, and where the session
/// stands (Start workout, the next item, Done) as the watch app last told it through the app group.
struct TodayEntry: TimelineEntry {
    let date: Date
    /// "Pull A", or "Rest day".
    let name: String
    /// "Strength & Thickness", when the focus has one.
    let detail: String?
    /// Nothing to lift today.
    let isRest: Bool
    let phase: ComplicationState.Phase
    /// While running: the item up next.
    let next: String?
    let done: Int
    let total: Int

    init(date: Date, day: PlanDay?, state: ComplicationState? = nil) {
        self.date = date
        let parts = (day?.focus ?? "SpotMe").components(separatedBy: " · ")
        isRest = !(day?.items.contains { $0.kind != .checklist } ?? false)
        name = isRest ? "Rest day" : parts[0]
        detail = isRest || parts.count < 2 ? nil : parts.dropFirst().joined(separator: " · ")
        // Only for a training day, and only if the app wrote it for this very day.
        let live = isRest ? nil : state
        phase = live?.phase ?? .notStarted
        next = live?.next
        done = live?.done ?? 0
        total = live?.total ?? 0
    }

    /// The small caps line of the rectangular slot.
    var eyebrow: String {
        switch phase {
        case .notStarted: isRest ? "SpotMe" : "Start workout"
        case .running: "Up next"
        case .finished: "Done"
        }
    }

    /// The big line: the day; the next item while it runs.
    var title: String {
        phase == .running ? next ?? name : name
    }

    /// The grey line under it.
    var subtitle: String {
        switch phase {
        case .notStarted: detail ?? (isRest ? "Recovery day" : "Today")
        case .running: "\(name) · \(done)/\(total)"
        case .finished: done >= total ? "All \(total) done" : "\(done) of \(total) done"
        }
    }

    /// Short enough for the circle: "Pull A", "Legs", "Mobility".
    var badge: String { isRest ? "Rest" : name.components(separatedBy: " + ")[0] }

    /// Taps open SpotMe where it is: on a training day with nothing started they start the workout; with a
    /// workout under way they go back to it; on a finished day they show it.
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
                Text(entry.phase == .finished ? "Done" : entry.badge)
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
            .widgetLabel {
                switch entry.phase {
                case .notStarted: Text(entry.isRest ? "Rest day" : "Start \(entry.badge)")
                case .running: Text("Next \(entry.next ?? entry.badge)")
                case .finished: Text("\(entry.badge) done")
                }
            }
    }
}

struct StartRectangular: View {
    let entry: TodayEntry

    var body: some View {
        HStack(spacing: 8) {
            MarkImage().frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.eyebrow)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.volt)
                    .widgetAccentable()
                Text(entry.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(entry.subtitle)
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
        switch entry.phase {
        case .notStarted: Text("SpotMe · \(entry.name)")
        case .running: Text("Next · \(entry.next ?? entry.name)")
        case .finished: Text("SpotMe · \(entry.name) done")
        }
    }
}

/// The Cradle mark, drawn: complications drop images that are too large, shapes always render.
/// The dot takes the watch face's accent colour where the face tints complications.
struct MarkImage: View {
    var body: some View {
        ZStack {
            CradleShape(part: .cradle).fill(.white)
            CradleShape(part: .dot).fill(Theme.volt).widgetAccentable()
        }
        .aspectRatio(CradleShape.aspectRatio, contentMode: .fit)
    }
}
