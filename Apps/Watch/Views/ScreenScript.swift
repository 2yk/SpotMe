#if DEBUG
import SwiftUI
import RepCoachCore

/// Drives the demo app to one screen for screenshots: `-demo YES -day wednesday -screen rest`.
@MainActor
enum ScreenScript {
    static func run(today: TodayModel, workout: WorkoutModel, path: Binding<[TodayView.Route]>,
                    choosingDay: Binding<Bool>) {
        guard let screen = LaunchOptions.screen else { return }
        switch screen {
        case "days":
            choosingDay.wrappedValue = true
        case "checklist":
            if let item = today.day.items.first(where: { $0.steps != nil }) {
                path.wrappedValue = [.checklist(item)]
            }
        case "hold":
            guard let item = today.day.items.first(where: { $0.kind == .timed }) else { return }
            workout.begin([item])
            path.wrappedValue = [.exercise]
            workout.flow?.startHold()
        case "superset", "superset-next", "superset-rest":
            guard let item = today.day.items.first(where: { $0.supersetGroup != nil }) else { return }
            today.promote(item)
            guard screen != "superset" else { return }
            workout.begin(today.queue.upNext)
            path.wrappedValue = [.exercise]
            // A1 goes straight to B1; B1 is followed by the pair's rest.
            workout.flow?.logSet()
            if screen == "superset-rest" { workout.flow?.logSet() }
        case "amrap", "volume":
            guard let item = today.day.items.first(where: { $0.kind == .amrap }) else { return }
            today.promote(item)
            workout.begin([item])
            workout.flow?.reps = 12
            workout.flow?.logSet()
            if screen == "volume" {
                workout.end()
                if let volume = today.day.items.first(where: { $0.kind == .percentOfMax }) { today.promote(volume) }
            } else {
                path.wrappedValue = [.exercise]
            }
        case "set", "rest", "finished":
            workout.begin(today.queue.upNext)
            path.wrappedValue = [.exercise]
            guard let flow = workout.flow else { return }
            if screen == "rest" {
                // One rep under the range, so the rest screen shows the engine dropping the weight.
                flow.reps = Double((flow.currentTarget.repMin ?? 6) - 1)
                flow.logSet()
            } else if screen == "finished" {
                while flow.current != nil {
                    flow.reps = Double(flow.currentTarget.repMax ?? 10)
                    flow.logSet()
                }
            }
        default:
            break
        }
    }

    /// `-screen bottom`: scroll Today to its last row.
    static func scroll(_ proxy: ScrollViewProxy, today: TodayModel) async {
        guard LaunchOptions.screen == "bottom",
              let last = today.queue.finished.last ?? today.queue.remaining.last else { return }
        try? await Task.sleep(for: .seconds(0.5))
        proxy.scrollTo(last.id, anchor: .bottom)
    }
}
#endif
