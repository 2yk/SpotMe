import Foundation

/// The order of the Today list: what's up next, what's left, and what's finished.
public struct TodayQueue: Equatable, Sendable {
    /// The item to do next, or its whole superset group.
    public var upNext: [PlanItem]
    /// The other open items, in plan order.
    public var remaining: [PlanItem]
    /// Done and skipped items, in the order they were finished.
    public var finished: [PlanItem]

    /// - Parameters:
    ///   - statuses: by exerciseId; items without one are pending.
    ///   - promoted: an item the user tapped to do next, e.g. because a machine is busy.
    public init(items: [PlanItem], statuses: [String: ItemStatus], promoted: String? = nil) {
        func status(_ item: PlanItem) -> ItemStatus { statuses[item.exerciseId] ?? .pending }
        let open = items.filter { !status($0).isFinished }

        let lead = open.first { $0.exerciseId == promoted }
            ?? open.first { if case .inProgress = status($0) { true } else { false } }
            ?? open.first
        if let group = lead?.supersetGroup {
            upNext = open.filter { $0.supersetGroup == group }
        } else {
            upNext = lead.map { [$0] } ?? []
        }
        let upNextIds = Set(upNext.map(\.exerciseId))
        remaining = open.filter { !upNextIds.contains($0.exerciseId) }

        let order = Dictionary(uniqueKeysWithValues: items.enumerated().map { ($1.exerciseId, $0) })
        finished = items
            .filter { status($0).isFinished }
            .sorted {
                let (a, b) = (status($0).finishedAt!, status($1).finishedAt!)
                return a != b ? a < b : order[$0.exerciseId]! < order[$1.exerciseId]!
            }
    }

    public var doneCount: Int { finished.count }
    public var totalCount: Int { upNext.count + remaining.count + finished.count }
    public var isComplete: Bool { upNext.isEmpty && totalCount > 0 }
}
