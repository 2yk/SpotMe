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

    struct Week: Identifiable {
        let start: Date
        let sets: Int

        var id: Date { start }
    }

    private(set) var exercises: [Exercise] = []
    private(set) var weeks: [Week] = []
    private(set) var sessionCount = 0

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
            let points = entries.reversed().map { point(for: $0, kind: item.kind) }
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
        sessionCount = (try? context.fetchCount(FetchDescriptor<WorkoutSession>())) ?? 0

        let timestamps = (try? store.countedSetTimestamps()) ?? []
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        weeks = (0..<8).reversed().compactMap { weeksBack in
            guard let start = calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: thisWeek),
                  let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) else { return nil }
            return Week(start: start, sets: timestamps.filter { $0 >= start && $0 < end }.count)
        }
    }

    private func point(for entry: HistoryEntry, kind: ItemKind) -> Point {
        if kind == .weighted {
            return Point(date: entry.date, value: entry.sets.map(\.weight).max() ?? 0,
                         e1rm: entry.sets.map { ProgressionEngine.estimated1RM(weight: $0.weight, reps: $0.reps) }.max(),
                         isDeload: entry.isDeload)
        }
        return Point(date: entry.date, value: Double(entry.sets.map(\.reps).max() ?? 0), e1rm: nil,
                     isDeload: entry.isDeload)
    }
}
