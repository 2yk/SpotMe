import Foundation

/// What today asks of one plan item.
public struct ItemTarget: Equatable, Sendable {
    public var sets: Int
    /// Weighted items: the engine's target for the session.
    public var session: SessionTarget?
    /// Weight for the first set: the engine's target, else the start weight, else (loadable items) the last
    /// weight used. nil when there's nothing to go on yet.
    public var weight: Double?
    /// Reps per set. Volume sets carry the computed reps at both ends.
    public var repMin: Int?
    public var repMax: Int?
    public var secMin: Int?
    public var secMax: Int?
    /// Volume sets: the max-rep set they're based on.
    public var amrap: Int?

    public init(sets: Int, session: SessionTarget? = nil, weight: Double? = nil, repMin: Int? = nil,
                repMax: Int? = nil, secMin: Int? = nil, secMax: Int? = nil, amrap: Int? = nil) {
        self.sets = sets
        self.session = session
        self.weight = weight
        self.repMin = repMin
        self.repMax = repMax
        self.secMin = secMin
        self.secMax = secMax
        self.amrap = amrap
    }
}

/// Turns a plan item plus its history into today's target. The numbers all come from `ProgressionEngine`.
public enum TargetPlanner {
    /// - Parameters:
    ///   - item: with the user's overrides already applied.
    ///   - history: previous non-deload sessions of the item, newest first (`HistoryStore.history`).
    ///   - startWeight: the user's start weight, for a weighted item with no history.
    ///   - amrap: volume sets only; see `amrapReps(today:history:)`.
    public static func target(for item: PlanItem, history: [[LoggedSet]], deload: Bool,
                              startWeight: Double? = nil, amrap: Int? = nil) -> ItemTarget {
        let sets = item.sets ?? 1
        let lastWeight = history.first?.first?.weight
        switch item.kind {
        case .checklist:
            return ItemTarget(sets: 0)
        case .weighted:
            guard let prescription = Prescription(item: item) else { return ItemTarget(sets: sets) }
            let session = ProgressionEngine.firstTarget(for: prescription, history: history, deload: deload)
            return ItemTarget(sets: session.sets, session: session, weight: session.weight ?? startWeight,
                              repMin: prescription.repMin, repMax: prescription.repMax)
        case .reps:
            return ItemTarget(sets: sets, weight: item.loadable == true ? lastWeight ?? startWeight : nil,
                              repMin: item.repMin, repMax: item.repMax)
        case .timed:
            return ItemTarget(sets: sets, weight: item.loadable == true ? lastWeight ?? startWeight : nil,
                              secMin: item.secMin, secMax: item.secMax)
        case .amrap:
            return ItemTarget(sets: sets)
        case .percentOfMax:
            guard let amrap else { return ItemTarget(sets: sets) }
            let reps = ProgressionEngine.volumeReps(amrap: amrap, percent: item.percent ?? 0.6)
            return ItemTarget(sets: sets, repMin: reps, repMax: reps, amrap: amrap)
        }
    }

    /// The max-rep set that volume sets are based on: today's if it's logged, else the most recent one.
    public static func amrapReps(today: [LoggedSet]?, history: [[LoggedSet]]) -> Int? {
        today?.first?.reps ?? history.first?.first?.reps
    }
}
