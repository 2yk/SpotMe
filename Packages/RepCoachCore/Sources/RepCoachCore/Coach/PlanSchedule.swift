import Foundation

/// Rearranging the days: which workout stands on which weekday. Weekday names never move; a workout keeps its
/// `key` (history, swaps and its exercise list are keyed on it) and takes the `weekday` and `title` of the
/// weekday it now stands on. `Plan.days` stays in the plan's order, Monday to Sunday, so everything that looks a
/// day up by weekday (today's workout, the day strip, the watch's day picker) follows the schedule without
/// knowing about it.
extension PlanEdits {
    /// The workout key on each weekday of `plan`, with the schedule applied: weekday → key. Where the schedule
    /// isn't a rearrangement of the plan's own workouts, the plan's own.
    func assignment(in plan: Plan) -> [Int: String] {
        let own = Dictionary(plan.days.map { ($0.weekday, $0.key) }, uniquingKeysWith: { first, _ in first })
        guard !schedule.isEmpty else { return own }
        var wanted = own
        for (weekday, key) in schedule where own[weekday] != nil { wanted[weekday] = key }
        return Set(wanted.values) == Set(own.values) ? wanted : own
    }

    /// Whether any workout is on a weekday other than the plan's.
    public func isRearranged(_ plan: Plan) -> Bool {
        let own = Dictionary(plan.days.map { ($0.weekday, $0.key) }, uniquingKeysWith: { first, _ in first })
        return assignment(in: plan) != own
    }

    /// The workout keys in the order of `plan.days` (Monday to Sunday): the workout on each weekday.
    public func workoutKeys(in plan: Plan) -> [String] {
        let assigned = assignment(in: plan)
        return plan.days.map { assigned[$0.weekday] ?? $0.key }
    }

    /// `plan` with each workout on the weekday the schedule gives it. Days stay in the plan's order, so the
    /// first is still Monday: the workout on Monday is the first day, with Monday's weekday and title.
    /// Applying it again, to a plan it has already scheduled, changes nothing.
    public func scheduled(_ plan: Plan) -> Plan {
        guard isRearranged(plan) else { return plan }
        let assigned = assignment(in: plan)
        let byKey = Dictionary(plan.days.map { ($0.key, $0) }, uniquingKeysWith: { first, _ in first })
        var result = plan
        for index in result.days.indices {
            let slot = plan.days[index]
            guard let key = assigned[slot.weekday], var day = byKey[key] else { continue }
            day.weekday = slot.weekday
            day.title = slot.title
            result.days[index] = day
        }
        return result
    }

    /// Puts `keys` on the weekdays of `plan`, in its order (Monday to Sunday): `keys[0]` is the workout on the
    /// first day. `plan` is the plan as shipped. Anything but each of the plan's workouts once is ignored.
    /// The plan's own arrangement clears the schedule.
    public mutating func arrange(_ keys: [String], on plan: Plan) {
        guard keys.count == plan.days.count, Set(keys) == Set(plan.days.map(\.key)) else { return }
        var next: [Int: String] = [:]
        for (slot, key) in zip(plan.days, keys) where key != slot.key {
            next[slot.weekday] = key
        }
        schedule = next
    }

    /// Swaps the workouts on two weekdays (rest days are workouts too). `plan` is the plan as shipped.
    public mutating func swapWorkouts(on weekday: Int, and other: Int, plan: Plan) {
        var keys = workoutKeys(in: plan)
        guard let first = plan.days.firstIndex(where: { $0.weekday == weekday }),
              let second = plan.days.firstIndex(where: { $0.weekday == other }) else { return }
        keys.swapAt(first, second)
        arrange(keys, on: plan)
    }

    /// Every workout back on the plan's own weekday.
    public mutating func resetSchedule() {
        schedule = [:]
    }
}
