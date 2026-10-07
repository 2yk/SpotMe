import Foundation
import SwiftData

/// What the phone sends the watch (WatchConnectivity application context, latest wins): settings, exercise
/// overrides and plan edits, which the watch applies between sessions and never in the middle of one, plus the
/// sessions the phone has stored, so the watch knows what it no longer needs to re-send.
public struct SyncContext: Codable, Equatable, Sendable {
    public var settings: TrainingSettings
    /// By exerciseId; exercises as in plan.json are absent.
    public var overrides: [String: ExerciseOverrides]
    /// Exercises added, removed or moved, and the user's own exercises.
    public var plan: PlanEdits
    /// Ids of the sessions the phone most recently stored.
    public var received: [UUID]
    /// Today's swaps as the phone has them. Unlike the rest of this context they apply at once, mid-workout.
    public var swaps: SwapMarks
    public var sentAt: Date

    public init(settings: TrainingSettings, overrides: [String: ExerciseOverrides], plan: PlanEdits = PlanEdits(),
                received: [UUID] = [], swaps: SwapMarks = SwapMarks(), sentAt: Date = .now) {
        self.settings = settings
        self.overrides = overrides
        self.plan = plan
        self.received = received
        self.swaps = swaps
        self.sentAt = sentAt
    }

    /// Contexts from before plan edits existed carry none.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        settings = try container.decode(TrainingSettings.self, forKey: .settings)
        overrides = try container.decode([String: ExerciseOverrides].self, forKey: .overrides)
        plan = try container.decodeIfPresent(PlanEdits.self, forKey: .plan) ?? PlanEdits()
        received = try container.decodeIfPresent([UUID].self, forKey: .received) ?? []
        swaps = try container.decodeIfPresent(SwapMarks.self, forKey: .swaps) ?? SwapMarks()
        sentAt = try container.decode(Date.self, forKey: .sentAt)
    }

    /// The overrides stored in `context`, keyed by exerciseId.
    public static func overrides(in context: ModelContext) throws -> [String: ExerciseOverrides] {
        let rows = try context.fetch(FetchDescriptor<ExerciseSettings>())
        return Dictionary(rows.filter { !$0.overrides.isEmpty }.map { ($0.exerciseId, $0.overrides) },
                          uniquingKeysWith: { first, _ in first })
    }

    /// Makes the plan's customisation in `context` exactly this: the overrides and the plan edits.
    public func applyPlan(to context: ModelContext) throws {
        try applyOverrides(to: context)
        try plan.save(to: context)
    }

    /// Makes the overrides in `context` exactly these: changed rows are updated, missing ones added, and rows
    /// for exercises no longer overridden deleted.
    public func applyOverrides(to context: ModelContext) throws {
        // An exercise renamed since the sender's build keeps its settings under the current id.
        var remaining = Dictionary(overrides.map { (ExerciseIdRenames.current($0.key), $0.value) },
                                   uniquingKeysWith: { first, _ in first })
        for row in try context.fetch(FetchDescriptor<ExerciseSettings>()) {
            if let wanted = remaining.removeValue(forKey: row.exerciseId) {
                row.overrides = wanted
            } else {
                context.delete(row)
            }
        }
        for (exerciseId, wanted) in remaining {
            let row = ExerciseSettings(exerciseId: exerciseId)
            row.overrides = wanted
            context.insert(row)
        }
        try context.save()
    }

    // MARK: WatchConnectivity

    static let key = "context"

    public var applicationContext: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return [Self.key: data]
    }

    public init?(applicationContext: [String: Any]) {
        guard let data = applicationContext[Self.key] as? Data,
              let context = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = context
    }
}
