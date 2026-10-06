import SwiftUI

/// How hard was the workout, 1 to 10, turned with the Digital Crown: asked after every Finish. Save keeps it;
/// closing the sheet saves the workout without one.
struct EffortView: View {
    @Environment(WorkoutModel.self) private var workout
    @Environment(\.dismiss) private var dismiss
    @State private var value: Double
    @FocusState private var focused: Bool

    init(initial: Int) {
        _value = State(initialValue: Double(initial))
    }

    var body: some View {
        let effort = Int(value.rounded())
        let band = EffortBand(effort)
        VStack(spacing: 0) {
            Text("How hard was it?").role(.row, .white, single: true)
            Text("\(effort)")
                .role(TextRole(size: 48, line: 50, weight: .heavy), .white, single: true)
                .padding(.top, pt(3))
                .accessibilityIdentifier("effort-value")
            Text(band.word).role(.title, band.color, single: true)
            HStack(spacing: pt(2)) {
                ForEach(1...10, id: \.self) { step in
                    Capsule()
                        .fill(step <= effort ? EffortBand(step).color : Theme.raised)
                        .frame(height: pt(5))
                }
            }
            .padding(.top, pt(6))
            .padding(.horizontal, pt(2))
            Text("Turn the Crown").role(.eyebrow, Theme.text3, single: true).padding(.top, pt(3))
            Spacer(minLength: 0)
            Button("Save") {
                workout.saveEffort(effort)
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .screenColumn(top: Metrics.sheetTop)
        .focusable()
        .focused($focused)
        .digitalCrownRotation($value, from: 1, through: 10, by: 1, sensitivity: .low, isContinuous: false,
                              isHapticFeedbackEnabled: true)
        .onAppear { focused = true }
        .barTitle("Effort", close: true)
        .accessibilityAdjustableAction { direction in
            value = min(10, max(1, value + (direction == .increment ? 1 : -1)))
        }
    }
}

/// Apple's words for the 1 to 10 scale and the colour of each.
struct EffortBand {
    let word: String
    let color: Color

    init(_ effort: Int) {
        switch effort {
        case ...3: (word, color) = ("Easy", Theme.mint)
        case 4...6: (word, color) = ("Moderate", Theme.volt)
        case 7...8: (word, color) = ("Hard", Theme.ember)
        default: (word, color) = ("All Out", Theme.red)
        }
    }
}
