import Foundation

/// One logged set. For timed items `reps` holds seconds.
public struct LoggedSet: Codable, Hashable, Sendable {
    public var weight: Double
    public var reps: Int

    public init(weight: Double, reps: Int) {
        self.weight = weight
        self.reps = reps
    }
}

/// The numbers the engine needs for a weighted exercise.
public struct Prescription: Hashable, Sendable {
    public var sets: Int
    public var repMin: Int
    public var repMax: Int
    public var increment: Double
    public var sessionsAtTopToProgress: Int

    public init(sets: Int, repMin: Int, repMax: Int, increment: Double, sessionsAtTopToProgress: Int = 1) {
        self.sets = sets
        self.repMin = repMin
        self.repMax = repMax
        self.increment = increment
        self.sessionsAtTopToProgress = sessionsAtTopToProgress
    }

    /// nil for items that are not weighted.
    public init?(item: PlanItem) {
        guard item.kind == .weighted,
              let sets = item.sets, let lo = item.repMin, let hi = item.repMax else { return nil }
        self.init(sets: sets, repMin: lo, repMax: hi,
                  increment: item.increment ?? 2.5,
                  sessionsAtTopToProgress: item.sessionsAtTopToProgress ?? 1)
    }
}

public enum SessionTargetReason: String, Codable, Sendable {
    /// No history: the user enters a starting weight.
    case firstTime
    /// Hit the top of the rep range on every set (for the required number of sessions).
    case increase
    /// Same weight; aim to add reps.
    case repeatWeight
    /// Missed the bottom of the range in the last two sessions at this weight.
    case decrease
    /// Deload week: fewer sets, lighter weight.
    case deload
}

public struct SessionTarget: Equatable, Sendable {
    public var weight: Double?
    public var sets: Int
    public var reason: SessionTargetReason
}

public enum NextSetReason: String, Codable, Sendable {
    case keep
    /// Reps fell below the range: lighter next set.
    case dropWeight
    /// Reps were 3+ above the range: heavier next set.
    case raiseWeight
}

public struct NextSetTarget: Equatable, Sendable {
    public var weight: Double
    public var reason: NextSetReason
}

/// Pure functions. Behaviour is pinned by ProgressionEngineTests, whose expected values come from
/// the Python reference implementation in docs/engine_reference.py. Change both together.
public enum ProgressionEngine {

    // MARK: Rounding

    /// Nearest multiple of `increment`, halves rounded up.
    public static func roundNearest(_ x: Double, to increment: Double) -> Double {
        twoDecimals((x / increment).rounded() * increment)
    }

    /// Largest multiple of `increment` that is ≤ x.
    public static func roundDown(_ x: Double, to increment: Double) -> Double {
        twoDecimals((x / increment + 1e-9).rounded(.down) * increment)
    }

    static func twoDecimals(_ x: Double) -> Double {
        (x * 100).rounded() / 100
    }

    // MARK: Session start (double progression)

    /// Target for the first working set of today's session.
    /// - Parameter history: previous non-deload sessions for this exercise, newest first.
    ///   Each session is its sets in the order performed.
    public static func firstTarget(for p: Prescription, history: [[LoggedSet]], deload: Bool = false) -> SessionTarget {
        let sets = deload ? Int((Double(p.sets) / 2).rounded(.up)) : p.sets
        guard let last = history.first, let work = last.first?.weight else {
            return SessionTarget(weight: nil, sets: sets, reason: .firstTime)
        }

        var consecutiveTop = 0
        for session in history {
            if session.first?.weight == work && isAtTop(session, weight: work, p: p) {
                consecutiveTop += 1
            } else {
                break
            }
        }

        var weight: Double
        var reason: SessionTargetReason
        if consecutiveTop >= p.sessionsAtTopToProgress {
            weight = work + p.increment
            reason = .increase
        } else if history.count >= 2,
                  history[1].first?.weight == work,
                  missed(history[0], p: p), missed(history[1], p: p) {
            var reduced = roundDown(work * 0.9, to: p.increment)
            if reduced > work - p.increment { reduced = work - p.increment }
            weight = max(reduced, 0)
            reason = .decrease
        } else {
            weight = work
            reason = .repeatWeight
        }

        if deload {
            weight = roundNearest(weight * 0.85, to: p.increment)
            reason = .deload
        }
        return SessionTarget(weight: twoDecimals(weight), sets: sets, reason: reason)
    }

    /// Every prescribed set at or above `weight` and at or above the top of the rep range.
    static func isAtTop(_ session: [LoggedSet], weight: Double, p: Prescription) -> Bool {
        let working = Array(session.prefix(p.sets))
        guard working.count >= p.sets else { return false }
        return working.allSatisfy { $0.weight >= weight && $0.reps >= p.repMax }
    }

    /// Too few sets, any set under the range, or the weight had to be dropped mid-session.
    static func missed(_ session: [LoggedSet], p: Prescription) -> Bool {
        let working = Array(session.prefix(p.sets))
        guard let first = working.first?.weight, working.count >= p.sets else { return true }
        return working.contains { $0.reps < p.repMin || $0.weight < first }
    }

    // MARK: Within a session

    /// Weight for the next set after logging `reps` at `weight`.
    /// - Parameters:
    ///   - setIndex: 1-based index of the set just logged.
    ///   - totalSets: sets planned today.
    public static func nextSet(for p: Prescription, weight: Double, reps: Int, setIndex: Int, totalSets: Int) -> NextSetTarget {
        if reps < p.repMin {
            let deficit = p.repMin - reps
            let pct = min(0.20, 0.05 * Double(deficit))
            var next = roundDown(weight * (1 - pct), to: p.increment)
            if next > weight - p.increment { next = weight - p.increment }
            return NextSetTarget(weight: max(twoDecimals(next), 0), reason: .dropWeight)
        }
        if reps >= p.repMax + 3 && setIndex < totalSets {
            return NextSetTarget(weight: twoDecimals(weight + p.increment), reason: .raiseWeight)
        }
        return NextSetTarget(weight: weight, reason: .keep)
    }

    // MARK: Pull-up endurance

    /// Reps per volume set from today's max-rep set (Thursday).
    public static func volumeReps(amrap: Int, percent: Double = 0.6) -> Int {
        max(1, Int((Double(amrap) * percent).rounded()))
    }

    // MARK: reps and timed kinds

    /// Every planned set reached the top of the range (seconds for timed sets). These kinds get no automatic
    /// weight change; the app says "Top of range. Add weight or make it harder next time."
    public static func reachedTopOfRange(_ sets: [LoggedSet], top: Int, plannedSets: Int) -> Bool {
        let done = sets.prefix(plannedSets)
        return done.count >= plannedSets && done.allSatisfy { $0.reps >= top }
    }

    // MARK: Charts

    /// Epley estimated one-rep max, for progress charts only.
    public static func estimated1RM(weight: Double, reps: Int) -> Double {
        twoDecimals(weight * (1 + Double(reps) / 30))
    }
}
