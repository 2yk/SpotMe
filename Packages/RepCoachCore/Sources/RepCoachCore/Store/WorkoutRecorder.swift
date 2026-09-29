import Foundation
import SwiftData

/// Writes today's workout. Every change is saved straight away, so a crash or a flat battery loses nothing.
public struct WorkoutRecorder {
    public let context: ModelContext
    public var calendar: Calendar

    public init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    /// The session for `dayKey` started on the same calendar day as `date`, if any.
    public func session(for dayKey: String, on date: Date = .now) throws -> WorkoutSession? {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        let key = dayKey
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.dayKey == key && $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Today's session for `dayKey`, started now if there isn't one yet.
    public func startSession(for dayKey: String, on date: Date = .now, isDeload: Bool) throws -> WorkoutSession {
        if let existing = try session(for: dayKey, on: date) { return existing }
        let session = WorkoutSession(date: date, dayKey: dayKey, isDeload: isDeload)
        context.insert(session)
        try context.save()
        return session
    }

    /// The log for `exerciseId` in `session`, created on first use.
    public func log(for exerciseId: String, in session: WorkoutSession) throws -> ExerciseLog {
        if let existing = session.log(for: exerciseId) { return existing }
        let log = ExerciseLog(exerciseId: exerciseId, order: session.logs.count)
        context.insert(log)
        log.session = session
        try context.save()
        return log
    }

    @discardableResult
    public func addSet(to log: ExerciseLog, weight: Double, reps: Int, seconds: Int? = nil,
                       at date: Date = .now) throws -> SetLog {
        let index = (log.sets.map(\.index).max() ?? 0) + 1
        let set = SetLog(index: index, weight: weight, reps: reps, seconds: seconds, timestamp: date)
        context.insert(set)
        set.log = log
        try context.save()
        return set
    }

    /// Removes the most recent set and reopens the item. Returns the removed set, or nil if there was none.
    @discardableResult
    public func removeLastSet(from log: ExerciseLog) throws -> LoggedSet? {
        guard let last = log.sets.max(by: { $0.index < $1.index }) else { return nil }
        let removed = last.loggedSet
        log.sets.removeAll { $0.persistentModelID == last.persistentModelID }
        context.delete(last)
        log.completedAt = nil
        log.skipped = false
        try context.save()
        return removed
    }

    public func complete(_ log: ExerciseLog, at date: Date = .now) throws {
        log.completedAt = date
        log.skipped = false
        try context.save()
    }

    public func skip(_ log: ExerciseLog, at date: Date = .now) throws {
        log.completedAt = date
        log.skipped = true
        try context.save()
    }

    /// Puts a finished or skipped item back on the list. Logged sets are kept.
    public func reopen(_ log: ExerciseLog) throws {
        log.completedAt = nil
        log.skipped = false
        try context.save()
    }

    public func finish(_ session: WorkoutSession, at date: Date = .now) throws {
        session.endedAt = date
        try context.save()
    }

    /// Sessions from before `date`'s day that were never finished, e.g. when Finish workout wasn't tapped.
    public func unfinishedSessions(before date: Date = .now) throws -> [WorkoutSession] {
        let start = calendar.startOfDay(for: date)
        return try context.fetch(FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endedAt == nil && $0.date < start },
            sortBy: [SortDescriptor(\.date)]))
    }

    /// Finishes a forgotten session at the last moment anything was logged in it.
    public func finishAtLastActivity(_ session: WorkoutSession) throws {
        let moments = session.logs.flatMap { log in [log.completedAt].compactMap { $0 } + log.sets.map(\.timestamp) }
        try finish(session, at: moments.max() ?? session.date)
    }

    /// Deletes a session and everything logged in it: a discarded workout.
    public func delete(_ session: WorkoutSession) throws {
        context.delete(session)
        try context.save()
    }

    /// Deletes the stored sessions among `ids`. Returns how many there were.
    @discardableResult
    public func deleteSessions(_ ids: some Sequence<UUID>) throws -> Int {
        let wanted = Set(ids)
        guard !wanted.isEmpty else { return 0 }
        let doomed = try context.fetch(FetchDescriptor<WorkoutSession>()).filter { wanted.contains($0.id) }
        doomed.forEach(context.delete)
        try context.save()
        return doomed.count
    }

    /// Stored sessions' ids and start dates, oldest first (from `since` on, if given), for comparing with the
    /// other device.
    public func sessionStamps(since: Date? = nil) throws -> [(id: UUID, date: Date)] {
        let start = since ?? .distantPast
        return try context.fetch(FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.date >= start },
                                                                 sortBy: [SortDescriptor(\.date)]))
            .map { (id: $0.id, date: $0.date) }
    }

    /// Stored sessions' ids, oldest first.
    public func sessionIds(since: Date? = nil) throws -> [UUID] {
        try sessionStamps(since: since).map(\.id)
    }
}
