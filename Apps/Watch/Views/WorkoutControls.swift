import SwiftUI
import RepCoachCore

/// Left of the workout, as in Apple's Workout app: pause or resume, end, skip to what's next, and the day's list.
/// The buttons have fixed sizes, so nothing is measured and nothing resizes when the page first appears.
struct WorkoutControls: View {
    @Environment(WorkoutModel.self) private var workout
    @Environment(HealthWorkout.self) private var health
    @Environment(TodayModel.self) private var today
    let onPauseOrResume: () -> Void
    let onEnd: () -> Void
    let onSkip: () -> Void
    let onList: () -> Void

    var body: some View {
        VStack(spacing: pt(4)) {
            header
            Grid(horizontalSpacing: pt(6), verticalSpacing: pt(4)) {
                GridRow {
                    if workout.isPaused {
                        ControlButton(title: "Resume", symbol: "play.fill", tint: Theme.mint, action: onPauseOrResume)
                    } else {
                        ControlButton(title: "Pause", symbol: "pause.fill", tint: Theme.amber, action: onPauseOrResume)
                    }
                    ControlButton(title: "End", symbol: "xmark", tint: Theme.red, action: onEnd)
                        .disabled(!workout.canFinish)
                }
                GridRow {
                    ControlButton(title: "Skip", symbol: "forward.end.fill", tint: nil, action: onSkip)
                        .disabled(!workout.canSkip)
                    ControlButton(title: "List", symbol: "list.bullet", tint: nil, action: onList)
                }
            }
            if let next = workout.skipTarget {
                VStack(spacing: 0) {
                    Text("Skip to \(next)").role(.small, Theme.text2).lineLimit(1).minimumScaleFactor(0.8)
                    if workout.skipLeavesOpen {
                        Text("This one stays open").role(.small, Theme.text3).lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Metrics.side)
        .padding(.top, Metrics.top)
        .padding(.bottom, Metrics.bottom)
        .ignoresSafeArea()
    }

    /// Workout time and heart rate while the Health workout runs, else the day's progress.
    @ViewBuilder
    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: pt(8)) {
            if health.isActive {
                ElapsedTime(size: 28)
                if let bpm = health.heartRate {
                    HStack(spacing: pt(3)) {
                        Image(systemName: "heart.fill").font(.system(size: pt(12), weight: .bold))
                        Text("\(Int(bpm.rounded()))").role(.row.weight(.bold).size(15), Theme.red)
                    }
                    .foregroundStyle(Theme.red)
                }
            } else {
                Text(workout.isPaused ? "Paused" : "\(today.queue.doneCount) of \(today.queue.totalCount) done")
                    .role(.title, workout.isPaused ? Theme.amber : .white)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

/// A button 40 pt high, tinted for a state or neutral, with its name underneath.
private struct ControlButton: View {
    let title: String
    let symbol: String
    /// nil: the neutral raised fill with a white icon.
    let tint: Color?
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            VStack(spacing: pt(2)) {
                Image(systemName: symbol)
                    .font(.system(size: pt(17), weight: .bold))
                    .foregroundStyle(tint ?? .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: pt(40))
                    .background(RoundedRectangle(cornerRadius: pt(17), style: .continuous)
                        .fill(tint.map { $0.opacity(0.18) } ?? Theme.raised))
                Text(title).role(.detail.weight(.semibold).size(12), .white).lineLimit(1)
            }
            .opacity(isEnabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

/// Workout time without pauses: counting while running, still and amber while paused.
struct ElapsedTime: View {
    @Environment(HealthWorkout.self) private var health
    var size: CGFloat = 15

    var body: some View {
        Group {
            if let start = health.timerStart {
                Text(start, style: .timer)
                    .foregroundStyle(Theme.volt)
            } else if let elapsed = health.pausedElapsed {
                Text(Duration.seconds(elapsed).formatted(
                    .time(pattern: elapsed >= 3600 ? .hourMinuteSecond : .minuteSecond)))
                    .foregroundStyle(Theme.amber)
            }
        }
        .font(.number(pt(size), weight: .heavy))
        .monospacedDigit()
        .lineLimit(1)
    }
}
