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
    /// The plan day with the user's edits and overrides applied.
    private(set) var day: PlanDay
    /// The whole plan as the user has it: their edits to the days, and each exercise's overrides.
    private(set) var editedPlan: Plan
    /// Exercises added, removed or moved, and the user's own exercises.
    private(set) var planEdits = PlanEdits()
    /// Per exercise, by exerciseId.
    private(set) var overrides: [String: ExerciseOverrides] = [:]
    private(set) var session: WorkoutSession?
    private(set) var queue: TodayQueue
    private(set) var targets: [String: ItemTarget] = [:]
    private(set) var statuses: [String: ItemStatus] = [:]
    private(set) var isDeload = false
    private(set) var promotedId: String?
    /// Exercises put off for later with Skip, in the order they were put off (watch). They stay open; they come
    /// back after the last other exercise. Kept for the day, so they survive leaving the workout and a relaunch.
    private(set) var waiting: [String] = []
    /// Where the day's small state (waiting, ramp-ups skipped) is kept. The demo uses a throwaway suite.
    @ObservationIgnored var defaults: UserDefaults = .standard
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
        self.editedPlan = plan
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

    /// Every exercise there is, overrides applied: the plan's and the user's own, on a day or not.
    var library: [PlanItem] {
        planEdits.library(plan: plan).map { $0.applying(overrides[$0.exerciseId]) }
    }

    /// An exercise as the plan (or the user, for their own) defined it, before overrides.
    func baseItem(_ exerciseId: String) -> PlanItem? {
        plan.days.lazy.flatMap(\.items).first { $0.exerciseId == exerciseId } ?? planEdits.custom[exerciseId]
    }

    /// Changes the plan's days, stores the change and shows it.
    func editPlan(_ change: (inout PlanEdits) -> Void) {
        var edits = planEdits
        change(&edits)
        guard edits != planEdits else { return }
        do {
            try edits.save(to: context)
        } catch {
            Logger.store.error("Couldn't save the plan: \(error.localizedDescription)")
        }
        refresh()
    }

    /// How hard the last workout that was rated felt, 1 to 10.
    func lastEffort() -> Int? {
        var descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.effort != nil },
                                                         sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first?.effort
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

    /// Reads today's session and works out targets and order again. Only values that changed are assigned, so
    /// screens redraw only when something they show did.
    func refresh() {
        let recorder = recorder
        let session = try? recorder.session(for: dayKey, on: .now)
        if session !== self.session { self.session = session }
        update(\.isDeload, session?.isDeload ?? settings.isDeload(on: .now, plan: plan, calendar: calendar))

        let overrides = Dictionary(
            ((try? context.fetch(FetchDescriptor<ExerciseSettings>())) ?? []).map { ($0.exerciseId, $0.overrides) },
            uniquingKeysWith: { first, _ in first })
        update(\.overrides, overrides)
        update(\.planEdits, PlanEdits.load(from: context))
        var edited = planEdits.applied(to: plan)
        for index in edited.days.indices {
            edited.days[index].items = edited.days[index].items.map { $0.applying(overrides[$0.exerciseId]) }
        }
        update(\.editedPlan, edited)
        guard let day = edited.days.first(where: { $0.key == dayKey }) else { return }
        update(\.day, day)
        update(\.statuses, session?.statuses ?? [:])
        let open = Set(day.items.filter { !(statuses[$0.exerciseId]?.isFinished ?? false) }.map(\.exerciseId))
        update(\.waiting, (defaults.stringArray(forKey: stateKey("waiting")) ?? []).filter(open.contains))

        var targets: [String: ItemTarget] = [:]
        for item in day.items {
            var amrap: Int?
            if item.kind == .percentOfMax, let source = item.sourceExerciseId {
                let today = session?.log(for: source)?.countedLoggedSets
                amrap = TargetPlanner.amrapReps(today: today, history: pastSessions(of: source))
            }
            targets[item.exerciseId] = TargetPlanner.target(
                for: item, history: pastSessions(of: item.exerciseId), deload: isDeload,
                startWeight: overrides[item.exerciseId]?.startWeight, amrap: amrap)
        }
        update(\.targets, targets)

        if let promotedId, statuses[promotedId]?.isFinished == true { self.promotedId = nil }
        update(\.queue, TodayQueue(items: day.items, statuses: statuses, promoted: promotedId, waiting: waiting))
    }

    private func update<Value: Equatable>(_ keyPath: ReferenceWritableKeyPath<TodayModel, Value>, _ value: Value) {
        if self[keyPath: keyPath] != value { self[keyPath: keyPath] = value }
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
        stopWaiting([item])
        update(\.queue, TodayQueue(items: day.items, statuses: statuses, promoted: promotedId, waiting: waiting))
    }

    // MARK: Waiting (watch)

    func isWaiting(_ item: PlanItem) -> Bool { waiting.contains(item.exerciseId) }

    /// Skip puts `items` off: they stay open and come back after the last other exercise.
    func putOff(_ items: [PlanItem]) {
        let ids = items.map(\.exerciseId)
        store(waiting.filter { !ids.contains($0) } + ids)
    }

    /// `items` are being done now (or are done): no longer waiting.
    func stopWaiting(_ items: [PlanItem]) {
        let ids = Set(items.map(\.exerciseId))
        guard waiting.contains(where: ids.contains) else { return }
        store(waiting.filter { !ids.contains($0) })
    }

    func clearWaiting() {
        defaults.removeObject(forKey: stateKey("waiting"))
        refresh()
    }

    /// Ramp-ups dropped for today with Skip on the ramp-up screen.
    func rampUpsSkipped(_ item: PlanItem) -> Bool {
        (defaults.stringArray(forKey: stateKey("rampSkipped")) ?? []).contains(item.exerciseId)
    }

    func skipRampUps(_ items: [PlanItem]) {
        let key = stateKey("rampSkipped")
        let list = (defaults.stringArray(forKey: key) ?? []) + items.map(\.exerciseId)
        defaults.set(Array(Set(list)), forKey: key)
    }

    private func store(_ list: [String]) {
        defaults.set(list, forKey: stateKey("waiting"))
        refresh()
    }

    /// What Skip leads to for `items` on screen: the next one in the queue with them put off, or, when nothing
    /// else is ready, the first other open item (a tick-off item) so Skip always goes somewhere else.
    func skipDestination(puttingOff items: [PlanItem]) -> [PlanItem] {
        let ids = Set(items.map(\.exerciseId))
        let list = waiting.filter { !ids.contains($0) } + items.map(\.exerciseId)
        let promoted = promotedId.flatMap { ids.contains($0) ? nil : $0 }
        let queue = TodayQueue(items: day.items, statuses: statuses, promoted: promoted, waiting: list)
        if Set(queue.upNext.map(\.exerciseId)) != ids { return queue.upNext }
        guard let other = day.items.first(where: { !status(of: $0).isFinished && !ids.contains($0.exerciseId) })
        else { return [] }
        guard let group = other.supersetGroup else { return [other] }
        return day.items.filter { $0.supersetGroup == group && !status(of: $0).isFinished }
    }

    /// The key for one piece of the day's small state: per plan day and calendar date.
    private func stateKey(_ name: String) -> String {
        let date = calendar.dateComponents([.year, .month, .day], from: .now)
        return "\(name).\(dayKey).\(date.year ?? 0)-\(date.month ?? 0)-\(date.day ?? 0)"
    }

    func skip(_ item: PlanItem) {
        perform { try $0.skip(try $0.log(for: item.exerciseId, in: try self.startSession())) }
    }

    func reopen(_ item: PlanItem) {
        guard let log = log(for: item) else { return }
        perform { try $0.reopen(log) }
    }

    /// Ticks off a checklist item, or finishes an exercise with the sets logged so far.
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
            let sets = log(for: item)?.orderedCountedSets ?? []
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
