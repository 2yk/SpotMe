#if DEBUG
import SwiftUI
import SwiftData
import RepCoachCore

/// Drives the demo app to one screen for screenshots: `-demo YES -day wednesday -screen swap -item machine-chest-press`.
@MainActor
enum PhoneScript {
    /// Today and what opens from it.
    static func today(today: TodayModel, detail: Binding<SlotRef?>) async {
        guard let screen = LaunchOptions.screen else { return }
        switch screen {
        case "running", "alldone":
            // Three items done (Warmup, Incline DB Press, Machine Chest Press).
            complete(today, first: screen == "alldone" ? today.day.items.count : 3)
            if screen == "alldone", let session = today.session {
                // What the watch sends at Finish.
                session.activeSeconds = 62 * 60
                session.energyKcal = 395
                session.effort = 7
                try? today.context.save()
                today.refresh()
            }
        default: break
        }
        if screen == "swap-later" || screen == "swapped" {
            // `-delay 20 -choice 1`: a swap made on the phone after a while (to the second row of the Swap sheet), for
            // watching it arrive on the watch.
            if screen == "swap-later" {
                try? await Task.sleep(for: .seconds(max(UserDefaults.standard.integer(forKey: "delay"), 1)))
            }
            let item = LaunchOptions.item.flatMap { id in today.day.items.first { $0.exerciseId == id } }
            let choices = item.map { today.swapChoices(for: $0) } ?? []
            let index = min(UserDefaults.standard.integer(forKey: "choice"), max(choices.count - 1, 0))
            if let item, choices.indices.contains(index) { today.swap(item, to: choices[index]) }
        }
        switch screen {
        case "detail", "swap", "exercise", "tickoff":
            let item = LaunchOptions.item.flatMap { id in today.day.items.first { $0.exerciseId == id } }
                ?? today.day.items.first { $0.kind == .weighted }
            if let item { detail.wrappedValue = SlotRef(id: today.slot(of: item).exerciseId) }
        default: break
        }
    }

    /// Every item of the day done but `except`.
    static func complete(_ today: TodayModel, first count: Int) {
        let ids = Set(today.day.items.prefix(count).map(\.exerciseId))
        for item in today.day.items where !today.status(of: item).isFinished && ids.contains(item.exerciseId) {
            if item.kind == .checklist {
                today.complete(item)
            } else if let log = try? today.writableLog(for: item) {
                _ = try? today.recorder.addSet(to: log, weight: today.target(for: item).weight ?? 0, reps: 10)
                try? today.recorder.complete(log)
            }
        }
        today.refresh()
    }

    /// History and what opens from it: `-screen session`, `exercise`, `body`, `body-warning`, `body-point`.
    static func history(path: Binding<[HistoryRoute]>, model: HistoryModel, today: TodayModel) {
        switch LaunchOptions.screen {
        case "session":
            if let row = model.sessions.first(where: { $0.isFinished }) ?? model.sessions.first {
                path.wrappedValue = [.session(row.id)]
            }
        case "exercise":
            let id = LaunchOptions.item ?? model.exercises.first(where: { $0.item.kind == .weighted })?.id
            if let id { path.wrappedValue = [.exercise(id)] }
        case "body", "body-warning", "body-add":
            path.wrappedValue = [.body]
        case "body-point":
            path.wrappedValue = [.body, .point(.arm)]
        default: break
        }
    }
}
#endif
