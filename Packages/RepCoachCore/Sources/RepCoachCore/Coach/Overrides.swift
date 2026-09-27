import Foundation

/// The user's changes to one exercise. nil means "as in plan.json".
public struct ExerciseOverrides: Codable, Hashable, Sendable {
    public var increment: Double?
    public var repMin: Int?
    public var repMax: Int?
    public var sets: Int?
    public var restSec: Int?
    /// Used for the first session, when there's no history to go on.
    public var startWeight: Double?

    public init(increment: Double? = nil, repMin: Int? = nil, repMax: Int? = nil, sets: Int? = nil,
                restSec: Int? = nil, startWeight: Double? = nil) {
        self.increment = increment
        self.repMin = repMin
        self.repMax = repMax
        self.sets = sets
        self.restSec = restSec
        self.startWeight = startWeight
    }

    public var isEmpty: Bool { self == ExerciseOverrides() }
}

extension PlanItem {
    /// This item with `overrides` applied. The start weight isn't part of a plan item; it goes to `TargetPlanner`.
    public func applying(_ overrides: ExerciseOverrides?) -> PlanItem {
        guard let overrides else { return self }
        var item = self
        if let value = overrides.increment { item.increment = value }
        if let value = overrides.repMin { item.repMin = value }
        if let value = overrides.repMax { item.repMax = value }
        if let value = overrides.sets { item.sets = value }
        if let value = overrides.restSec { item.restSec = value }
        return item
    }
}

extension ExerciseSettings {
    public var overrides: ExerciseOverrides {
        get {
            ExerciseOverrides(increment: increment, repMin: repMin, repMax: repMax, sets: sets,
                              restSec: restSec, startWeight: startWeight)
        }
        set {
            increment = newValue.increment
            repMin = newValue.repMin
            repMax = newValue.repMax
            sets = newValue.sets
            restSec = newValue.restSec
            startWeight = newValue.startWeight
        }
    }
}
