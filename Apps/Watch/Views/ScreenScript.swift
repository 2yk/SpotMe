#if DEBUG
import SwiftUI
import RepCoachCore

/// Drives the demo app to one screen for screenshots: `-demo YES -day wednesday -screen rest`.
@MainActor
enum ScreenScript {
    static func run(today: TodayModel, workout: WorkoutModel, path: Binding<[TodayView.Route]>,
                    choosingDay: Binding<Bool>, confirmingFinish: Binding<Bool>, confirmingDiscard: Binding<Bool>,
                    open: (URL) -> Void) {
        guard let screen = LaunchOptions.screen else { return }
        if ["workout", "rest", "alldone", "finish-dialog", "next", "next-picker"].contains(screen) {
            workout.health.pretendRunning(heartRate: 128, minutes: 24)
        }
        func show(_ items: [PlanItem]) {
            workout.show(items)
            path.wrappedValue = [.workout]
        }
        switch screen {
        case "alldone":
            completeEverything(today)
        case "alldone-screen":
            completeEverything(today)
            workout.advance()
            path.wrappedValue = [.workout]
        case "finish-dialog":
            confirmingFinish.wrappedValue = true
        case "discard":
            confirmingDiscard.wrappedValue = true
        case "discarded":
            workout.discardWorkout()
        case "start-denied":
            workout.startProblem = WorkoutModel.accessDeniedMessage
        case "complications":
            path.wrappedValue = [.complications]
        case "tap-start":
            // What a complication tap delivers (simctl can't open links on watchOS).
            open(URL(string: "spotme://start")!)
        case "finish":
            // With `-sync YES`: finish the demo day so the watch sends it (and its history) to the phone.
            completeEverything(today)
            Task { await workout.finishWorkout() }
        case "firsttime":
            // The first weighted item not started today; with `-weeks 0` it has no history either.
            guard let item = today.day.items.first(where: { $0.kind == .weighted && today.log(for: $0) == nil })
            else { return }
            show([item])
        case "summary":
            workout.summary = WorkoutModel.Summary(savedToHealth: true, duration: 62 * 60 + 14,
                                                   averageHeartRate: 124, energy: 342, sets: 27)
        case "days":
            choosingDay.wrappedValue = true
        case "checklist":
            if let item = today.day.items.first(where: { $0.steps != nil }) { show([item]) }
        case "hold":
            guard let item = today.day.items.first(where: { $0.kind == .timed }) else { return }
            show([item])
            workout.flow?.startHold()
        case "superset", "superset-next", "superset-rest":
            guard let group = today.day.items.first(where: { $0.supersetGroup != nil })?.supersetGroup else { return }
            show(today.day.items.filter { $0.supersetGroup == group })
            guard screen != "superset" else { return }
            // A1 goes straight to B1; B1 is followed by the pair's rest.
            workout.flow?.logSet()
            if screen == "superset-rest" { workout.flow?.logSet() }
        case "amrap", "volume":
            guard let item = today.day.items.first(where: { $0.kind == .amrap }) else { return }
            show([item])
            guard screen == "volume" else { return }
            // Logging the max-rep set finishes it; the break then shows the volume sets at 60% of it.
            workout.flow?.reps = 12
            workout.flow?.logSet()
        case "set", "rest", "next", "next-picker":
            show(today.queue.upNext)
            guard let flow = workout.flow else { return }
            if screen == "rest" {
                // One rep under the range, so the rest screen shows the engine dropping the weight.
                flow.reps = Double((flow.currentTarget.repMin ?? 6) - 1)
                flow.logSet()
            } else if screen != "set" {
                while flow.current != nil {
                    flow.reps = Double(flow.currentTarget.repMax ?? 10)
                    flow.logSet()
                }
            }
        default:
            break
        }
    }

    private static func completeEverything(_ today: TodayModel) {
        for item in today.day.items where !today.status(of: item).isFinished {
            if item.kind == .checklist {
                today.complete(item)
            } else if let log = try? today.recorder.log(for: item.exerciseId, in: today.startSession()) {
                _ = try? today.recorder.addSet(to: log, weight: today.target(for: item).weight ?? 0, reps: 10)
                try? today.recorder.complete(log)
            }
        }
        today.refresh()
    }

    /// `-screen bottom`: scroll Today to its end.
    static func scroll(_ proxy: ScrollViewProxy, today: TodayModel) async {
        guard LaunchOptions.screen == "bottom" else { return }
        try? await Task.sleep(for: .seconds(0.5))
        proxy.scrollTo(TodayView.endOfList, anchor: .bottom)
    }
}
#endif
