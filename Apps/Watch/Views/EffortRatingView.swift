import SwiftUI
import RepCoachCore

/// After Finish: how hard the session felt, on Apple's 1 to 10 scale. Ten rising bars that run from cool to hot
/// as it gets harder; tap one or slide a finger across them, then Done. `onDone` gets the score, or nil for Skip.
struct EffortRatingView: View {
    let onDone: (Int?) -> Void
    @State private var score: Int?

    init(onDone: @escaping (Int?) -> Void) {
        self.onDone = onDone
        #if DEBUG
        _score = State(initialValue: LaunchOptions.effort)
        #endif
    }

    var body: some View {
        GeometryReader { geometry in
            // The bars take what's left under the readout and above the buttons.
            let bars = max(40, geometry.size.height - 96)
            VStack(spacing: 6) {
                readout
                RatingBars(score: $score)
                    .frame(height: bars)
                Button("Done") { onDone(score) }
                    .buttonStyle(PrimaryButtonStyle(tint: score.map(Theme.effort) ?? Theme.secondary, height: 40))
                    .disabled(score == nil)
                    .opacity(score == nil ? 0.35 : 1)
                Button("Skip") { onDone(nil) }
                    .buttonStyle(.plain)
                    .font(.rounded(.footnote, .semibold))
                    .foregroundStyle(Theme.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// The number and its word, or what to do until there's one.
    private var readout: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if let score {
                Text("\(score)")
                    .font(.number(34))
                    .monospacedDigit()
                    .foregroundStyle(Theme.effort(score))
                    .contentTransition(.numericText())
                Text(Effort.level(score).title)
                    .font(.rounded(.headline, .bold))
                    .foregroundStyle(Theme.effort(score))
            } else {
                Text("How hard was it?")
                    .font(.rounded(.headline, .bold))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(height: 38)
        .animation(.snappy(duration: 0.15), value: score)
    }
}

/// Ten bars, low to high. Lit up to the score; the touch picks the bar under the finger.
private struct RatingBars: View {
    @Binding var score: Int?

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 3
            let width = (geometry.size.width - spacing * 9) / 10
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(Effort.range, id: \.self) { value in
                    let lit = score.map { value <= $0 } ?? false
                    RoundedRectangle(cornerRadius: width / 2.4, style: .continuous)
                        .fill(Theme.effort(value).opacity(lit ? 1 : 0.25))
                        .frame(width: width, height: geometry.size.height * (0.28 + 0.72 * Double(value - 1) / 9))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                pick(Int(drag.location.x / ((geometry.size.width + spacing) / 10)) + 1)
            })
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort")
        .accessibilityValue(score.map { "\(Effort.text($0)) of 10" } ?? "Not set")
        .accessibilityIdentifier("effort-bars")
        .accessibilityAdjustableAction { direction in
            pick((score ?? 5) + (direction == .increment ? 1 : -1))
        }
    }

    private func pick(_ value: Int) {
        let clamped = min(Effort.range.upperBound, max(Effort.range.lowerBound, value))
        guard clamped != score else { return }
        score = clamped
        Haptics.play(.step)
    }
}
