import SwiftUI
import RepCoachCore

/// Timed sets: Start counts up, with a haptic at the bottom and top of the range; Stop logs the seconds.
struct HoldView: View {
    @Bindable var flow: ExerciseFlow
    @FocusState private var weightFocused: Bool

    var body: some View {
        let item = flow.currentItem
        let target = flow.currentTarget
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Set \(flow.current?.set ?? 1) of \(target.sets)").eyebrow(Theme.violet)
                Spacer(minLength: 4)
                Text(Format.perSet(item, target) ?? "")
                    .font(.rounded(.footnote, .semibold))
                    .foregroundStyle(Theme.secondary)
            }
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                HoldRing(elapsed: flow.holdStartedAt.map { context.date.timeIntervalSince($0) } ?? 0,
                         low: target.secMin ?? 0, high: target.secMax ?? 30)
            }
            .frame(maxHeight: .infinity)

            if flow.holdStartedAt == nil {
                HStack(spacing: 6) {
                    if item.takesWeight {
                        VStack(spacing: -3) {
                            Text(Format.weight(flow.weight)).font(.number(20)).monospacedDigit()
                            Text("kg").eyebrow(weightFocused ? Theme.violet : Theme.tertiary, size: 9)
                        }
                        .frame(width: 58, height: 44)
                        .background(Capsule().fill(weightFocused ? Theme.violet.opacity(0.18) : Theme.card))
                        .overlay(Capsule().strokeBorder(weightFocused ? Theme.violet : Theme.hairline))
                        .focusable()
                        .focused($weightFocused)
                        .focusEffectDisabled()
                        .digitalCrownRotation($flow.weight, from: 0, through: 200, by: item.increment ?? 2.5,
                                              sensitivity: .medium, isContinuous: false,
                                              isHapticFeedbackEnabled: true)
                        .onTapGesture { weightFocused = true }
                    }
                    Button("Start") { flow.startHold() }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.violet))
                }
            } else {
                Button("Stop") { withAnimation(.snappy) { flow.stopHold() } }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.pulse))
            }
        }
    }
}

private struct HoldRing: View {
    let elapsed: TimeInterval
    let low: Int
    let high: Int

    var body: some View {
        let full = Double(max(high, 1))
        let reachedLow = elapsed >= Double(low)
        let reachedHigh = elapsed >= Double(high)
        ZStack {
            ProgressRing(progress: elapsed / full, tint: reachedHigh ? Theme.mint : Theme.violet, lineWidth: 9)
            if low > 0, low < high {
                Capsule()
                    .fill(.white.opacity(0.8))
                    .frame(width: 3, height: 13)
                    .offset(y: -1)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .rotationEffect(.degrees(360 * Double(low) / full))
            }
            VStack(spacing: -2) {
                Text(Format.clock(Int(elapsed)))
                    .font(.number(34))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                Text(reachedHigh ? "Top" : reachedLow ? "In range" : "Hold")
                    .eyebrow(reachedHigh ? Theme.mint : Theme.violet, size: 10)
            }
            .padding(.horizontal, 12)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
