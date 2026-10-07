import Foundation
import SwiftData

/// Exercise ids that were renamed in plan.json. History is keyed on the id, so stored data under an old id is
/// moved to the new one (`IdMigration`), and anything that arrives from the other device with an old id is
/// mapped on receipt.
public enum ExerciseIdRenames {
    /// Old id → current id. "Machine Chest Press (or Flat Bench)" became one exercise, Machine Chest Press
    /// (watch build 9): everything logged under the old id counts as Machine Chest Press.
    public static let all: [String: String] = [
        "machine-chest-press-or-flat-bench": "machine-chest-press",
    ]

    public static func current(_ id: String) -> String { all[id] ?? id }

    /// The old ids that now read `id`.
    public static func legacy(of id: String) -> [String] {
        all.filter { $0.value == id }.map(\.key).sorted()
    }

    /// The day's small state kept in UserDefaults (put-off and skipped-ramp-up marks) holds exercise ids under
    /// keys that start with one of these.
    static let defaultsPrefixes = ["waiting.", "rampSkipped."]
}

/// Moves everything stored under a renamed exercise id to the current id. Idempotent: with nothing under an
/// old id it changes nothing.
public enum IdMigration {
    public struct Report: Equatable, Sendable {
        /// Exercise logs (one per exercise per session) renamed.
        public var logs = 0
        /// The sets in those logs.
        public var sets = 0
        /// Per-exercise settings rows (renames, increments, start weights) moved.
        public var settings = 0
        /// Plan edits rewritten (1 when the day lists or custom exercises named an old id).
        public var planEdits = 0
        /// Marks in UserDefaults (put off, ramp-ups skipped) rewritten.
        public var marks = 0

        public init() {}

        public var isEmpty: Bool { logs == 0 && settings == 0 && planEdits == 0 && marks == 0 }

        /// "Renamed machine-chest-press-or-flat-bench: 12 sets in 4 logs, 1 settings row"
        public var summary: String {
            var parts = ["\(sets) set\(sets == 1 ? "" : "s") in \(logs) log\(logs == 1 ? "" : "s")"]
            if settings > 0 { parts.append("\(settings) settings row\(settings == 1 ? "" : "s")") }
            if planEdits > 0 { parts.append("plan edits") }
            if marks > 0 { parts.append("\(marks) mark\(marks == 1 ? "" : "s")") }
            return parts.joined(separator: ", ")
        }
    }

    @discardableResult
    public static func run(in context: ModelContext, defaults: UserDefaults? = nil) throws -> Report {
        var report = Report()
        for (old, new) in ExerciseIdRenames.all.sorted(by: { $0.key < $1.key }) {
            try renameLogs(old, to: new, in: context, report: &report)
            try renameSettings(old, to: new, in: context, report: &report)
        }
        try renamePlanEdits(in: context, report: &report)
        if let defaults { report.marks = renameMarks(in: defaults) }
        if report.logs + report.settings + report.planEdits > 0 { try context.save() }
        return report
    }

    private static func renameLogs(_ old: String, to new: String, in context: ModelContext,
                                   report: inout Report) throws {
        let oldId = old
        let logs = try context.fetch(FetchDescriptor<ExerciseLog>(predicate: #Predicate { $0.exerciseId == oldId }))
        for log in logs {
            report.logs += 1
            report.sets += log.sets.count
            if let twin = log.session?.log(for: new), twin !== log {
                // Both ids in one session can't happen from this app; fold the sets together if it ever does.
                var index = (twin.sets.map(\.index).max() ?? 0) + 1
                for set in log.orderedSets {
                    set.index = index
                    index += 1
                    set.log = twin
                }
                context.delete(log)
            } else {
                log.exerciseId = new
            }
        }
    }

    private static func renameSettings(_ old: String, to new: String, in context: ModelContext,
                                       report: inout Report) throws {
        let oldId = old
        let rows = try context.fetch(FetchDescriptor<ExerciseSettings>(predicate: #Predicate { $0.exerciseId == oldId }))
        for row in rows {
            report.settings += 1
            let newId = new
            let exists = try context.fetchCount(
                FetchDescriptor<ExerciseSettings>(predicate: #Predicate { $0.exerciseId == newId })) > 0
            if exists { context.delete(row) } else { row.exerciseId = new }
        }
    }

    private static func renamePlanEdits(in context: ModelContext, report: inout Report) throws {
        let rows = try context.fetch(FetchDescriptor<PlanEditsRecord>())
        for row in rows {
            guard var edits = try? JSONDecoder().decode(PlanEdits.self, from: row.data) else { continue }
            let before = edits
            edits.renameExercises()
            guard edits != before, let data = try? JSONEncoder().encode(edits) else { continue }
            row.data = data
            report.planEdits += 1
        }
    }

    /// Rewrites the ids in the day's put-off and skipped-ramp-up lists. Returns how many lists changed.
    static func renameMarks(in defaults: UserDefaults) -> Int {
        var changed = 0
        for (key, value) in defaults.dictionaryRepresentation() {
            guard ExerciseIdRenames.defaultsPrefixes.contains(where: key.hasPrefix),
                  let ids = value as? [String] else { continue }
            let renamed = ids.map(ExerciseIdRenames.current)
            guard renamed != ids else { continue }
            var seen = Set<String>()
            defaults.set(renamed.filter { seen.insert($0).inserted }, forKey: key)
            changed += 1
        }
        return changed
    }
}

extension PlanEdits {
    /// Day lists and custom exercises that name a renamed exercise name its current id.
    mutating func renameExercises() {
        for (day, ids) in days {
            var seen = Set<String>()
            days[day] = ids.map(ExerciseIdRenames.current).filter { seen.insert($0).inserted }
        }
        for (id, item) in custom {
            var renamed = item
            if let source = item.sourceExerciseId { renamed.sourceExerciseId = ExerciseIdRenames.current(source) }
            custom[id] = renamed
        }
    }
}
