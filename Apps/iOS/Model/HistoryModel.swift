import Foundation
import SwiftData
import RepCoachCore

/// What the History tab shows, read from SwiftData.
@MainActor @Observable
final class HistoryModel {
    struct Exercise: Identifiable {
        let item: PlanItem
        let dayTitle: String
        /// Newest first, deloads included.
        let entries: [HistoryEntry]
        /// Oldest first, for charts.
        let points: [Point]

        var id: String { item.exerciseId }

        /// Change in the headline number from the first logged session to the latest.
        var change: Double? {
            guard points.count > 1, let first = points.first, let last = points.last else { return nil }
            return last.value - first.value
        }
    }

    struct Point: Identifiable {
        let date: Date
        /// Weighted: the heaviest set. Otherwise the best reps (or seconds).
        let value: Double
        /// Weighted only: the best Epley estimate among the session's sets.
        let e1rm: Double?
        let isDeload: Bool

        var id: Date { date }
    }

    /// One logged workout, for the SESSIONS list (board 8.1).
    struct SessionRow: Identifiable {
        let session: WorkoutSession
        /// "Push A".
        let name: String
        let minutes: Int?
        let kcal: Int?
        let effort: Int?
        /// Items finished (done or skipped) and the day's items.
        let done: Int
        let total: Int

        var id: UUID { session.id }
        var date: Date { session.date }
        var isFinished: Bool { total > 0 && done >= total }

        /// "Wed 7 Oct · 48 min · 342 kcal · Hard 7", whatever of it is known.
        var detail: String {
            var parts = [date.weekdayDayMonth]
            if let minutes { parts.append("\(minutes) min") }
            if let kcal { parts.append("\(kcal) kcal") }
            if let effort { parts.append("\(EffortBand(effort).word) \(effort)") }
            return parts.joined(separator: " · ")
        }
    }

    struct Week: Identifiable {
        let start: Date
        let sets: Int

        var id: Date { start }
    }

    private(set) var exercises: [Exercise] = []
    private(set) var weeks: [Week] = []
    private(set) var sessionCount = 0
    /// Newest first.
    private(set) var sessions: [SessionRow] = []
    private(set) var firstSessionDate: Date?

    /// Training weeks run Monday to Sunday, whatever the locale says.
    static let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }()

    /// Titles exercises that are on no day any more, but have history.
    static let notInPlan = "Not in the plan"

    /// - Parameters:
    ///   - plan: as the user has it, edits and names applied (`TodayModel.editedPlan`).
    ///   - library: every exercise, for history of ones taken off every day (`TodayModel.library`).
    func load(plan: Plan, library: [PlanItem], context: ModelContext) {
        let calendar = Self.calendar
        let store = HistoryStore(context: context)
        var seen = Set<String>()
        var exercises: [Exercise] = []
        func add(_ item: PlanItem, dayTitle: String) {
            guard item.kind != .checklist, seen.insert(item.exerciseId).inserted else { return }
            let entries = (try? store.entries(for: item.exerciseId)) ?? []
            guard !entries.isEmpty else { return }
            let points = entries.reversed().map { Self.point(for: $0, kind: item.kind) }
            exercises.append(Exercise(item: item, dayTitle: dayTitle, entries: entries, points: points))
        }
        for day in plan.days {
            day.items.forEach { add($0, dayTitle: day.title) }
        }
        library.forEach { add($0, dayTitle: Self.notInPlan) }
        // Exercises logged by a swap on the watch that are in no plan: by their own names.
        let logged = (try? store.loggedExerciseIds()) ?? []
        for id in logged.subtracting(seen).sorted() {
            if let exercise = ExerciseDatabase.shared?.exercise(id: id) {
                add(PlanItem(database: exercise), dayTitle: Self.notInPlan)
            }
        }
        self.exercises = exercises
        let stored = (try? context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
        sessionCount = stored.count
        firstSessionDate = stored.last?.date
        sessions = stored.map { session in
            let day = plan.days.first { $0.key == session.dayKey }
            let seconds = session.activeSeconds ?? session.endedAt.map { $0.timeIntervalSince(session.date) }
            return SessionRow(session: session, name: day?.headline ?? session.dayKey.capitalized,
                              minutes: seconds.flatMap { $0 >= 60 ? Int(($0 / 60).rounded()) : nil },
                              kcal: session.energyKcal.map { Int($0.rounded()) }, effort: session.effort,
                              done: session.logs.filter { $0.completedAt != nil }.count,
                              total: day?.items.count ?? session.logs.count)
        }

        let timestamps = (try? store.countedSetTimestamps()) ?? []
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        weeks = (0..<8).reversed().compactMap { weeksBack in
            guard let start = calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: thisWeek),
                  let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) else { return nil }
            return Week(start: start, sets: timestamps.filter { $0 >= start && $0 < end }.count)
        }
    }

    /// One exercise with every session logged for it (today's included), for its own screen.
    static func exercise(for item: PlanItem, dayTitle: String, context: ModelContext) -> Exercise {
        let entries = (try? HistoryStore(context: context).entries(for: item.exerciseId)) ?? []
        return Exercise(item: item, dayTitle: dayTitle, entries: entries,
                        points: entries.reversed().map { point(for: $0, kind: item.kind) })
    }

    private static func point(for entry: HistoryEntry, kind: ItemKind) -> Point {
        if kind == .weighted {
            return Point(date: entry.date, value: entry.sets.map(\.weight).max() ?? 0,
                         e1rm: entry.sets.map { ProgressionEngine.estimated1RM(weight: $0.weight, reps: $0.reps) }.max(),
                         isDeload: entry.isDeload)
        }
        return Point(date: entry.date, value: Double(entry.sets.map(\.reps).max() ?? 0), e1rm: nil,
                     isDeload: entry.isDeload)
    }
}
