import SwiftUI
import RepCoachCore

/// Countdown between sets: the timer runs round the edge, the middle has the time and what to load next. It
/// never says why the weight moved, and a running rest never pauses: Pause stops the workout's clock, not this.
struct RestView: View {
    @Environment(HealthWorkout.self) private var health
    @Environment(WorkoutModel.self) private var workout
    @Environment(\.dimmed) private var dimmed
    @Bindable var flow: ExerciseFlow
    let rest: Countdown

    var body: some View {
        let next = flow.nextSet
        ZStack(alignment: .top) {
            EdgeCountdown(countdown: rest)
            VStack(spacing: 0) {
                CountdownDigits(countdown: rest)
                heartLine
                    .padding(.top, pt(2))
                Text(next.eyebrow)
                    .role(.eyebrow, dimmed ? Theme.dimmedText : Theme.text3, single: true)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, pt(7))
                HStack(spacing: pt(4)) {
                    if let change = next.change {
                        Image(systemName: change == .up ? "arrow.up" : "arrow.down")
                            .font(.system(size: pt(17), weight: .bold))
                    }
                    Text(next.value).lineLimit(1).minimumScaleFactor(0.6)
                }
                .role(.nextValue, valueColor(next), single: true)
                if let reason = next.reason {
                    Text(reason)
                        .role(.detail, dimmed ? Theme.dimmedText : Theme.text2, single: true)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(.horizontal, Metrics.side)
            .padding(.top, Metrics.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .bottom) {
            RestControls(addTime: { flow.addRest(30) }, undo: flow.canUndo ? { workout.undoLastSet() } : nil,
                         endSymbol: "forward.end.fill", endLabel: "Skip rest",
                         end: { withAnimation(.snappy) { flow.endRest() } })
        }
        .ignoresSafeArea()
    }

    /// Heart rate from the running workout; "Paused" in amber while the workout is paused (the rest runs on).
    /// Keeps its height without either, so the lines under it don't jump.
    @ViewBuilder
    private var heartLine: some View {
        Group {
            if workout.isPaused {
                Text("Paused").role(.eyebrow, Theme.amber)
            } else if let bpm = health.heartRate, !dimmed {
                HStack(spacing: pt(3)) {
                    Image(systemName: "heart.fill").font(.system(size: pt(11), weight: .bold))
                    Text("\(Int(bpm.rounded()))")
                }
                .role(.detail.weight(.bold).size(13), Theme.red)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Heart rate \(Int(bpm.rounded()))")
            } else {
                Color.clear
            }
        }
        .frame(height: pt(15))
    }

    private func valueColor(_ next: ExerciseFlow.NextSet) -> Color {
        if dimmed { return Theme.text2 }
        switch next.change {
        case .up: return Theme.volt
        case .down: return Theme.ember
        case nil: return .white
        }
    }
}
