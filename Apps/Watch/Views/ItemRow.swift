import SwiftUI
import RepCoachCore

/// One row of the Today list. Finished items are dimmed with a checkmark.
struct ItemRow: View {
    @Environment(TodayModel.self) private var today
    let item: PlanItem

    var body: some View {
        let status = today.status(of: item)
        HStack(spacing: 9) {
            ItemBadge(item: item, status: status)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.rounded(.body, .medium))
                    .foregroundStyle(status.isFinished ? Theme.secondary : .white)
                    .lineLimit(2)
                Text(today.detailLine(for: item))
                    .font(.rounded(.footnote))
                    .foregroundStyle(status.isFinished ? Theme.tertiary : Theme.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .opacity(status.isFinished ? 0.75 : 1)
    }
}
