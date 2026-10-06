import SwiftUI
import RepCoachCore

/// One row of the Today list: the name, the prescription on the left and today's target weight on the right.
/// Finished items are dimmed with a check.
struct ItemRow: View {
    @Environment(TodayModel.self) private var today
    let item: PlanItem

    var body: some View {
        let info = today.rowInfo(for: item)
        VStack(alignment: .leading, spacing: pt(1)) {
            Text(item.name)
                .role(info.isFinished ? TextRole.row.weight(.medium) : .row, info.isFinished ? Theme.text2 : .white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: pt(6)) {
                Text(info.detail)
                    .role(.detail, info.detailColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(info.detailLines)
                    .fixedSize(horizontal: false, vertical: info.detailLines > 1)
                Spacer(minLength: 0)
                if info.isFinished, !info.isSkipped {
                    Image(systemName: "checkmark")
                        .font(.system(size: pt(13), weight: .heavy))
                        .foregroundStyle(Theme.mint)
                } else {
                    RowWeight(info: info)
                }
            }
        }
        .padding(EdgeInsets(top: pt(7), leading: pt(10), bottom: pt(8), trailing: pt(10)))
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface()
        .contentShape(Rectangle())
    }
}
