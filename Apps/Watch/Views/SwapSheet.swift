import SwiftUI
import RepCoachCore

/// Swap: the exercises that can take `item`'s place for today, from the database's alternatives, each with why
/// it fits. One tap picks it. Leaves out anything the user's injury areas rule out and flags "take care".
struct SwapSheet: View {
    @Environment(TodayModel.self) private var today
    let item: PlanItem
    let onPick: (SwapChoice) -> Void

    var body: some View {
        let slot = today.slot(of: item)
        ScrollView {
            VStack(spacing: pt(4)) {
                Text("Instead of \(item.name)")
                    .role(.small.weight(.medium), Theme.text3)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, pt(6))
                ForEach(today.swapChoices(for: item)) { choice in
                    Button { onPick(choice) } label: { row(choice) }
                        .buttonStyle(RowButtonStyle())
                }
                Text("Today only. It takes these sets and reps and keeps its own weights.")
                    .role(.small.weight(.medium), Theme.text3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, pt(6))
                    .padding(.top, pt(4))
                    .accessibilityHint(slot.exerciseId == item.exerciseId ? "" : "Swapped from \(slot.name)")
            }
            .padding(.horizontal, Metrics.side)
            .padding(.top, Metrics.sheetTop)
            .padding(.bottom, Metrics.bottom)
        }
        .ignoresSafeArea()
        .topFade()
        .barTitle("Swap", close: true)
    }

    private func row(_ choice: SwapChoice) -> some View {
        VStack(alignment: .leading, spacing: pt(1)) {
            Text(choice.name)
                .role(.row)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(choice.why)
                .role(.small.weight(.medium), Theme.text2)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if choice.takeCare {
                Text("Take care")
                    .role(.eyebrow, .black)
                    .padding(.horizontal, pt(5))
                    .padding(.vertical, pt(1))
                    .background(Capsule().fill(Theme.ember))
                    .padding(.top, pt(2))
            }
        }
        .padding(EdgeInsets(top: pt(7), leading: pt(10), bottom: pt(8), trailing: pt(10)))
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface()
        .contentShape(Rectangle())
    }
}
