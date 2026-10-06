import Foundation

/// Which exercises get lighter sets before their first working set. Edited on the iPhone, sent to the watch.
public enum RampUpSetting: String, Codable, CaseIterable, Hashable, Sendable {
    case off
    /// Weighted exercises with 2:00 or more of rest.
    case mainLifts
    /// Every weighted exercise.
    case everyWeightedLift
}

/// How much of a ramp-up an exercise gets, from its place in the day.
public enum RampUpRole: String, Codable, Hashable, Sendable {
    /// The day's first main lift.
    case first
    /// Any other main lift.
    case main
    /// A smaller weighted lift (rest under 2:00).
    case small
}

/// Pure functions, pinned by ProgressionEngineTests against the "ramp-up" lines printed by docs/engine_reference.py.
/// Ramp-up sets are never counted: not in history, progression, charts or set counts.
extension ProgressionEngine {

    /// Rest after a ramp-up set, in seconds.
    public static let restAfterRampUpSec = 60

    /// A main lift is weighted with 120 s of rest or more. nil for anything that isn't weighted.
    /// - Parameters:
    ///   - dayItems: the day's items in the plan's order, not the order they are done in.
    ///   - index: the item to look at.
    public static func rampUpRole(dayItems: [PlanItem], index: Int) -> RampUpRole? {
        func isMain(_ item: PlanItem) -> Bool { item.kind == .weighted && (item.restSec ?? 0) >= 120 }
        let item = dayItems[index]
        guard item.kind == .weighted else { return nil }
        guard isMain(item) else { return .small }
        return dayItems[..<index].contains(where: isMain) ? .main : .first
    }

    /// The ramp-up sets before the first working set, lightest first. Empty when the setting or the role says
    /// none, there is no working weight yet, or a set would round to nothing.
    /// - Parameters:
    ///   - working: today's weight for set 1: the first target, or the deload weight in a deload week. nil
    ///     without history.
    ///   - repMax: the top of the rep range; ramp-up reps never go above it.
    ///   - bodyweightBase: the logged weight is added to bodyweight (weighted pull-ups), so a weight of 0 means
    ///     bodyweight only.
    public static func rampUps(working: Double?, increment: Double, repMax: Int, role: RampUpRole?,
                               setting: RampUpSetting = .mainLifts,
                               bodyweightBase: Bool = false) -> [(weight: Double, reps: Int)] {
        guard let role, setting != .off, let working else { return [] }
        if role == .small && setting != .everyWeightedLift { return [] }

        var sets: [(weight: Double, reps: Int)] = []
        if bodyweightBase {
            guard working > 0 else { return [] }
            sets.append((weight: 0, reps: min(5, repMax)))
            if role == .first {
                let half = roundDown(working * 0.5, to: increment)
                if half > 0 && half < working { sets.append((weight: half, reps: min(3, repMax))) }
            }
            return sets
        }

        let table: [(factor: Double, reps: Int)] = role == .first ? [(0.50, 8), (0.75, 4)] : [(0.70, 5)]
        for (factor, reps) in table {
            let weight = roundDown(working * factor, to: increment)
            if weight <= 0 || weight >= working { continue }
            if let lighter = sets.last, weight <= lighter.weight { continue }
            sets.append((weight: weight, reps: min(reps, repMax)))
        }
        return sets
    }
}
