import SwiftUI
import RepCoachCore

/// Weight and reps for one set. Tap a value and the Digital Crown changes it, one step per click.
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
        GeometryReader { geometry in
            // The values take what's left under the header and above Log set: bigger on bigger watches.
            let rows: CGFloat = takesWeight ? 2 : 1
            let room = (geometry.size.height - 18 - 40 - 4 * (rows + 1)) / rows
            let height = min(takesWeight ? 52 : 66, max(34, room))
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
                    CrownValue(value: $flow.weight, step: flow.increment, range: 0...500, unit: "kg",
                               tint: item.tint, height: height, focus: $focus, field: .weight, format: Format.weight)
                }
                CrownValue(value: $flow.reps, step: 1, range: 0...200,
                           unit: item.perSide == true ? "reps/side" : "reps", tint: item.tint, height: height,
                           focus: $focus, field: .reps, format: { "\(Int($0.rounded()))" })
                Button("Log set") { withAnimation(.snappy) { flow.logSet() } }
                    .buttonStyle(PrimaryButtonStyle(tint: item.tint, height: 40))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

/// One number. Tap it and the Digital Crown moves it one step per click (the exercise's increment, or one rep),
/// counting from wherever it is, so it never jumps to an in-between or rounded value.
struct CrownValue: View {
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    let unit: String
    let tint: Color
    var height: CGFloat = 46
    var focus: FocusState<SetView.Field?>.Binding
    let field: SetView.Field
    let format: (Double) -> String

    /// The value the Crown counts from, and how many clicks it has turned since.
    @State private var anchor: Double?
    @State private var clicks = 0.0

    var body: some View {
        let focused = focus.wrappedValue == field
        let base = anchor ?? value
        let shape = RoundedRectangle(cornerRadius: height / 2, style: .continuous)
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(format(value))
                .font(.number(height * 0.7))
                .monospacedDigit()
            Text(unit)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(focused ? tint : Theme.tertiary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(shape.fill(focused ? tint.opacity(0.16) : Theme.card))
        .overlay(shape.strokeBorder(focused ? tint : Theme.hairline, lineWidth: focused ? 2 : 1))
        .contentShape(shape)
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
        // Changed another way (a new set, VoiceOver): the Crown counts from the new value.
        .onChange(of: value) {
            guard let anchor, Self.tidy(anchor + clicks * step) != value else { return }
            self.anchor = nil
            clicks = 0
        }
        .onTapGesture { focus.wrappedValue = field }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(field == .weight ? "Weight" : "Reps")
        .accessibilityValue("\(format(value)) \(unit)")
        .accessibilityIdentifier(field == .weight ? "weight-value" : "reps-value")
        .accessibilityAdjustableAction { direction in
            change(by: direction == .increment ? 1 : -1)
        }
    }

    /// VoiceOver's swipe up or down: one step.
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
