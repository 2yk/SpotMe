import SwiftUI
import RepCoachCore

// The form groups of look B (design/reviews/2-iphone.md "Form group", worn in the cards of 10-look-b-today.md):
// Settings, the plan editors and their sheets. A group is an eyebrow, one gradient card of rows 52 pt high with a
// line between them, and footnotes under it. The names start with "Spot" so they stay clear of the kit's.

/// A titled card of rows, with footnotes under it. Rows are separated by an inset line.
struct SpotFormGroup<Content: View>: View {
    var title: String?
    var footnotes: [String] = []
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title)
                    .depthEyebrow()
                    .padding(.leading, 6)
                    .padding(.bottom, 8)
            }
            VStack(spacing: 0) {
                Group(subviews: content) { subviews in
                    ForEach(subviews) { subview in
                        subview
                        if subview.id != subviews.last?.id { DepthDivider(inset: 16) }
                    }
                }
            }
            .depthRows()
            if !footnotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(footnotes, id: \.self) { Text($0) }
                }
                .font(PhoneFont.foot)
                .foregroundStyle(Theme.text3)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A row: its label on the left, whatever goes at the right edge.
struct SpotRow<Trailing: View>: View {
    let title: String
    var gap: CGFloat = 12
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: gap) {
            Text(title)
                .font(PhoneFont.body)
                .lineLimit(2)
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
    }
}

/// The value at a row's right edge: white where it can be changed here, volt where it differs from the plan,
/// `Theme.text2` for information only.
struct SpotValue: View {
    let text: String
    var color: Color = .white
    var weight: Font.Weight = .medium

    var body: some View {
        Text(text)
            .font(.system(size: 17, weight: weight, design: .rounded))
            .foregroundStyle(color)
            .monospacedDigit()
            .lineLimit(1)
    }
}

/// A row with a switch.
struct SpotSwitchRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title).font(PhoneFont.body).lineLimit(2)
        }
        .tint(Theme.volt)
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
    }
}

/// A row that does something: volt text (red for removing), an optional icon at the right edge.
struct SpotActionRow: View {
    let title: String
    var color: Color = Theme.volt
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) { SpotActionLabel(title: title, color: color, icon: icon) }
            .buttonStyle(RowPressStyle())
    }
}

/// The inside of an action row, for a `ShareLink` or any other button that draws it.
struct SpotActionLabel: View {
    let title: String
    var color: Color = Theme.volt
    var icon: String?

    var body: some View {
        HStack(spacing: 12) {
            Text(title).font(PhoneFont.body).foregroundStyle(color)
            Spacer(minLength: 8)
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(color)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// A row whose value is picked from a menu: "Reps ⌄".
struct SpotMenuRow<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [(value: Value, title: String)]
    var highlighted = false

    var body: some View {
        Menu {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.value) { Text($0.title).tag($0.value) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(title).font(PhoneFont.body).foregroundStyle(.white)
                Spacer(minLength: 8)
                SpotValue(text: options.first { $0.value == selection }?.title ?? "",
                          color: highlighted ? Theme.volt : .white, weight: highlighted ? .semibold : .medium)
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.text2)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(RowPressStyle())
        .accessibilityValue(options.first { $0.value == selection }?.title ?? "")
    }
}

/// A row with a text field in it. Typed text is white, the prompt `Theme.text3`.
struct SpotTextRow: View {
    let prompt: String
    @Binding var text: String
    var capitalization: TextInputAutocapitalization = .words
    var focus: FocusState<Bool>.Binding?
    var onSubmit: (() -> Void)?

    var body: some View {
        field
            .font(PhoneFont.body)
            .textInputAutocapitalization(capitalization)
            .submitLabel(.done)
            .onSubmit { onSubmit?() }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
    }

    @ViewBuilder
    private var field: some View {
        let field = TextField("", text: $text, prompt: Text(prompt).foregroundStyle(Theme.text3))
        if let focus {
            field.focused(focus)
        } else {
            field
        }
    }
}

// MARK: Steppers

/// The 94 × 32 stepper of the boards: a raised capsule split by a hairline, minus and plus. Holding a side repeats.
struct SpotStepper: View {
    var decrementLabel = "Decrease"
    var incrementLabel = "Increase"
    var canDecrement = true
    var canIncrement = true
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            side("minus", decrementLabel, enabled: canDecrement, action: decrement)
            Rectangle().fill(Color.white.opacity(0.16)).frame(width: 1, height: 18)
            side("plus", incrementLabel, enabled: canIncrement, action: increment)
        }
        .frame(width: 94, height: 32)
        .background(Capsule().fill(Theme.raised))
        .clipShape(Capsule())
    }

    private func side(_ symbol: String, _ label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .opacity(enabled ? 1 : 0.3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(StepperSideStyle())
        .buttonRepeatBehavior(.enabled)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

private struct StepperSideStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(Color.white.opacity(configuration.isPressed ? 0.12 : 0))
    }
}

/// "Sets  plan 4  5  [− +]": a number the stepper changes. The value is volt when it differs from the plan; "plan 4"
/// then shows what the plan has. The value sits in a 36 pt right-aligned slot so the steppers line up.
struct SpotStepperRow<Value: Comparable & AdditiveArithmetic>: View {
    let title: String
    @Binding var value: Value
    let range: ClosedRange<Value>
    let step: Value
    /// What the value looks like: "5", "2:30", "52.5 kg".
    let text: (Value) -> String
    /// The plan's value, as text; nil when there is no plan value to compare with.
    var plan: String?
    var decrementLabel = "Decrease"
    var incrementLabel = "Increase"
    /// Shown instead of a number when there is none yet ("Not set").
    var placeholder: String?

    var body: some View {
        let shown = text(value)
        let edited = plan != nil && plan != shown
        SpotRow(title: title) {
            if edited, let plan {
                Text("plan \(plan)").font(PhoneFont.foot).foregroundStyle(Theme.text3)
            }
            if let placeholder {
                SpotValue(text: placeholder, color: Theme.text2)
            } else {
                SpotValue(text: shown, color: edited ? Theme.volt : .white, weight: edited ? .semibold : .medium)
                    .frame(minWidth: 36, alignment: .trailing)
            }
            SpotStepper(decrementLabel: decrementLabel, incrementLabel: incrementLabel,
                        canDecrement: value > range.lowerBound, canIncrement: value < range.upperBound,
                        decrement: { value = max(range.lowerBound, value - step) },
                        increment: { value = min(range.upperBound, value + step) })
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: Segmented control

/// Two or three equal halves in a capsule: "New exercise | From the plan".
struct SpotSegmented<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, title: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                let selected = option.value == selection
                Button {
                    withAnimation(.snappy(duration: 0.2)) { selection = option.value }
                } label: {
                    Text(option.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            if selected { Capsule().fill(Color(hex: 0x3A3A3C)) }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(2)
        .frame(height: 36)
        .background(Capsule().fill(Color(hex: 0x1C1C1E)))
    }
}

// MARK: Sheet bar

/// The top bar of a sheet with actions: "Cancel", the title, and the action at the right (bold). It sits 20 pt
/// below the top of the sheet; the content starts at 76.
struct SpotSheetBar: View {
    let title: String
    var leading = "Cancel"
    var trailing: String?
    var trailingEnabled = true
    let onLeading: () -> Void
    var onTrailing: () -> Void = {}

    var body: some View {
        ZStack {
            Text(title)
                .font(PhoneFont.headline)
                .lineLimit(1)
                .padding(.horizontal, 110)
                .accessibilityAddTraits(.isHeader)
            HStack {
                Button(leading, action: onLeading)
                    .font(PhoneFont.body)
                    .foregroundStyle(Theme.volt)
                Spacer()
                if let trailing {
                    Button(trailing, action: onTrailing)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.volt)
                        .opacity(trailingEnabled ? 1 : 0.4)
                        .disabled(!trailingEnabled)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 44)
        .padding(.top, 20)
    }
}

// MARK: Rows of a plan

extension PlanItem {
    /// "4 × 6–10 · +2.5 kg · 2:30 rest": what a plan row says about an exercise (a tick-off item: its own text).
    func planLine(group showsGroup: Bool = false) -> String {
        var parts = [Format.prescription(self, TargetPlanner.target(for: self, history: [], deload: false))]
        if kind == .weighted, let increment { parts.append("+\(Format.kg(increment))") }
        if let restSec { parts.append("\(Format.clock(restSec)) rest") }
        if showsGroup { parts.insert(group, at: 0) }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
