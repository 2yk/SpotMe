import SwiftUI
import RepCoachCore

/// What one line of Today (and the break's target line) shows for an item.
struct RowInfo: Equatable {
    enum Arrow { case up, down }

    /// Left: the prescription, or where the item stands.
    var detail: String
    var detailColor: Color
    /// Right: today's target weight, for items that take one.
    var weight: String?
    /// Up when today's target is above the last working weight, down when it is lower or a deload. These come
    /// from the engine's own reason for the target; nothing is worked out here.
    var arrow: Arrow?
    var isFinished: Bool
    var isSkipped: Bool
    /// Lines the detail may take: a tick-off item's note runs to several.
    var detailLines = 1
    /// Swapped in for today: the row shows the swap icon before its prescription.
    var isSwapped = false
    /// Swapped in with no history of its own: "First time" on the right, no weight yet.
    var isFirstTime = false
}

extension TodayModel {
    func rowInfo(for item: PlanItem) -> RowInfo {
        var info = plainRowInfo(for: item)
        if isSwapped(item) {
            info.isSwapped = true
            info.isFirstTime = !info.isFinished && info.weight == nil && pastSessions(of: item.exerciseId).isEmpty
        }
        return info
    }

    private func plainRowInfo(for item: PlanItem) -> RowInfo {
        let target = target(for: item)
        let status = status(of: item)
        let weight = item.takesWeight ? target.weight.flatMap { $0 > 0 ? Format.kg($0) : nil } : nil
        switch status {
        case .skipped:
            return RowInfo(detail: "Skipped · tap to do it", detailColor: Theme.text3, weight: nil, arrow: nil,
                           isFinished: true, isSkipped: true)
        case .done:
            let sets = log(for: item)?.orderedCountedSets ?? []
            let top = sets.map(\.weight).max() ?? 0
            let count = "\(sets.count) set\(sets.count == 1 ? "" : "s")"
            let detail = sets.isEmpty ? "Done"
                : item.takesWeight && top > 0 ? "\(count) · \(Format.kg(top))" : count
            return RowInfo(detail: detail, detailColor: Theme.text3, weight: nil, arrow: nil,
                           isFinished: true, isSkipped: false)
        case .inProgress(let done):
            if isWaiting(item) {
                return RowInfo(detail: "\(done) of \(target.sets) sets · waiting", detailColor: Theme.ice,
                               weight: weight, arrow: arrow(target), isFinished: false, isSkipped: false)
            }
            return RowInfo(detail: "Set \(done + 1) of \(target.sets) · in progress", detailColor: Theme.volt,
                           weight: weight, arrow: arrow(target), isFinished: false, isSkipped: false)
        case .pending:
            var info = RowInfo(detail: Format.prescription(item, target), detailColor: Theme.text2, weight: weight,
                               arrow: arrow(target), isFinished: false, isSkipped: false)
            if item.kind == .checklist, ["", "—"].contains(item.display ?? ""), let note = item.note {
                info.detail = note
                info.detailLines = 4
            }
            if isWaiting(item) {
                info.detail += " · waiting"
                info.detailColor = Theme.ice
            }
            return info
        }
    }

    /// Where a waiting exercise picks up: "Set 2 of 3 · 17.5 kg", the weight the engine's next set asks for.
    func resumeLine(for item: PlanItem) -> String {
        let target = target(for: item)
        let sets = log(for: item)?.orderedCountedSets.map(\.loggedSet) ?? []
        var parts = ["Set \(sets.count + 1) of \(target.sets)"]
        if item.takesWeight {
            var weight = target.weight
            if item.kind == .weighted, let last = sets.last, let p = Prescription(item: item) {
                weight = ProgressionEngine.nextSet(for: p, weight: last.weight, reps: last.reps, setIndex: sets.count,
                                                   totalSets: target.sets).weight
            } else if let last = sets.last {
                weight = last.weight
            }
            if let weight, weight > 0 { parts.append(Format.kg(weight)) }
        }
        return parts.joined(separator: " · ")
    }

    private func arrow(_ target: ItemTarget) -> RowInfo.Arrow? {
        switch target.session?.reason {
        case .increase: .up
        case .decrease, .deload: .down
        default: nil
        }
    }
}

/// A target weight on the right of a row, with its arrow: "↑ 45 kg".
struct RowWeight: View {
    let info: RowInfo
    var size: CGFloat = 13

    var body: some View {
        if let weight = info.weight {
            HStack(spacing: pt(2)) {
                if let arrow = info.arrow {
                    Image(systemName: arrow == .up ? "arrow.up" : "arrow.down")
                        .font(.system(size: pt(size - 2), weight: .bold))
                        .foregroundStyle(arrow == .up ? Theme.volt : Theme.ember)
                }
                Text(weight).role(TextRole(size: size, line: size + 2, weight: .bold))
            }
            .lineLimit(1)
            .fixedSize()
        }
    }
}

extension ItemStatus {
    /// Dropped for the day, as against done.
    var isSkipped: Bool {
        if case .skipped = self { true } else { false }
    }
}
