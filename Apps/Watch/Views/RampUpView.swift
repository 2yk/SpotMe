import SwiftUI
import RepCoachCore

/// A ramp-up set: a lighter, shorter set before the first working set. Tapped off, not entered; never counted.
/// Skip drops the rest of them for this exercise and opens set 1.
struct RampUpView: View {
    @Bindable var flow: ExerciseFlow
    let step: ExerciseFlow.RampStep

    var body: some View {
        let item = flow.items[step.item]
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .role(.title)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .firstTextBaseline, spacing: pt(6)) {
                    Text("\(step.number) of \(step.of) · not counted")
                        .role(.detail, Theme.text2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                    Button { withAnimation(.snappy) { flow.skipRampUps() } } label: {
                        Text("Skip").role(.detail.weight(.semibold), .white)
                            .frame(minHeight: pt(30))
                            .padding(.leading, pt(8))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Skip the ramp-up")
                }
                .padding(.top, pt(1))
            }
            .padding(.horizontal, pt(4))

            VStack(spacing: pt(2)) {
                Text(setText)
                    .role(TextRole(size: 32, line: 34, weight: .bold), .white, single: true)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("Working weight \(flow.workingWeightLabel(forItem: step.item))")
                    .role(.eyebrow, Theme.text3, single: true)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, pt(6))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: pt(17), style: .continuous).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: pt(17), style: .continuous)
                .strokeBorder(Theme.line, lineWidth: pt(1)))
            .padding(.top, pt(6))
            .accessibilityElement(children: .combine)

            Button("Done") { withAnimation(.snappy) { flow.doneRampUp() } }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, pt(6))
        }
        .screenColumn()
    }

    /// "10 kg × 8", "BW × 5" for the bodyweight set, "+7.5 kg × 3" for the weighted one.
    private var setText: String {
        if step.bodyweight { return "BW × \(step.reps)" }
        let weight = Format.kg(step.weight)
        return "\(flow.items[step.item].bodyweightBase == true ? "+" : "")\(weight) × \(step.reps)"
    }
}
