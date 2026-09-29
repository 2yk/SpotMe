import Foundation
import SwiftData

/// A session as the watch sends it to the phone (WatchConnectivity `transferUserInfo`).
public struct SessionPayload: Codable, Equatable, Sendable {
    public struct Log: Codable, Equatable, Sendable {
        public var exerciseId: String
        public var order: Int
        public var completedAt: Date?
        public var skipped: Bool
        public var sets: [SetEntry]
    }

    public struct SetEntry: Codable, Equatable, Sendable {
        public var index: Int
        public var weight: Double
        public var reps: Int
        public var seconds: Int?
        public var timestamp: Date
    }

    public var id: UUID
    public var date: Date
    public var dayKey: String
    public var isDeload: Bool
    public var endedAt: Date?
    public var healthKitWorkoutId: UUID?
    /// How hard the session felt, 1 to 10. Rated after Finish, so a session is sent again with it.
    public var effort: Int?
    public var logs: [Log]

    /// A snapshot of `session` and everything logged in it.
    public init(_ session: WorkoutSession) {
        id = session.id
        date = session.date
        dayKey = session.dayKey
        isDeload = session.isDeload
        endedAt = session.endedAt
        healthKitWorkoutId = session.healthKitWorkoutId
        effort = session.effort
        logs = session.logs.sorted { $0.order < $1.order }.map { log in
            Log(exerciseId: log.exerciseId, order: log.order, completedAt: log.completedAt, skipped: log.skipped,
                sets: log.orderedSets.map {
                    SetEntry(index: $0.index, weight: $0.weight, reps: $0.reps, seconds: $0.seconds, timestamp: $0.timestamp)
                })
        }
    }

    // MARK: WatchConnectivity

    static let key = "session"

    public var userInfo: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return [Self.key: data]
    }

    public init?(userInfo: [String: Any]) {
        guard let data = userInfo[Self.key] as? Data,
              let payload = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = payload
    }

    // MARK: Storing

    /// Stores the session only if this device doesn't have it, so a copy restored from the other device never
    /// overwrites what's here. Returns whether it was stored.
    @discardableResult
    public func insertIfMissing(into context: ModelContext) throws -> Bool {
        let id = id
        guard try context.fetchCount(FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == id })) == 0
        else { return false }
        try upsert(into: context)
        return true
    }

    /// Inserts the session, or replaces the stored copy with the same id, so re-sends never duplicate anything.
    @discardableResult
    public func upsert(into context: ModelContext) throws -> WorkoutSession {
        let id = id
        let session: WorkoutSession
        if let existing = try context.fetch(FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == id })).first {
            session = existing
            let old = session.logs
            session.logs.removeAll()
            old.forEach(context.delete)
        } else {
            session = WorkoutSession(id: id, date: date, dayKey: dayKey, isDeload: isDeload)
            context.insert(session)
        }
        session.date = date
        session.dayKey = dayKey
        session.isDeload = isDeload
        session.endedAt = endedAt
        session.healthKitWorkoutId = healthKitWorkoutId
        // A re-send with the rating adds it; one from before it was rated never takes it away.
        if let effort = Effort.valid(effort) { session.effort = effort }

        for entry in logs {
            insert(entry, order: entry.order, into: session, context: context)
        }
        try context.save()
        return session
    }

    /// Folds this session's items into `local`, the watch's own session for the same day, keeping the watch's
    /// log for any item both have. For a restored copy of a day the watch had already started again.
    public func merge(into local: WorkoutSession, context: ModelContext) throws {
        let kept = Set(local.logs.map(\.exerciseId))
        var order = (local.logs.map(\.order).max() ?? -1) + 1
        for entry in logs.sorted(by: { $0.order < $1.order }) where !kept.contains(entry.exerciseId) {
            insert(entry, order: order, into: local, context: context)
            order += 1
        }
        if local.effort == nil { local.effort = Effort.valid(effort) }
        try context.save()
    }

    private func insert(_ entry: Log, order: Int, into session: WorkoutSession, context: ModelContext) {
        let log = ExerciseLog(exerciseId: entry.exerciseId, order: order)
        context.insert(log)
        log.session = session
        log.completedAt = entry.completedAt
        log.skipped = entry.skipped
        for set in entry.sets {
            let row = SetLog(index: set.index, weight: set.weight, reps: set.reps, seconds: set.seconds,
                             timestamp: set.timestamp)
            context.insert(row)
            row.log = log
        }
    }
}
