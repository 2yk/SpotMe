import Foundation
import OSLog
import SwiftData
import RepCoachCore

/// One plan day as it stands today: targets, order and progress. Shared by the watch and the phone.
@MainActor @Observable
final class TodayModel {
    let plan: Plan
    let context: ModelContext
    @ObservationIgnored let settingsStore: SettingsStore
    @ObservationIgnored var calendar = Calendar.current

    private(set) var dayKey: String
    /// The plan day with the user's overrides applied.
    private(set) var day: PlanDay
    private(set) var session: WorkoutSession?
    private(set) var queue: TodayQueue
    private(set) var targets: [String: ItemTarget] = [:]
    private(set) var statuses: [String: ItemStatus] = [:]
    private(set) var isDeload = false
    private(set) var promotedId: String?
    /// False once the user picks another day, so midnight doesn't move them.
    private var followsToday: Bool

    init(plan: Plan, context: ModelContext, settings: SettingsStore, dayKey: String? = nil) {
        self.plan = plan
        self.context = context
        self.settingsStore = settings
        let requested = plan.days.first { $0.key == dayKey }
        let day = requested ?? plan.day(for: .now) ?? plan.days[0]
        self.dayKey = day.key
        self.day = day
        self.followsToday = requested == nil
        self.queue = TodayQueue(items: day.items, statuses: [:])
        refresh()
    }

    var settings: TrainingSettings { settingsStore.settings }
    var recorder: WorkoutRecorder { WorkoutRecorder(context: context, calendar: calendar) }
    var history: HistoryStore { HistoryStore(context: context) }
    var isToday: Bool { dayKey == plan.day(for: .now, calendar: calendar)?.key }

    func target(for item: PlanItem) -> ItemTarget {
        targets[item.exerciseId] ?? ItemTarget(sets: item.sets ?? 0)
    }

    func status(of item: PlanItem) -> ItemStatus {
        statuses[item.exerciseId] ?? .pending
    }

    /// Today's log of `item`, if it has been started.
    func log(for item: PlanItem) -> ExerciseLog? {
        session?.log(for: item.exerciseId)
    }

    /// Previous non-deload sessions of an exercise, newest first, leaving out today's.
    func pastSessions(of exerciseId: String) -> [[LoggedSet]] {
        (try? history.history(for: exerciseId, excluding: session?.id)) ?? []
    }

    func select(_ key: String) {
        guard key != dayKey, plan.days.contains(where: { $0.key == key }) else { return }
        dayKey = key
        followsToday = key == plan.day(for: .now, calendar: calendar)?.key
        promotedId = nil
        refresh()
    }

    /// Back to today's plan day, following the date again.
    func showToday() {
        guard let key = plan.day(for: .now, calendar: calendar)?.key else { return }
        select(key)
        followsToday = true
    }

    /// Call when the app comes to the foreground: picks up a new day after midnight.
    func wake() {
        if followsToday, let key = plan.day(for: .now, calendar: calendar)?.key, key != dayKey {
            dayKey = key
            promotedId = nil
        }
        refresh()
    }

    func refresh() {
        let recorder = recorder
        session = try? recorder.session(for: dayKey, on: .now)
        isDeload = session?.isDeload ?? settings.isDeload(on: .now, plan: plan, calendar: calendar)

        let overrides = Dictionary(
            ((try? context.fetch(FetchDescriptor<ExerciseSettings>())) ?? []).map { ($0.exerciseId, $0.overrides) },
            uniquingKeysWith: { first, _ in first })
        guard var day = plan.days.first(where: { $0.key == dayKey }) else { return }
        day.items = day.items.map { $0.applying(overrides[$0.exerciseId]) }
        self.day = day
        statuses = session?.statuses ?? [:]

        var targets: [String: ItemTarget] = [:]
        for item in day.items {
            var amrap: Int?
            if item.kind == .percentOfMax, let source = item.sourceExerciseId {
                let today = session?.log(for: source)?.orderedSets.map(\.loggedSet)
                amrap = TargetPlanner.amrapReps(today: today, history: pastSessions(of: source))
            }
            targets[item.exerciseId] = TargetPlanner.target(
                for: item, history: pastSessions(of: item.exerciseId), deload: isDeload,
                startWeight: overrides[item.exerciseId]?.startWeight, amrap: amrap)
        }
        self.targets = targets

        if let promotedId, statuses[promotedId]?.isFinished == true { self.promotedId = nil }
        queue = TodayQueue(items: day.items, statuses: statuses, promoted: promotedId)
    }

    /// Today's session, started on first use with the day's deload state.
    func startSession() throws -> WorkoutSession {
        if let session { return session }
        let started = try recorder.startSession(for: dayKey, on: .now, isDeload: isDeload)
        session = started
        return started
    }

    /// Makes `item` up next, e.g. when the machine for the current one is busy.
    func promote(_ item: PlanItem) {
        promotedId = item.exerciseId
        queue = TodayQueue(items: day.items, statuses: statuses, promoted: promotedId)
    }

    func skip(_ item: PlanItem) {
        perform { try $0.skip(try $0.log(for: item.exerciseId, in: try self.startSession())) }
    }

    func reopen(_ item: PlanItem) {
        guard let log = log(for: item) else { return }
        perform { try $0.reopen(log) }
    }

    /// Ticks off a checklist item.
    func complete(_ item: PlanItem) {
        perform { try $0.complete(try $0.log(for: item.exerciseId, in: try self.startSession())) }
    }

    private func perform(_ change: (WorkoutRecorder) throws -> Void) {
        do {
            try change(recorder)
        } catch {
            Logger.store.error("Couldn't save: \(error.localizedDescription)")
        }
        refresh()
    }
}

extension TodayModel {
    /// The second line of an item's row: "4 × 6–10 · 22.5 kg", "Set 3 of 5 · in progress", "4 sets · 25 kg".
    func detailLine(for item: PlanItem) -> String {
        let target = target(for: item)
        switch status(of: item) {
        case .skipped:
            return "Skipped"
        case .done:
            let sets = log(for: item)?.orderedSets ?? []
            guard !sets.isEmpty else { return "Done" }
            let top = sets.map(\.weight).max() ?? 0
            return item.takesWeight && top > 0 ? "\(sets.count) sets · \(Format.kg(top))" : "\(sets.count) sets"
        case .inProgress(let done):
            return "Set \(done + 1) of \(target.sets) · in progress"
        case .pending:
            var parts = [Format.prescription(item, target)]
            if item.takesWeight, let weight = target.weight, weight > 0 { parts.append(Format.kg(weight)) }
            return parts.joined(separator: " · ")
        }
    }
}

extension Logger {
    static let store = Logger(subsystem: "com.yeshu.RepCoach", category: "store")
    static let sync = Logger(subsystem: "com.yeshu.RepCoach", category: "sync")
}
