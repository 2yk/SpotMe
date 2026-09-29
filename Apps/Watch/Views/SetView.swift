import SwiftUI
import RepCoachCore

/// Weight and reps for one set. − and + change a value by exactly one step; tap a value and the Digital Crown
/// changes it too, one step per click.
struct SetView: View {
    @Environment(WorkoutModel.self) private var workout
    @Bindable var flow: ExerciseFlow
    @FocusState private var focus: Field?

    enum Field: Hashable {
        case weight, reps
    }

    var body: some View {
        let item = flow.currentItem
        let takesWeight = item.takesWeight
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(setLabel).eyebrow(item.tint)
                Spacer(minLength: 4)
                Text(workout.isPaused ? "Paused" : hint)
                    .font(.rounded(.footnote, .semibold))
                    .foregroundStyle(workout.isPaused ? Theme.amber
                        : flow.needsStartingWeight ? item.tint : Theme.secondary)
                    .lineLimit(1)
            }
            if takesWeight {
                StepperRow(value: $flow.weight, step: flow.increment, range: 0...500, unit: "kg",
                           tint: item.tint, height: 40, focus: $focus, field: .weight, format: Format.weight)
            }
            StepperRow(value: $flow.reps, step: 1, range: 0...200, unit: item.perSide == true ? "reps/side" : "reps",
                       tint: item.tint, height: takesWeight ? 40 : 56, focus: $focus, field: .reps,
                       format: { "\(Int($0.rounded()))" })
            Button("Log set") { withAnimation(.snappy) { flow.logSet() } }
                .buttonStyle(PrimaryButtonStyle(tint: item.tint, height: 40))
        }
        .padding(.horizontal, 2)
        // A new set starts on fresh rows, so the Crown never carries over from the last one.
        .id(flow.stepIndex)
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

/// One number with − and + either side. While it's focused (tap it) the Digital Crown moves it one step per
/// click, counting from wherever it is, so it never jumps to an in-between or rounded value.
struct StepperRow: View {
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    let unit: String
    let tint: Color
    var height: CGFloat = 44
    var focus: FocusState<SetView.Field?>.Binding
    let field: SetView.Field
    let format: (Double) -> String

    /// The value the Crown counts from, and how many clicks it has turned since.
    @State private var anchor: Double?
    @State private var clicks = 0.0

    var body: some View {
        let focused = focus.wrappedValue == field
        let base = anchor ?? value
        HStack(spacing: 0) {
            StepButton(symbol: "minus", tint: tint, size: height - 10) { change(by: -1) }
                .disabled(value - step < range.lowerBound - 0.001)
                .accessibilityLabel(field == .weight ? "Less weight" : "Fewer reps")
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(format(value))
                    .font(.number(height * 0.64))
                    .monospacedDigit()
                Text(unit)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(focused ? tint : Theme.tertiary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { focus.wrappedValue = field }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(field == .weight ? "Weight" : "Reps")
            .accessibilityValue("\(format(value)) \(unit)")
            .accessibilityIdentifier(field == .weight ? "weight-value" : "reps-value")
            .accessibilityAdjustableAction { direction in
                change(by: direction == .increment ? 1 : -1)
            }
            StepButton(symbol: "plus", tint: tint, size: height - 10) { change(by: 1) }
                .disabled(value + step > range.upperBound + 0.001)
                .accessibilityLabel(field == .weight ? "More weight" : "More reps")
        }
        .padding(.horizontal, 5)
        .frame(height: height)
        .background(RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(focused ? tint.opacity(0.16) : Theme.card))
        .overlay(RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .strokeBorder(focused ? tint : Theme.hairline, lineWidth: focused ? 2 : 1))
        .focusable()
        .focused(focus, equals: field)
        .focusEffectDisabled()
        // Whole clicks only, from the anchor: one step per click with a haptic, never between steps.
        .digitalCrownRotation(detent: $clicks, from: ((range.lowerBound - base) / step).rounded(.up),
                              through: ((range.upperBound - base) / step).rounded(.down), by: 1,
                              sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
        .onChange(of: clicks) {
            let base = anchor ?? value
            anchor = base
            value = Self.tidy(base + clicks * step)
        }
        // Changed another way (− or +, a new set): the Crown counts from the new value.
        .onChange(of: value) {
            guard let anchor, Self.tidy(anchor + clicks * step) != value else { return }
            self.anchor = nil
            clicks = 0
        }
        .accessibilityElement(children: .contain)
    }

    private func change(by steps: Double) {
        focus.wrappedValue = field
        let next = Self.tidy(value + steps * step)
        guard range.contains(next) else { return }
        value = next
        Haptics.play(.step)
    }

    /// Two decimals, so steps like 1.25 add up exactly.
    private static func tidy(_ x: Double) -> Double {
        (x * 100).rounded() / 100
    }
}

/// A round − or + inside a value row.
private struct StepButton: View {
    let symbol: String
    let tint: Color
    let size: CGFloat
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .heavy))
                .foregroundStyle(isEnabled ? tint : Theme.tertiary)
                .frame(width: size, height: size)
                .background(Circle().fill(Theme.cardRaised))
        }
        .buttonStyle(.plain)
    }
}
