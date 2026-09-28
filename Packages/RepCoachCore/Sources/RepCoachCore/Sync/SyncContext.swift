import Foundation
import SwiftData

/// What the phone sends the watch (WatchConnectivity application context, latest wins): settings and plan
/// overrides, which the watch applies between sessions and never in the middle of one, plus the sessions the
/// phone has stored, so the watch knows what it no longer needs to re-send.
public struct SyncContext: Codable, Equatable, Sendable {
    public var settings: TrainingSettings
    /// By exerciseId; exercises as in plan.json are absent.
    public var overrides: [String: ExerciseOverrides]
    /// Ids of the sessions the phone most recently stored.
    public var received: [UUID]
    public var sentAt: Date

    public init(settings: TrainingSettings, overrides: [String: ExerciseOverrides], received: [UUID] = [],
                sentAt: Date = .now) {
        self.settings = settings
        self.overrides = overrides
        self.received = received
        self.sentAt = sentAt
    }

    /// The overrides stored in `context`, keyed by exerciseId.
    public static func overrides(in context: ModelContext) throws -> [String: ExerciseOverrides] {
        let rows = try context.fetch(FetchDescriptor<ExerciseSettings>())
        return Dictionary(rows.filter { !$0.overrides.isEmpty }.map { ($0.exerciseId, $0.overrides) },
                          uniquingKeysWith: { first, _ in first })
    }

    /// Makes the overrides in `context` exactly these: changed rows are updated, missing ones added, and rows
    /// for exercises no longer overridden deleted.
    public func applyOverrides(to context: ModelContext) throws {
        var remaining = overrides
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
