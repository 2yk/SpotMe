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
        if ["workout", "rest", "alldone", "finish-dialog", "next", "next-picker", "controls", "paused", "media",
            "paused-rest", "skipped", "running", "running-paused", "running-end", "paused-set", "break-checklist",
            "break-pick", "running-waiting", "break-back", "effort", "superset", "superset-next", "superset-rest", "how"].contains(screen) || UserDefaults.standard.bool(forKey: "running") {
            workout.health.pretendRunning(heartRate: 128, minutes: 24)
        }
        func show(_ items: [PlanItem]) {
            workout.show(items)
            path.wrappedValue = [.workout]
        }
        switch screen {
        case "running", "running-paused", "running-end":
            // Three items done (Warmup, Incline DB Press, Machine Chest Press): Continue leads to the next one.
            complete(today, first: 3)
            if screen == "running-paused" { workout.pause() }
        case "paused-set":
            show(today.queue.upNext)
            workout.pause()
        case "break-checklist":
            // Everything but the last exercise and the cooldown is done; finishing it starts the break.
            guard let last = today.day.items.last(where: { $0.kind != .checklist }) else { return }
            complete(today, except: [last.exerciseId, today.day.items.last?.exerciseId ?? ""])
            show([last])
            while let flow = workout.flow, flow.current != nil {
                flow.reps = Double(flow.currentTarget.repMax ?? 10)
                flow.logSet()
            }
        case "running-waiting":
            // Shoulder press has one set logged and is put off: Today shows it waiting, Continue names the next.
            complete(today, first: 3)
            if let item = today.day.items.first(where: { $0.exerciseId == "seated-db-shoulder-press" }) {
                show([item])
                workout.flow?.logSet()
                workout.skip()
            }
            path.wrappedValue = []
        case "break-back":
            // The shoulder press is put off after one set; the last exercise is done, and the break leads back.
            guard let last = today.day.items.last(where: { $0.kind != .checklist }),
                  let item = today.day.items.first(where: { $0.exerciseId == "seated-db-shoulder-press" })
            else { return }
            complete(today, except: [item.exerciseId, last.exerciseId])
            show([item])
            workout.flow?.logSet()
            workout.skip()
            while let flow = workout.flow, flow.current != nil {
                flow.reps = Double(flow.currentTarget.repMax ?? 10)
                flow.logSet()
            }
        case "list":
            break
        case "alldone":
            completeEverything(today)
        case "alldone-screen":
            // The last exercise is done by hand, so its break (here: the end of the day) shows how it went.
            guard let last = today.day.items.last(where: { $0.kind != .checklist }) else { return }
            complete(today, except: [last.exerciseId])
            show([last])
            while let flow = workout.flow, flow.current != nil {
                flow.reps = Double(flow.currentTarget.repMax ?? 10)
                flow.logSet()
            }
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
        case "effort":
            workout.effortPrompt = WorkoutModel.EffortPrompt(initial: 7)
        case "summary-effort":
            workout.summary = WorkoutModel.Summary(title: today.day.headline, savedToHealth: true,
                                                   duration: 62 * 60 + 14, averageHeartRate: 124, energy: 342,
                                                   sets: 27, effort: 7)
        case "summary":
            workout.summary = WorkoutModel.Summary(title: today.day.headline, savedToHealth: true,
                                                   duration: 62 * 60 + 14,
                                                   averageHeartRate: 124, energy: 342, sets: 27)
        case "days":
            choosingDay.wrappedValue = true
        case "checklist", "checklist-end":
            if let item = today.day.items.first(where: { $0.steps != nil }) { show([item]) }
        case "hold":
            guard let item = today.day.items.first(where: { $0.kind == .timed }) else { return }
            show([item])
            if UserDefaults.standard.string(forKey: "elapsed") != nil { workout.flow?.startHold() }
            if let elapsed = UserDefaults.standard.string(forKey: "elapsed").flatMap(Double.init) {
                workout.flow?.debugHold(elapsed: elapsed + shotDelay)
            }
        case "superset", "superset-next", "superset-rest":
            guard let group = today.day.items.first(where: { $0.supersetGroup != nil })?.supersetGroup else { return }
            show(today.day.items.filter { $0.supersetGroup == group })
            guard screen != "superset" else { return }
            // A1 goes straight to B1; B1 is followed by the pair's rest.
            workout.flow?.logSet()
            if screen == "superset-rest" { workout.flow?.logSet() }
        case "amrap", "volume", "volume-set":
            guard let item = today.day.items.first(where: { $0.kind == .amrap }) else { return }
            // Everything before the max-rep set is done, so what's next after it is the volume sets.
            let mine = today.day.items.filter { $0.kind == .amrap || $0.kind == .percentOfMax }.map(\.exerciseId)
            complete(today, except: mine)
            show([item])
            guard screen != "amrap" else { return }
            // Logging the max-rep set finishes it; the break then shows the volume sets at 60% of it.
            workout.flow?.reps = 12
            workout.flow?.logSet()
            if screen == "volume-set" { workout.advance() }
        case "item":
            // `-item hanging-leg-raise`: that item's set screen; `-log 1 -reps 17`: after that many sets.
            let id = UserDefaults.standard.string(forKey: "item")
            if let item = today.day.items.first(where: { $0.exerciseId == id }) { show([item]) }
            // `-ramps 2`: after that many ramp-up sets.
            let ramps = UserDefaults.standard.string(forKey: "ramps").flatMap(Int.init) ?? 0
            for index in 0..<ramps {
                workout.flow?.doneRampUp()
                if index < ramps - 1 { workout.flow?.endRest() }
            }
            let logged = UserDefaults.standard.string(forKey: "log").flatMap(Int.init) ?? 0
            for _ in 0..<logged {
                if let reps = UserDefaults.standard.string(forKey: "reps").flatMap(Double.init) {
                    workout.flow?.reps = reps
                }
                workout.flow?.logSet()
            }
        case "controls", "media", "paused", "skipped":
            // The pager on the first exercise not done yet; paused, or after Skip.
            show(today.queue.upNext)
            if screen == "paused" { workout.pause() }
            if screen == "skipped" { workout.skip() }
        case "paused-rest":
            show(today.queue.upNext)
            workout.flow?.logSet()
            workout.pause()
        case "set", "rest", "next", "next-picker", "how":
            show(today.queue.upNext)
            guard let flow = workout.flow else { return }
            if screen == "rest" {
                // One rep under the range, so the rest screen shows the engine dropping the weight.
                flow.reps = Double((flow.currentTarget.repMin ?? 6) - 1)
                flow.logSet()
            } else if screen != "set" && screen != "how" {
                while flow.current != nil {
                    flow.reps = Double(flow.currentTarget.repMax ?? 10)
                    flow.logSet()
                }
            }
        default:
            break
        }
        // `-left 108 -of 150`: age the rest or break on screen, to match a board's time.
        // The time is what the screenshot shows, taken a few seconds after launch.
        if let left = UserDefaults.standard.string(forKey: "left").flatMap(Double.init) {
            let length = UserDefaults.standard.string(forKey: "of").flatMap(Double.init) ?? 150
            workout.flow?.debugRest(left: left + shotDelay, of: length)
            workout.debugBreak(left: left + shotDelay, of: length)
        }
    }

    /// Seconds between launching and the screenshot (`Scripts/watch-shot.sh`).
    private static let shotDelay = 4.5

    /// The first `count` items of the day done, with the sets the plan asks for.
    private static func complete(_ today: TodayModel, first count: Int) {
        let ids = Set(today.day.items.prefix(count).map(\.exerciseId))
        completeEverything(today, only: ids)
    }

    /// Every item done but `except`.
    private static func complete(_ today: TodayModel, except ids: [String]) {
        completeEverything(today, only: Set(today.day.items.map(\.exerciseId)).subtracting(ids))
    }

    private static func completeEverything(_ today: TodayModel, only ids: Set<String>? = nil) {
        for item in today.day.items where !today.status(of: item).isFinished && ids?.contains(item.exerciseId) != false {
            if item.kind == .checklist {
                today.complete(item)
            } else if let log = try? today.recorder.log(for: item.exerciseId, in: today.startSession()) {
                _ = try? today.recorder.addSet(to: log, weight: today.target(for: item).weight ?? 0, reps: 10)
                try? today.recorder.complete(log)
            }
        }
        today.refresh()
    }

    /// `-screen bottom`: scroll Today to its end. `list`: to the third open item, which sits under the bar.
    static func scroll(_ proxy: ScrollViewProxy, today: TodayModel) async {
        switch LaunchOptions.screen {
        case "bottom", "running-end":
            try? await Task.sleep(for: .seconds(0.5))
            proxy.scrollTo(TodayView.endOfList, anchor: .bottom)
        case "list":
            try? await Task.sleep(for: .seconds(0.5))
            if let item = today.queue.upNext.first.map({ _ in today.day.items.filter { !today.status(of: $0).isFinished } })?.dropFirst(2).first {
                proxy.scrollTo(item.exerciseId, anchor: .top)
            }
        default:
            return
        }
    }
}
#endif
