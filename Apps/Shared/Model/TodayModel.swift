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
    /// The day's session was finished (Finish workout). Today then shows Finished, with what is left, until Start
    /// again reopens it.
    private(set) var isFinished = false
    /// The plan's exercise each swapped-in exercise of today stands in for: swapped-in id → slot id.
    private(set) var slotOf: [String: String] = [:]
    /// Called after a swap made here, with every mark, so the other device gets it.
    @ObservationIgnored var onSwapsChanged: ((SwapMarks) -> Void)?
    /// Called at the end of every `refresh()`: the watch tells its complication where the day stands.
    @ObservationIgnored var onRefresh: (() -> Void)?
    /// Exercises put off for later with Skip, in the order they were put off (watch). They stay open; they come
    /// back after the last other exercise. Kept for the day, so they survive leaving the workout and a relaunch.
    private(set) var waiting: [String] = []
    /// Where the day's small state (waiting, ramp-ups skipped) is kept. The demo uses a throwaway suite.
    @ObservationIgnored var defaults: UserDefaults = .standard {
        didSet { swapMarks = SwapMarks.load(from: defaults) }
    }
    /// Today's swaps and the last few days', as both devices keep them.
    @ObservationIgnored private(set) var swapMarks = SwapMarks.load(from: .standard)
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
        let stamp = SwapMarks.stamp(.now, calendar: calendar)
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
        guard let planned = edited.days.first(where: { $0.key == dayKey }) else { return }
        // Today's swaps stand in the plan's slots; everything below then works on the swapped-in exercises.
        let swapped = ExerciseDatabase.shared?.applying(swapMarks.swaps(dayKey: dayKey, date: stamp), to: planned)
            ?? SwappedDay(day: planned)
        var day = swapped.day
        // A swapped-in exercise has the user's own settings for it, if any (an increment, a name).
        day.items = day.items.map { $0.applying(overrides[$0.exerciseId]) }
        update(\.slotOf, swapped.slotOf)
        update(\.day, day)
        update(\.isFinished, session?.endedAt != nil)
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
        onRefresh?()
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

    // MARK: Logging

    /// The log of `item` in today's session, made on first use. A swapped-in exercise's log says which slot it
    /// stands in for.
    func writableLog(for item: PlanItem) throws -> ExerciseLog {
        try recorder.log(for: item.exerciseId, slot: slotOf[item.exerciseId], in: startSession())
    }

    // MARK: Swap (for today only)

    /// The plan's own exercise in the slot `item` stands in for (`item` itself when it isn't swapped).
    func slot(of item: PlanItem) -> PlanItem {
        let id = slotOf[item.exerciseId] ?? item.exerciseId
        let planned = editedPlan.days.first { $0.key == dayKey }?.items.first { $0.exerciseId == id }
        return planned.map { $0.applying(overrides[$0.exerciseId]) } ?? item
    }

    func isSwapped(_ item: PlanItem) -> Bool { slotOf[item.exerciseId] != nil }

    /// Swap is offered for an open exercise nothing has been logged on yet (ramp-ups don't count) that the
    /// database has alternatives for.
    func canSwap(_ item: PlanItem) -> Bool {
        guard let database = ExerciseDatabase.shared, !status(of: item).isFinished,
              (log(for: item)?.countedSets.isEmpty ?? true) else { return false }
        return database.canSwap(slot(of: item))
    }

    /// The Swap sheet's rows for `item`.
    func swapChoices(for item: PlanItem) -> [SwapChoice] {
        let slot = slot(of: item)
        let taken = Set(day.items.map(\.exerciseId)).subtracting([item.exerciseId, slot.exerciseId])
        return ExerciseDatabase.shared?.choices(for: item, slot: slot, injuryAreas: settings.injuryAreas,
                                                excluding: taken) ?? []
    }

    /// Today's item for the slot `item` stands in for now takes the chosen exercise (or the plan's own, taking
    /// the swap back). Whatever ramp-up sets the old exercise logged go with it.
    func swap(_ item: PlanItem, to choice: SwapChoice) {
        let slotId = slot(of: item).exerciseId
        if let log = log(for: item), log.countedSets.isEmpty { perform { try $0.delete(log) } }
        if promotedId == item.exerciseId { promotedId = choice.id }
        record(SwapMark(dayKey: dayKey, date: SwapMarks.stamp(.now, calendar: calendar), slot: slotId,
                        exercise: choice.id))
    }

    /// Takes back all of today's swaps (Discard workout).
    func clearSwaps() {
        var marks = swapMarks
        marks.clear(dayKey: dayKey, date: SwapMarks.stamp(.now, calendar: calendar))
        store(marks, notify: true)
    }

    /// The other device's marks. Returns whether anything here changed (the screen on show may need to move to
    /// the swapped-in exercise).
    @discardableResult
    func applySwaps(from other: SwapMarks) -> Bool {
        var marks = swapMarks
        guard marks.merge(other) else { return false }
        store(marks, notify: false)
        return true
    }

    private func record(_ mark: SwapMark) {
        var marks = swapMarks
        marks.record(mark)
        store(marks, notify: true)
    }

    private func store(_ marks: SwapMarks, notify: Bool) {
        var marks = marks
        marks.prune(before: SwapMarks.stamp(calendar.date(byAdding: .day, value: -3, to: .now) ?? .now,
                                            calendar: calendar))
        swapMarks = marks
        marks.save(to: defaults)
        refresh()
        if notify { onSwapsChanged?(marks) }
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
        perform { try $0.skip(try self.writableLog(for: item)) }
    }

    func reopen(_ item: PlanItem) {
        guard let log = log(for: item) else { return }
        perform { try $0.reopen(log) }
    }

    /// Ticks off a checklist item, or finishes an exercise with the sets logged so far.
    func complete(_ item: PlanItem) {
        perform { try $0.complete(try self.writableLog(for: item)) }
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
