#if DEBUG
import Foundation
import SwiftData

/// Weeks of plausible training for the simulator, previews and screenshots. Debug builds only; never touches
/// the on-disk store because the apps only seed an in-memory container.
public enum DemoData {
    /// Fills `context` with a session of every plan day for each of the past `weeks`, with weights chosen by
    /// `ProgressionEngine` and reps that creep up until the weight goes up.
    /// - Parameter dayKey: also start today's session for this plan day: the leading checklist items done
    ///   (up to two) and two sets of its first weighted exercise logged.
    public static func seed(_ context: ModelContext, plan: Plan, weeks: Int = 8, today: Date = .now,
                            calendar: Calendar = .current, inProgress dayKey: String? = nil) throws {
        var history: [String: [[LoggedSet]]] = [:]
        var form: [String: Int] = [:]

        for (date, day) in pastSessions(plan: plan, weeks: weeks, before: today, calendar: calendar) {
            let session = WorkoutSession(date: date, dayKey: day.key)
            context.insert(session)
            var minutes = 0.0
            var amrapToday: Int?
            for (order, item) in day.items.enumerated() {
                let sets = simulate(item, history: history[item.exerciseId] ?? [], form: &form, amrapToday: amrapToday)
                if item.kind == .amrap { amrapToday = sets.first?.reps }
                minutes += Double(max(4, sets.count * 3))
                add(item, sets: sets, order: order, to: session, at: date.addingTimeInterval(minutes * 60),
                    completed: true, context: context)
                if !sets.isEmpty { history[item.exerciseId, default: []].insert(sets, at: 0) }
            }
            session.endedAt = date.addingTimeInterval((minutes + 5) * 60)
        }

        if let dayKey, let day = plan.days.first(where: { $0.key == dayKey }) {
            let start = max(calendar.startOfDay(for: today), today.addingTimeInterval(-35 * 60))
            let session = WorkoutSession(date: start, dayKey: day.key)
            context.insert(session)
            var order = 0
            for item in day.items.prefix(while: { $0.kind == .checklist }).prefix(2) {
                add(item, sets: [], order: order, to: session, at: start.addingTimeInterval(Double(order + 1) * 600),
                    completed: true, context: context)
                order += 1
            }
            if let item = day.items.first(where: { $0.kind == .weighted }), let p = Prescription(item: item) {
                let target = ProgressionEngine.firstTarget(for: p, history: history[item.exerciseId] ?? [])
                let weight = target.weight ?? startWeights[item.exerciseId] ?? 10
                let sets = (1...min(2, p.sets)).map { LoggedSet(weight: weight, reps: max(p.repMin, p.repMax - $0 + 1)) }
                add(item, sets: sets, order: order, to: session, at: today, completed: false, context: context)
            }
        }
        try context.save()
    }

    /// Dates of each plan day's session over the past `weeks`, oldest first, at 06:30.
    static func pastSessions(plan: Plan, weeks: Int, before today: Date, calendar: Calendar) -> [(Date, PlanDay)] {
        let startOfToday = calendar.startOfDay(for: today)
        var sessions: [(Date, PlanDay)] = []
        for day in plan.days {
            guard let latest = calendar.nextDate(after: startOfToday,
                                                 matching: DateComponents(hour: 6, minute: 30, weekday: day.weekday),
                                                 matchingPolicy: .nextTime, direction: .backward) else { continue }
            for week in 0..<weeks {
                if let date = calendar.date(byAdding: .day, value: -7 * week, to: latest) {
                    sessions.append((date, day))
                }
            }
        }
        return sessions.sorted { $0.0 < $1.0 }
    }

    static func simulate(_ item: PlanItem, history: [[LoggedSet]], form: inout [String: Int],
                         amrapToday: Int?) -> [LoggedSet] {
        let id = item.exerciseId
        let sets = max(1, item.sets ?? 1)
        let level = form[id, default: 0]
        form[id] = level + 1
        switch item.kind {
        case .checklist:
            return []
        case .weighted:
            guard let p = Prescription(item: item) else { return [] }
            let target = ProgressionEngine.firstTarget(for: p, history: history)
            // A new weight starts low in the range; wide ranges climb two reps a session.
            let climb = p.repMax - p.repMin >= 4 ? 2 : 1
            let atWeight = target.reason == .repeatWeight ? level : 0
            form[id] = atWeight + climb
            let weight = target.weight ?? startWeights[id] ?? 10
            return (1...p.sets).map { LoggedSet(weight: weight, reps: reps(atWeight, set: $0, p.repMin, p.repMax)) }
        case .reps:
            let weight = item.loadable == true ? startWeights[id] ?? 10 : 0
            return (1...sets).map {
                LoggedSet(weight: weight, reps: reps(level, set: $0, item.repMin ?? 8, item.repMax ?? 12))
            }
        case .timed:
            let weight = item.loadable == true ? startWeights[id] ?? 10 : 0
            let low = item.secMin ?? 20, high = item.secMax ?? low
            let hold = min(high + 5, low + level * 3)
            return (1...sets).map { LoggedSet(weight: weight, reps: max(low - 5, hold - ($0 - 1) * 2)) }
        case .amrap:
            return [LoggedSet(weight: 0, reps: 9 + level / 2)]
        case .percentOfMax:
            guard let amrap = amrapToday ?? TargetPlanner.amrapReps(today: nil, history: history) else { return [] }
            let reps = ProgressionEngine.volumeReps(amrap: amrap, percent: item.percent ?? 0.6)
            return Array(repeating: LoggedSet(weight: 0, reps: reps), count: sets)
        }
    }

    /// Reps for a 1-based set at a level of form: a rep fewer every second set, never outside the range.
    static func reps(_ level: Int, set: Int, _ low: Int, _ high: Int) -> Int {
        min(high, max(low, low + level + 1 - (set - 1) / 2))
    }

    static func add(_ item: PlanItem, sets: [LoggedSet], order: Int, to session: WorkoutSession, at date: Date,
                    completed: Bool, context: ModelContext) {
        let log = ExerciseLog(exerciseId: item.exerciseId, order: order)
        context.insert(log)
        log.session = session
        log.completedAt = completed ? date : nil
        for (offset, set) in sets.enumerated() {
            let timed = item.kind == .timed
            let row = SetLog(index: offset + 1, weight: set.weight, reps: timed ? 0 : set.reps,
                             seconds: timed ? set.reps : nil, timestamp: date)
            context.insert(row)
            row.log = log
        }
    }

    static let startWeights: [String: Double] = [
        "weighted-pull-ups": 7.5, "chest-supported-db-row": 20, "close-grip-lat-pulldown": 45, "face-pulls": 17.5,
        "incline-db-curl": 10, "hammer-curl": 12.5,
        "leg-press": 110, "bulgarian-split-squat-dbs": 12.5, "hip-thrust": 60, "lying-hamstring-curl": 30,
        "leg-extension": 40, "standing-calf-raise": 50,
        "incline-db-press": 20, "machine-chest-press-or-flat-bench": 45, "seated-db-shoulder-press": 15,
        "cable-lateral-raise": 5, "overhead-cable-extension": 17.5, "rope-pushdown": 22.5,
        "cable-crunch": 30, "russian-twist-weighted": 5,
        "single-arm-cable-row": 20, "straight-arm-pulldown": 20, "reverse-pec-deck": 30, "preacher-curl": 17.5,
        "cable-curl-drop-set": 17.5,
        "db-bench-press": 22.5, "low-to-high-cable-fly": 10, "machine-shoulder-press": 35, "db-lateral-raise": 7,
        "ez-bar-skull-crusher": 20, "bayesian-cable-curl": 10, "cable-overhead-extension": 17.5,
        "pallof-press": 12.5, "suitcase-carry": 20, "weighted-plank": 10,
    ]
}
#endif
