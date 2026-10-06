import SwiftUI
import RepCoachCore

/// Timed sets: Start counts up round the edge, with the target zone marked and a haptic at the bottom and top
/// of the range; Stop logs the seconds.
struct HoldView: View {
    @Environment(WorkoutModel.self) private var workout
    @Bindable var flow: ExerciseFlow
    @FocusState private var focus: SetView.Field?

    var body: some View {
        if let start = flow.holdStartedAt {
            running(since: start)
        } else {
            ready
        }
    }

    // MARK: Ready

    private var ready: some View {
        let item = flow.currentItem
        let target = flow.currentTarget
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .role(.title)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                SetHintRow(flow: flow)
                    .padding(.top, pt(1))
            }
            .padding(.horizontal, pt(4))

            if item.takesWeight {
                CrownValue(value: $flow.weight, step: flow.increment, range: 0...500, unit: "kg", wide: true,
                           focus: $focus, field: .weight, format: Format.weight)
                    .frame(maxHeight: .infinity)
                    .padding(.top, pt(6))
                    .id(flow.stepIndex)
            } else {
                // Nothing for the Crown to move: the target to hold for.
                VStack(spacing: pt(1)) {
                    Text(Format.range(target.secMin ?? 0, target.secMax ?? target.secMin ?? 0))
                        .role(.valueWide, .white, single: true)
                    Text("seconds").role(.eyebrow, Theme.text3, single: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .surface()
                .padding(.top, pt(6))
            }

            Button("Start") { withAnimation(.snappy) { flow.startHold() } }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, pt(6))
        }
        .screenColumn()
        .onAppear { if item.takesWeight { focus = .weight } }
    }

    // MARK: Running

    private func running(since start: Date) -> some View {
        let item = flow.currentItem
        let target = flow.currentTarget
        let low = Double(target.secMin ?? 0)
        let high = Double(max(target.secMax ?? 30, 1))
        return TimelineView(CountUpSchedule(start: start)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(start))
            let reachedTop = elapsed >= high
            let color = reachedTop ? Theme.mint : Theme.volt
            ZStack {
                ZStack {
                    EdgeTrack(tint: Theme.volt)
                    if low > 0, low < high {
                        EdgeArc(from: low / high, to: 1, tint: Theme.volt.opacity(0.38))
                    }
                    EdgeArc(from: 0, to: min(elapsed / high, 1), tint: color)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                VStack(spacing: 0) {
                    Text(item.name).role(.row, .white).lineLimit(1).minimumScaleFactor(0.8)
                    Text(Format.clock(Int(elapsed)))
                        .role(.timer, .white, single: true)
                        .accessibilityIdentifier("countdown")
                    Text(reachedTop ? "Top · stop when ready" : elapsed >= low ? "In range" : "Hold")
                        .role(.eyebrow, color, single: true)
                        .padding(.top, pt(2))
                    Text(detail(item, target))
                        .role(.detail, Theme.text2)
                        .padding(.top, pt(2))
                    Spacer(minLength: 0)
                    Button("Stop") { withAnimation(.snappy) { flow.stopHold() } }
                        .buttonStyle(PrimaryButtonStyle.destructive)
                }
                .padding(.horizontal, Metrics.side)
                .padding(.top, Metrics.top + pt(4))
                .padding(.bottom, Metrics.bottom)
                .ignoresSafeArea()
            }
        }
    }

    /// "30–45s · 10 kg"
    private func detail(_ item: PlanItem, _ target: ItemTarget) -> String {
        var parts = [Format.perSet(item, target) ?? ""]
        if item.takesWeight, flow.weight > 0 { parts.append(Format.kg(flow.weight)) }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
