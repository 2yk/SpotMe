import SwiftUI
import RepCoachCore

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
