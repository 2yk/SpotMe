import SwiftUI
import RepCoachCore

/// Weight and reps for one set. Tap a value to focus it; the Digital Crown changes it.
struct SetView: View {
    @Bindable var flow: ExerciseFlow
    @FocusState private var focus: Field?

    enum Field: Hashable {
        case weight, reps
    }

    var body: some View {
        let item = flow.currentItem
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(setLabel).eyebrow(item.tint)
                Spacer(minLength: 4)
                Text(hint)
                    .font(.rounded(.footnote, .semibold))
                    .foregroundStyle(flow.needsStartingWeight ? item.tint : Theme.secondary)
                    .lineLimit(1)
            }
            HStack(spacing: 6) {
                if item.takesWeight {
                    ValueTile(value: Format.weight(flow.weight), unit: "kg", tint: item.tint,
                              focused: focus == .weight)
                        .focusable()
                        .focused($focus, equals: .weight)
                        .focusEffectDisabled()
                        // Detents only: the value moves a whole increment per click, never in between.
                        .digitalCrownRotation(detent: $flow.weight, from: 0, through: 400, by: flow.increment,
                                              sensitivity: .low, isContinuous: false,
                                              isHapticFeedbackEnabled: true)
                        .onTapGesture { focus = .weight }
                }
                ValueTile(value: "\(Int(flow.reps.rounded()))", unit: item.perSide == true ? "reps/side" : "reps",
                          tint: item.tint, focused: focus == .reps)
                    .focusable()
                    .focused($focus, equals: .reps)
                    .focusEffectDisabled()
                    .digitalCrownRotation(detent: $flow.reps, from: 0, through: 100, by: 1, sensitivity: .low,
                                          isContinuous: false, isHapticFeedbackEnabled: true)
                    .onTapGesture { focus = .reps }
            }
            Button("Log set") { withAnimation(.snappy) { flow.logSet() } }
                .buttonStyle(PrimaryButtonStyle(tint: item.tint))
        }
        .padding(.horizontal, 2)
        .onAppear { focus = flow.needsStartingWeight ? .weight : .reps }
        .onChange(of: flow.stepIndex) {
            focus = flow.needsStartingWeight ? .weight : .reps
        }
    }

    private var setLabel: String {
        guard let step = flow.current else { return "" }
        if flow.currentItem.kind == .amrap { return "Max reps" }
        return "Set \(step.set) of \(flow.currentTarget.sets)"
    }

    private var hint: String {
        let item = flow.currentItem
        let target = flow.currentTarget
        if flow.needsStartingWeight { return "First time" }
        switch item.kind {
        case .amrap: return "Strict, all out"
        case .percentOfMax: return target.amrap.map { "60% of \($0)" } ?? ""
        default: return Format.perSet(item, target) ?? ""
        }
    }
}

/// A big number with its unit; lit up while the Digital Crown controls it.
struct ValueTile: View {
    let value: String
    let unit: String
    let tint: Color
    let focused: Bool

    var body: some View {
        VStack(spacing: -2) {
            Text(value)
                .font(.number(36))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
            Text(unit)
                .eyebrow(focused ? tint : Theme.tertiary, size: 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(focused ? tint.opacity(0.16) : Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(focused ? tint : Theme.hairline, lineWidth: focused ? 2 : 1)
        )
        .animation(.snappy(duration: 0.2), value: value)
    }
}
