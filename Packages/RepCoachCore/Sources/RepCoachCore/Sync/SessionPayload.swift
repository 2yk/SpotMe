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
    public var logs: [Log]

    /// A snapshot of `session` and everything logged in it.
    public init(_ session: WorkoutSession) {
        id = session.id
        date = session.date
        dayKey = session.dayKey
        isDeload = session.isDeload
        endedAt = session.endedAt
        healthKitWorkoutId = session.healthKitWorkoutId
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

        for entry in logs {
            let log = ExerciseLog(exerciseId: entry.exerciseId, order: entry.order)
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
        try context.save()
        return session
    }
}
