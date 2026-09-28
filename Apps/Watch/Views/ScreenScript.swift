#if DEBUG
import SwiftUI
import RepCoachCore

/// Drives the demo app to one screen for screenshots: `-demo YES -day wednesday -screen rest`.
@MainActor
enum ScreenScript {
    static func run(today: TodayModel, workout: WorkoutModel, path: Binding<[TodayView.Route]>,
                    choosingDay: Binding<Bool>) {
        guard let screen = LaunchOptions.screen else { return }
        if ["workout", "rest", "alldone"].contains(screen) {
            workout.health.pretendRunning(heartRate: 128, minutes: 24)
        }
        switch screen {
        case "alldone":
            for item in today.day.items where !today.status(of: item).isFinished {
                if item.kind == .checklist {
                    today.complete(item)
                } else if let log = try? today.recorder.log(for: item.exerciseId, in: today.startSession()) {
                    _ = try? today.recorder.addSet(to: log, weight: today.target(for: item).weight ?? 0, reps: 10)
                    try? today.recorder.complete(log)
                }
            }
            today.refresh()
        case "firsttime", "firsttime-card":
            // The first weighted item not started today; with `-weeks 0` it has no history either.
            guard let item = today.day.items.first(where: { $0.kind == .weighted && today.log(for: $0) == nil })
            else { return }
            today.promote(item)
            if screen == "firsttime" {
                workout.begin([item])
                path.wrappedValue = [.exercise]
            }
        case "start":
            // A finished session and no workout running: the Start button shows (needs `-healthkit YES`).
            if let session = today.session { try? today.recorder.finish(session) }
            today.refresh()
        case "summary":
            workout.summary = WorkoutModel.Summary(savedToHealth: true, duration: 62 * 60 + 14,
                                                   averageHeartRate: 124, energy: 342, sets: 27)
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

    /// `-screen bottom` and `-screen start`: scroll Today to its end.
    static func scroll(_ proxy: ScrollViewProxy, today: TodayModel) async {
        guard ["bottom", "start"].contains(LaunchOptions.screen) else { return }
        try? await Task.sleep(for: .seconds(0.5))
        proxy.scrollTo(TodayView.endOfList, anchor: .bottom)
    }
}
#endif
