import Foundation
import SwiftData

/// One past session of one exercise.
public struct HistoryEntry: Hashable, Sendable {
    public var sessionId: UUID
    public var date: Date
    public var isDeload: Bool
    /// In the order performed. Timed sets carry their seconds in `reps`.
    public var sets: [LoggedSet]

    public init(sessionId: UUID, date: Date, isDeload: Bool, sets: [LoggedSet]) {
        self.sessionId = sessionId
        self.date = date
        self.isDeload = isDeload
        self.sets = sets
    }
}

/// Reads past sessions in the shape the progression engine wants.
public struct HistoryStore {
    public let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Previous non-deload sessions of `exerciseId`, newest first: the input for `ProgressionEngine.firstTarget`.
    /// - Parameter sessionId: today's session, left out so targets don't move while sets are being logged.
    public func history(for exerciseId: String, excluding sessionId: UUID? = nil) throws -> [[LoggedSet]] {
        try entries(for: exerciseId, excluding: sessionId)
            .filter { !$0.isDeload }
            .map(\.sets)
    }

    /// Every session with at least one counted set of `exerciseId`, deloads included, newest first. Ramp-up sets
    /// are left out, and a session with only ramp-ups isn't there.
    public func entries(for exerciseId: String, excluding sessionId: UUID? = nil) throws -> [HistoryEntry] {
        let id = exerciseId
        let logs = try context.fetch(FetchDescriptor<ExerciseLog>(predicate: #Predicate { $0.exerciseId == id }))
        return logs
            .compactMap { log -> HistoryEntry? in
                let sets = log.countedLoggedSets
                guard let session = log.session, session.id != sessionId, !sets.isEmpty else { return nil }
                return HistoryEntry(sessionId: session.id, date: session.date, isDeload: session.isDeload, sets: sets)
            }
            .sorted { $0.date > $1.date }
    }

    /// Every exerciseId with at least one counted set.
    public func loggedExerciseIds() throws -> Set<String> {
        Set(try context.fetch(FetchDescriptor<ExerciseLog>()).filter { !$0.countedSets.isEmpty }.map(\.exerciseId))
    }
}
