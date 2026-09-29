import Foundation
import SwiftData

/// One day's training. Created when the first item of the day is logged.
@Model
public final class WorkoutSession {
    @Attribute(.unique) public var id: UUID
    /// When the session started.
    public var date: Date
    /// Key of the plan day being trained, e.g. "monday". Usually today's weekday, but any day can be trained.
    public var dayKey: String
    /// Deload sessions are kept but left out of progression history.
    public var isDeload: Bool
    public var healthKitWorkoutId: UUID?
    /// Set when the workout is finished.
    public var endedAt: Date?
    /// How hard the session felt, 1 to 10 (`Effort`), rated on the watch after Finish. nil: not rated.
    public var effort: Int?

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
    public var logs: [ExerciseLog] = []

    public init(id: UUID = UUID(), date: Date = .now, dayKey: String, isDeload: Bool = false) {
        self.id = id
        self.date = date
        self.dayKey = dayKey
        self.isDeload = isDeload
    }
}

/// One plan item within a session.
@Model
public final class ExerciseLog {
    public var session: WorkoutSession?
    public var exerciseId: String
    /// Position in the order items were started within the session.
    public var order: Int
    /// Set when the item is finished or skipped.
    public var completedAt: Date?
    /// Skipped from Today without logging.
    public var skipped: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \SetLog.log)
    public var sets: [SetLog] = []

    public init(exerciseId: String, order: Int) {
        self.exerciseId = exerciseId
        self.order = order
    }
}

/// One performed set.
@Model
public final class SetLog {
    public var log: ExerciseLog?
    /// 1-based, in the order performed.
    public var index: Int
    /// kg; 0 for unloaded sets.
    public var weight: Double
    public var reps: Int
    /// Timed sets only.
    public var seconds: Int?
    public var timestamp: Date

    public init(index: Int, weight: Double, reps: Int, seconds: Int? = nil, timestamp: Date = .now) {
        self.index = index
        self.weight = weight
        self.reps = reps
        self.seconds = seconds
        self.timestamp = timestamp
    }
}

/// Per-exercise overrides edited on the iPhone. nil fields fall back to plan.json.
@Model
public final class ExerciseSettings {
    @Attribute(.unique) public var exerciseId: String
    /// A new name for the exercise, everywhere it appears.
    public var name: String?
    public var increment: Double?
    public var repMin: Int?
    public var repMax: Int?
    public var sets: Int?
    public var restSec: Int?
    public var startWeight: Double?

    public init(exerciseId: String) {
        self.exerciseId = exerciseId
    }
}

/// Flexed upper arm and waist, measured about every two weeks, in inches. iPhone only.
@Model
public final class BodyMeasurement {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    /// Flexed upper arm, at its widest.
    public var arm: Double
    /// Waist, at the navel.
    public var waist: Double

    public init(id: UUID = UUID(), date: Date = .now, arm: Double, waist: Double) {
        self.id = id
        self.date = date
        self.arm = arm
        self.waist = waist
    }
}

/// The user's `PlanEdits` (exercises added, removed or moved, and their own exercises), JSON-encoded in one row.
@Model
public final class PlanEditsRecord {
    public var data: Data

    public init(data: Data) {
        self.data = data
    }
}

// MARK: - Derived values

/// Where a plan item stands today.
public enum ItemStatus: Hashable, Sendable {
    case pending
    case inProgress(setsDone: Int)
    case done(Date)
    case skipped(Date)

    public var isFinished: Bool { finishedAt != nil }

    public var finishedAt: Date? {
        switch self {
        case .done(let at), .skipped(let at): at
        case .pending, .inProgress: nil
        }
    }
}

extension WorkoutSession {
    public func log(for exerciseId: String) -> ExerciseLog? {
        logs.first { $0.exerciseId == exerciseId }
    }

    /// Status of every item that has a log in this session, keyed by exerciseId.
    public var statuses: [String: ItemStatus] {
        Dictionary(logs.map { ($0.exerciseId, $0.status) }, uniquingKeysWith: { first, _ in first })
    }
}

extension ExerciseLog {
    /// Sets in the order performed.
    public var orderedSets: [SetLog] {
        sets.sorted { $0.index < $1.index }
    }

    public var status: ItemStatus {
        if let at = completedAt { return skipped ? .skipped(at) : .done(at) }
        return sets.isEmpty ? .pending : .inProgress(setsDone: sets.count)
    }
}

extension SetLog {
    /// The set as the engine sees it. Timed sets carry their seconds in `reps`.
    public var loggedSet: LoggedSet {
        LoggedSet(weight: weight, reps: seconds ?? reps)
    }
}
