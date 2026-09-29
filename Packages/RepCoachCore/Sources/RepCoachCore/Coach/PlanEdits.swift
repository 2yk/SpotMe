import Foundation
import SwiftData

/// The user's changes to the plan's days: exercises added, removed or moved, and exercises they created.
/// plan.json never changes; these apply on top of it. Renames and prescriptions are per exercise, in
/// `ExerciseOverrides`.
public struct PlanEdits: Codable, Hashable, Sendable {
    /// By dayKey: the day's exerciseIds in order, for the days the user changed.
    public var days: [String: [String]]
    /// Exercises the user created, by exerciseId.
    public var custom: [String: PlanItem]

    public init(days: [String: [String]] = [:], custom: [String: PlanItem] = [:]) {
        self.days = days
        self.custom = custom
    }

    public var isEmpty: Bool { days.isEmpty && custom.isEmpty }

    /// `plan` with the days' lists changed. An exercise from another day comes with that day's prescription;
    /// ids that no longer exist are left out.
    public func applied(to plan: Plan) -> Plan {
        guard !days.isEmpty else { return plan }
        let catalog = Self.catalog(plan: plan, custom: custom)
        var result = plan
        for index in result.days.indices {
            let day = result.days[index]
            guard let ids = days[day.key] else { continue }
            let own = Dictionary(day.items.map { ($0.exerciseId, $0) }, uniquingKeysWith: { first, _ in first })
            result.days[index].items = ids.compactMap { own[$0] ?? catalog[$0] }
        }
        return result
    }

    /// Every exercise there is, one per exerciseId: the plan's in plan order, then the user's own.
    public func library(plan: Plan) -> [PlanItem] {
        var seen = Set<String>()
        var items = plan.days.flatMap(\.items).filter { seen.insert($0.exerciseId).inserted }
        items += custom.values.sorted { $0.name < $1.name }.filter { seen.insert($0.exerciseId).inserted }
        return items
    }

    // MARK: Changing a day

    /// `day`'s exerciseIds as they stand. `day` is the plan's own, before edits.
    public func itemIds(for day: PlanDay) -> [String] {
        days[day.key] ?? day.items.map(\.exerciseId)
    }

    public mutating func remove(_ exerciseId: String, from day: PlanDay) {
        setItemIds(itemIds(for: day).filter { $0 != exerciseId }, for: day)
    }

    /// Moves by offsets in the day as shown (`applied(to:)`), which leaves out ids that no longer exist.
    public mutating func move(from source: IndexSet, to destination: Int, in day: PlanDay, plan: Plan) {
        var ids = liveItemIds(for: day, plan: plan)
        let moving = source.sorted().map { ids[$0] }
        let before = source.filter { $0 < destination }.count
        for index in source.sorted(by: >) { ids.remove(at: index) }
        ids.insert(contentsOf: moving, at: destination - before)
        setItemIds(ids, for: day)
    }

    /// Adds `item` to `day`, keeping its definition if it's one the user created. It goes after the day's last
    /// exercise, ahead of a trailing cooldown, unless `index` says where. Already there: nothing changes.
    public mutating func add(_ item: PlanItem, to day: PlanDay, at index: Int? = nil, plan: Plan) {
        var ids = liveItemIds(for: day, plan: plan)
        guard !ids.contains(item.exerciseId) else { return }
        if Self.catalog(plan: plan, custom: [:])[item.exerciseId] == nil {
            custom[item.exerciseId] = item
        }
        let catalog = Self.catalog(plan: plan, custom: custom)
        let own = Dictionary(day.items.map { ($0.exerciseId, $0) }, uniquingKeysWith: { first, _ in first })
        let lastExercise = ids.lastIndex { id in (own[id] ?? catalog[id]).map { $0.kind != .checklist } ?? false }
        let position = index ?? lastExercise.map { $0 + 1 } ?? ids.count
        ids.insert(item.exerciseId, at: min(max(position, 0), ids.count))
        setItemIds(ids, for: day)
    }

    /// Back to the plan's own list for `day`.
    public mutating func reset(_ day: PlanDay) {
        days[day.key] = nil
    }

    /// Whether `day`'s list differs from the plan's.
    public func isEdited(_ day: PlanDay) -> Bool {
        days[day.key] != nil
    }

    /// `day`'s ids that still resolve to an exercise, in order: the day as shown.
    private func liveItemIds(for day: PlanDay, plan: Plan) -> [String] {
        let catalog = Self.catalog(plan: plan, custom: custom)
        let own = Set(day.items.map(\.exerciseId))
        return itemIds(for: day).filter { own.contains($0) || catalog[$0] != nil }
    }

    /// Makes `ids` the day's list; the plan's own order clears the edit.
    public mutating func setItemIds(_ ids: [String], for day: PlanDay) {
        days[day.key] = ids == day.items.map(\.exerciseId) ? nil : ids
    }

    private static func catalog(plan: Plan, custom: [String: PlanItem]) -> [String: PlanItem] {
        var catalog: [String: PlanItem] = [:]
        for item in plan.days.flatMap(\.items) where catalog[item.exerciseId] == nil {
            catalog[item.exerciseId] = item
        }
        return catalog.merging(custom) { planned, _ in planned }
    }

    // MARK: Creating an exercise

    /// A new exercise's id: "custom-" and its name as a slug, made unique among `taken`.
    public static func newExerciseId(name: String, taken: Set<String>) -> String {
        let slug = String(name.lowercased().map { $0.isLetter || $0.isNumber ? $0 : "-" })
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        let base = "custom-" + (slug.isEmpty ? "exercise" : String(slug.prefix(40)))
        var id = base
        var suffix = 2
        while taken.contains(id) {
            id = "\(base)-\(suffix)"
            suffix += 1
        }
        return id
    }

    // MARK: Storage

    /// The edits stored in `context`, or none.
    public static func load(from context: ModelContext) -> PlanEdits {
        let rows = (try? context.fetch(FetchDescriptor<PlanEditsRecord>())) ?? []
        return rows.first.flatMap { try? JSONDecoder().decode(PlanEdits.self, from: $0.data) } ?? PlanEdits()
    }

    /// Stores these edits in `context`, replacing what was there. No edits, no row.
    public func save(to context: ModelContext) throws {
        let rows = try context.fetch(FetchDescriptor<PlanEditsRecord>())
        if isEmpty {
            rows.forEach(context.delete)
        } else {
            let data = try JSONEncoder().encode(self)
            if let row = rows.first {
                row.data = data
                rows.dropFirst().forEach(context.delete)
            } else {
                context.insert(PlanEditsRecord(data: data))
            }
        }
        try context.save()
    }
}
