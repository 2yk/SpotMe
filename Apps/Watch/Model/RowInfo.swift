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
}

extension TodayModel {
    func rowInfo(for item: PlanItem) -> RowInfo {
        let target = target(for: item)
        let status = status(of: item)
        let weight = item.takesWeight ? target.weight.flatMap { $0 > 0 ? Format.kg($0) : nil } : nil
        switch status {
        case .skipped:
            return RowInfo(detail: "Skipped", detailColor: Theme.text3, weight: nil, arrow: nil,
                           isFinished: true, isSkipped: true)
        case .done:
            let sets = log(for: item)?.orderedSets ?? []
            let top = sets.map(\.weight).max() ?? 0
            let detail = sets.isEmpty ? "Done"
                : item.takesWeight && top > 0 ? "\(sets.count) sets · \(Format.kg(top))" : "\(sets.count) sets"
            return RowInfo(detail: detail, detailColor: Theme.text3, weight: nil, arrow: nil,
                           isFinished: true, isSkipped: false)
        case .inProgress(let done):
            return RowInfo(detail: "Set \(done + 1) of \(target.sets) · in progress", detailColor: Theme.volt,
                           weight: weight, arrow: arrow(target), isFinished: false, isSkipped: false)
        case .pending:
            var info = RowInfo(detail: Format.prescription(item, target), detailColor: Theme.text2, weight: weight,
                               arrow: arrow(target), isFinished: false, isSkipped: false)
            if item.kind == .checklist, ["", "—"].contains(item.display ?? ""), let note = item.note {
                info.detail = note
                info.detailLines = 4
            }
            return info
        }
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
