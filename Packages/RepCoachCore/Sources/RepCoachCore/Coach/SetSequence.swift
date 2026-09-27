import Foundation

/// One set in the order it's performed.
public struct SetStep: Hashable, Sendable {
    /// Which of the exercise's items (one, or two for a superset) this set belongs to.
    public var item: Int
    /// 1-based set number for that item.
    public var set: Int
    /// Seconds of rest after this set; nil when the next set follows straight away or this is the last one.
    public var restAfter: Int?

    public init(item: Int, set: Int, restAfter: Int?) {
        self.item = item
        self.set = set
        self.restAfter = restAfter
    }
}

public enum SetSequence {
    /// A single item runs its sets with rest in between. A superset alternates A1 → B1 → rest → A2 → B2 → rest …,
    /// resting for the second item's rest time after each round.
    /// - Parameters:
    ///   - sets: sets per item.
    ///   - rest: rest seconds per item.
    public static func steps(sets: [Int], rest: [Int]) -> [SetStep] {
        var steps: [SetStep] = []
        let rounds = sets.max() ?? 0
        guard rounds > 0 else { return [] }
        for round in 1...rounds {
            for item in sets.indices where sets[item] >= round {
                steps.append(SetStep(item: item, set: round, restAfter: nil))
            }
            if let last = steps.indices.last {
                steps[last].restAfter = rest[steps[last].item]
            }
        }
        steps[steps.count - 1].restAfter = nil
        return steps
    }
}
