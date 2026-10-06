import SwiftUI
import RepCoachCore

/// Weight and reps for one set. Tap a value and the Digital Crown changes it, one step per click.
struct SetView: View {
    @Environment(WorkoutModel.self) private var workout
    @Environment(TodayModel.self) private var today
    @Bindable var flow: ExerciseFlow
    @FocusState private var focus: Field?

    enum Field: Hashable {
        case weight, reps
    }

    var body: some View {
        let item = flow.currentItem
        let takesWeight = item.takesWeight
        VStack(alignment: .leading, spacing: 0) {
            // The name and its hints line up inside the tiles' corners.
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .role(.title)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if today.isDeload {
                    Text("Deload")
                        .role(.eyebrow, .black)
                        .padding(.horizontal, pt(5))
                        .padding(.vertical, pt(1))
                        .background(Capsule().fill(Theme.ember))
                        .padding(.top, pt(2))
                }
                SetHintRow(flow: flow)
                    .padding(.top, pt(1))
                if let partner = partnerName {
                    Text("Superset · then \(partner)")
                        .role(.small, Theme.ice)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, pt(1))
                }
            }
            .padding(.horizontal, pt(4))

            HStack(spacing: pt(6)) {
                if takesWeight {
                    CrownValue(value: $flow.weight, step: flow.increment, range: 0...500, unit: "kg",
                               focus: $focus, field: .weight, format: Format.weight)
                }
                CrownValue(value: $flow.reps, step: 1, range: 0...200,
                           unit: item.perSide == true ? "reps/side" : "reps", wide: !takesWeight,
                           focus: $focus, field: .reps, format: { "\(Int($0.rounded()))" })
            }
            .frame(maxHeight: .infinity)
            .padding(.top, pt(6))

            Button("Log set") { withAnimation(.snappy) { flow.logSet() } }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, pt(6))
        }
        .screenColumn()
        // A new set starts on fresh rows, so the Crown never carries over from the last one.
        .id(flow.stepIndex)
        .onAppear {
            focus = flow.needsStartingWeight ? .weight : .reps
            #if DEBUG
            // `-focus weight`: the Crown on the weight, for the board that shows it.
            if UserDefaults.standard.string(forKey: "focus") == "weight" { focus = .weight }
            #endif
        }
        .onChange(of: flow.stepIndex) {
            focus = flow.needsStartingWeight ? .weight : .reps
        }
    }

    /// The other exercise of a superset pair.
    private var partnerName: String? {
        guard flow.isSuperset, let step = flow.current else { return nil }
        return flow.items[(step.item + 1) % flow.items.count].name
    }
}

/// One number. Tap it and the Digital Crown moves it one step per click (the exercise's increment, or one rep),
/// counting from wherever it is, so it never jumps to an in-between or rounded value. The focused tile is the
/// one the Crown moves: volt outline, volt unit.
struct CrownValue: View {
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    let unit: String
    /// A single tile across the whole width.
    var wide = false
    var focus: FocusState<SetView.Field?>.Binding
    let field: SetView.Field
    let format: (Double) -> String

    /// The value the Crown counts from, and how many clicks it has turned since.
    @State private var anchor: Double?
    @State private var clicks = 0.0

    var body: some View {
        let focused = focus.wrappedValue == field
        let text = format(value)
        let shape = RoundedRectangle(cornerRadius: pt(17), style: .continuous)
        VStack(spacing: pt(1)) {
            Text(text)
                .role(wide ? .valueWide : text.count >= 5 ? .valueSmall : .value, single: true)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(unit).role(.eyebrow, focused ? Theme.volt : Theme.text3, single: true)
        }
        .padding(.horizontal, pt(4))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shape.fill(focused ? Theme.volt.opacity(0.16) : Theme.card))
        .overlay(shape.strokeBorder(focused ? Theme.volt : Theme.line, lineWidth: focused ? pt(2) : pt(1)))
        .contentShape(shape)
        .focusable()
        .focused(focus, equals: field)
        .focusEffectDisabled()
        // Whole clicks only, from the anchor: one step per click with a haptic, never between steps.
        .digitalCrownRotation(detent: $clicks, from: ((range.lowerBound - (anchor ?? value)) / step).rounded(.up),
                              through: ((range.upperBound - (anchor ?? value)) / step).rounded(.down), by: 1,
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
        .accessibilityValue("\(text) \(unit)")
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

/// Under the exercise's name: the range on the left; on the right what to beat, "Last 9", or "First time" in volt.
/// Paused, the left side also says which set this is and the right side is empty.
struct SetHintRow: View {
    @Environment(WorkoutModel.self) private var workout
    @Environment(TodayModel.self) private var today
    let flow: ExerciseFlow

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: pt(6)) {
            Text(workout.isPaused ? "Set \(flow.current?.set ?? 1) of \(flow.currentTarget.sets) · \(hint)" : hint)
                .role(.detail, Theme.text2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            if !workout.isPaused { trailing }
        }
    }

    @ViewBuilder
    private var trailing: some View {
        let item = flow.currentItem
        if item.kind == .percentOfMax || today.isDeload {
            EmptyView()
        } else if flow.needsStartingWeight || !flow.hasHistory {
            Text("First time").role(.detail.weight(.bold), Theme.volt)
        } else if let last = flow.lastTimeValue {
            HStack(spacing: pt(3)) {
                Text("Last").role(.detail, Theme.text2)
                Text("\(last)\(item.kind == .timed ? "s" : "")").role(.detail.weight(.bold))
            }
            .lineLimit(1)
        }
    }

    /// The left hint: "6–10 reps", "10/side", "30–45s", "Strict, all out", "60% of 12".
    private var hint: String {
        let item = flow.currentItem
        let target = flow.currentTarget
        switch item.kind {
        case .amrap: return "Strict, all out"
        case .percentOfMax: return target.amrap.map { "60% of \($0)" } ?? ""
        default:
            guard let perSet = Format.perSet(item, target) else { return "" }
            return item.kind == .timed || item.perSide == true ? perSet : "\(perSet) reps"
        }
    }
}
