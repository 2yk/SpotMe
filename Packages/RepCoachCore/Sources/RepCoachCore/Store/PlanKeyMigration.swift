import Foundation
import SwiftData

/// Plan 12 (13 Oct 2026) moved workouts between weekday keys. A key names a workout, and everything stored under
/// one belongs to that workout: key "friday" was Push B and is now Legs B, Push B is "saturday", and "sunday" is
/// Full Rest (plan 11's Long Run + Mobility + Core B left the week). This moves what was stored under the old
/// meaning to the key of the workout it was done in:
///
/// - **Sessions** are told apart by what was logged in them: a "friday" session of Push B's exercises becomes
///   "saturday", a "saturday" session of Full Rest's ticks becomes "sunday". Looking at the content makes it safe
///   to run any number of times, and to run on a session that arrives from a device still on the old plan.
/// - **Plan edits** carry the plan version of their keys (`PlanEdits.planKeys`) and move once.
public enum PlanKeyMigration {
    public struct Report: Equatable, Sendable {
        /// Sessions given the key of the workout they were done in.
        public var sessions = 0
        /// Edited exercise lists moved to the key of their workout.
        public var listsMoved = 0
        /// Exercises dropped from edited lists because plan 12 took them out of the week, and the whole edited
        /// list of plan 11's Sunday.
        public var exercisesDropped = 0
        /// Exercises put in place of a removed one in an edited list (weighted plank for the Copenhagen plank,
        /// seated cable row for the single-arm row, the barbell bench at the head of Wednesday).
        public var exercisesReplaced = 0
        /// The Rearrange days mapping was reset to the plan's own.
        public var scheduleReset = false

        public init() {}

        public var isEmpty: Bool {
            sessions == 0 && listsMoved == 0 && exercisesDropped == 0 && exercisesReplaced == 0 && !scheduleReset
        }

        /// "2 sessions moved, 1 edited list moved, 3 exercises dropped, Rearrange days reset"
        public var summary: String {
            var parts: [String] = []
            if sessions > 0 { parts.append("\(sessions) session\(sessions == 1 ? "" : "s") moved") }
            if listsMoved > 0 { parts.append("\(listsMoved) edited list\(listsMoved == 1 ? "" : "s") moved") }
            if exercisesReplaced > 0 { parts.append("\(exercisesReplaced) exercise\(exercisesReplaced == 1 ? "" : "s") replaced") }
            if exercisesDropped > 0 { parts.append("\(exercisesDropped) exercise\(exercisesDropped == 1 ? "" : "s") dropped") }
            if scheduleReset { parts.append("Rearrange days reset") }
            return parts.joined(separator: ", ")
        }
    }

    /// Where a workout went: sessions and edits under `from` that belong to the workout now at `to`.
    static let moves: [(from: String, to: String)] = [("friday", "saturday"), ("saturday", "sunday")]

    /// Exercises plan 12 took out of the week (the Copenhagen plank and the single-arm row are replaced where
    /// they stood; plan 11's Sunday went with its workout).
    static let removed: Set<String> = [
        "copenhagen-plank", "single-arm-cable-row", "long-run", "90-90-hip-flow", "thoracic-rotations",
        "pigeon-pose", "couch-stretch", "doorway-pec-overhead-lat-stretch", "pallof-press", "suitcase-carry",
        "ab-wheel-rollout-knees", "side-plank-with-reach", "l-sit-progression",
    ]

    /// `plan` is the plan as shipped (runs included).
    @discardableResult
    public static func run(in context: ModelContext, plan: Plan) throws -> Report {
        var report = Report()
        report.sessions = try moveSessions(in: context, plan: plan)
        try migrateEdits(in: context, report: &report)
        if report.sessions + report.listsMoved + report.exercisesDropped + report.exercisesReplaced > 0
            || report.scheduleReset {
            try context.save()
        }
        return report
    }

    // MARK: Sessions

    /// Whether `session`, kept under `from`, belongs to the workout at `to`: it holds an exercise of that
    /// workout and none of its own.
    static func belongs(_ ids: Set<String>, from: String, to: String, plan: Plan) -> Bool {
        guard let own = plan.days.first(where: { $0.key == from }),
              let target = plan.days.first(where: { $0.key == to }) else { return false }
        return ids.isDisjoint(with: own.items.map(\.exerciseId)) && !ids.isDisjoint(with: target.items.map(\.exerciseId))
    }

    /// The plan's exercise each log of `session` stands in for, under its current id.
    static func loggedIds(_ session: WorkoutSession) -> Set<String> {
        Set(session.logs.map { ExerciseIdRenames.current($0.slotExerciseId ?? $0.exerciseId) })
    }

    /// Gives `session` the key of the workout it was done in. Returns whether it moved.
    @discardableResult
    public static func relocate(_ session: WorkoutSession, plan: Plan) -> Bool {
        guard let move = moves.first(where: { $0.from == session.dayKey }),
              belongs(loggedIds(session), from: move.from, to: move.to, plan: plan) else { return false }
        session.dayKey = move.to
        return true
    }

    /// Moves sessions to the key of the workout they were done in. Returns how many.
    @discardableResult
    public static func moveSessions(in context: ModelContext, plan: Plan) throws -> Int {
        var moved = 0
        for move in moves {
            let from = move.from
            let sessions = try context.fetch(FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.dayKey == from }))
            for session in sessions where relocate(session, plan: plan) { moved += 1 }
        }
        return moved
    }

    /// Plan 11's Sunday as History names it: its sessions keep the key "sunday", which is Full Rest now.
    /// nil for any other session.
    public static func retiredHeadline(of session: WorkoutSession, in plan: Plan) -> String? {
        guard session.dayKey == "sunday", !session.logs.isEmpty,
              let sunday = plan.days.first(where: { $0.key == "sunday" }),
              loggedIds(session).isDisjoint(with: sunday.items.map(\.exerciseId)) else { return nil }
        return "Long Run + Mobility + Core B"
    }

    // MARK: Plan edits

    private static func migrateEdits(in context: ModelContext, report: inout Report) throws {
        for row in try context.fetch(FetchDescriptor<PlanEditsRecord>()) {
            guard let edits = try? JSONDecoder().decode(PlanEdits.self, from: row.data),
                  edits.planKeys < PlanEdits.currentPlanKeys else { continue }
            let migrated = edits.onCurrentPlanKeys(report: &report)
            if let data = try? JSONEncoder().encode(migrated) { row.data = data }
        }
    }
}

extension PlanEdits {
    /// These edits on plan 12's workout keys; edits already on them come back as they are. Edits that came from
    /// the other device on plan 11's keys are moved the same way.
    public func onCurrentPlanKeys() -> PlanEdits {
        var report = PlanKeyMigration.Report()
        return onCurrentPlanKeys(report: &report)
    }

    func onCurrentPlanKeys(report: inout PlanKeyMigration.Report) -> PlanEdits {
        guard planKeys < Self.currentPlanKeys else { return self }
        var next = self
        next.planKeys = Self.currentPlanKeys

        var lists: [String: [String]] = [:]
        for (key, ids) in days {
            switch key {
            case "friday": lists["saturday"] = ids; report.listsMoved += 1
            case "saturday": lists["sunday"] = ids; report.listsMoved += 1
            case "sunday": report.exercisesDropped += ids.count
            default: lists[key] = ids
            }
        }

        // Where plan 12 put another exercise in the place of a removed one, the edited list gets it in the same
        // place; the barbell bench leads Wednesday ahead of the incline press.
        func replace(_ old: String, with new: String, on key: String) {
            guard var ids = lists[key], let index = ids.firstIndex(of: old) else { return }
            ids[index] = new
            var seen = Set<String>()
            lists[key] = ids.filter { seen.insert($0).inserted }
            report.exercisesReplaced += 1
        }
        replace("copenhagen-plank", with: "weighted-plank", on: "tuesday")
        replace("single-arm-cable-row", with: "seated-cable-row", on: "thursday")
        if var ids = lists["wednesday"], !ids.contains("barbell-bench-press") {
            let index = ids.firstIndex(of: "incline-db-press")
                ?? ids.firstIndex { !$0.hasSuffix("-warmup") } ?? ids.count
            ids.insert("barbell-bench-press", at: index)
            lists["wednesday"] = ids
            report.exercisesReplaced += 1
        }

        for (key, ids) in lists {
            let kept = ids.filter { !PlanKeyMigration.removed.contains($0) }
            if kept.count != ids.count {
                report.exercisesDropped += ids.count - kept.count
                lists[key] = kept
            }
        }
        next.days = lists

        // A mapping made on plan 11 moved workouts that have changed since.
        if !schedule.isEmpty {
            next.schedule = [:]
            report.scheduleReset = true
        }
        return next
    }
}
