import Foundation

/// How an item in the plan is logged.
public enum ItemKind: String, Codable, Sendable {
    /// Tick to complete: runs, warmups, cooldowns, mobility, neck work.
    case checklist
    /// Weight + reps per set, driven by the progression engine.
    case weighted
    /// Reps per set; weight optional when `loadable` is true.
    case reps
    /// Seconds per set (holds, carries); weight optional when `loadable` is true.
    case timed
    /// One all-out set of strict pull-ups. Reps only.
    case amrap
    /// Sets at a percentage of today's AMRAP (Thursday volume sets).
    case percentOfMax
}

public struct PlanItem: Codable, Hashable, Identifiable, Sendable {
    public var name: String
    /// Stable across days and plan versions; history is keyed on this.
    public var exerciseId: String
    public var group: String
    public var note: String?
    /// Human-readable prescription, e.g. "4 × 8–12".
    public var display: String?
    public var kind: ItemKind
    public var steps: [String]?
    public var sets: Int?
    public var repMin: Int?
    public var repMax: Int?
    public var secMin: Int?
    public var secMax: Int?
    public var perSide: Bool?
    public var loadable: Bool?
    /// Smallest weight jump available for this exercise, in kg.
    public var increment: Double?
    /// Consecutive sessions at the top of the rep range needed before adding weight.
    public var sessionsAtTopToProgress: Int?
    public var restSec: Int?
    public var percent: Double?
    public var sourceExerciseId: String?
    /// Items sharing a superset group alternate set by set.
    public var supersetGroup: String?

    public var id: String { exerciseId }
}

public struct PlanDay: Codable, Hashable, Identifiable, Sendable {
    public var key: String
    /// Calendar weekday: 1 = Sunday, 2 = Monday … 7 = Saturday.
    public var weekday: Int
    public var title: String
    public var focus: String
    public var time: String
    public var items: [PlanItem]

    public var id: String { key }
}

public struct Plan: Codable, Hashable, Sendable {
    public var planVersion: Int
    public var deloadEveryNthWeek: Int
    public var days: [PlanDay]

    public func day(forWeekday weekday: Int) -> PlanDay? {
        days.first { $0.weekday == weekday }
    }

    public func day(for date: Date, calendar: Calendar = .current) -> PlanDay? {
        day(forWeekday: calendar.component(.weekday, from: date))
    }

    /// The plan that ships with the app (v11 muscle-gain phase).
    public static func bundled() throws -> Plan {
        guard let url = Bundle.module.url(forResource: "plan", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(Plan.self, from: Data(contentsOf: url))
    }

    /// Week number (1-based) since the program start date. Every `deloadEveryNthWeek`th week is a deload.
    public func isDeloadWeek(programStart: Date, today: Date, calendar: Calendar = .current) -> Bool {
        guard deloadEveryNthWeek > 0 else { return false }
        let start = calendar.startOfDay(for: programStart)
        let now = calendar.startOfDay(for: today)
        guard let days = calendar.dateComponents([.day], from: start, to: now).day, days >= 0 else { return false }
        let week = days / 7 + 1
        return week % deloadEveryNthWeek == 0
    }
}
