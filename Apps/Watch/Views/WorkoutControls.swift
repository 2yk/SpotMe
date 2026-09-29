import SwiftUI
import RepCoachCore

/// Left of the workout, as in Apple's Workout app: pause or resume, end, skip to what's next, and the day's list.
struct WorkoutControls: View {
    @Environment(WorkoutModel.self) private var workout
    @Environment(HealthWorkout.self) private var health
    @Environment(TodayModel.self) private var today
    let onPauseOrResume: () -> Void
    let onEnd: () -> Void
    let onSkip: () -> Void
    let onList: () -> Void

    var body: some View {
        GeometryReader { geometry in
            // Two rows of buttons with their labels, under a line of workout time and heart rate.
            let button = min(54, (geometry.size.height - 88) / 2)
            VStack(spacing: 6) {
                header
                Grid(horizontalSpacing: 8, verticalSpacing: 6) {
                    GridRow {
                        if workout.isPaused {
                            ControlButton(title: "Resume", symbol: "play.fill", tint: Theme.mint, height: button,
                                          action: onPauseOrResume)
                        } else {
                            ControlButton(title: "Pause", symbol: "pause.fill", tint: Theme.amber, height: button,
                                          action: onPauseOrResume)
                        }
                        ControlButton(title: "End", symbol: "xmark", tint: Theme.pulse, height: button, action: onEnd)
                            .disabled(!workout.canFinish)
                    }
                    GridRow {
                        ControlButton(title: "Skip", symbol: "forward.end.fill", tint: Theme.ice, height: button,
                                      action: onSkip)
                            .disabled(!workout.canSkip)
                        ControlButton(title: "List", symbol: "list.bullet", tint: .white, height: button,
                                      action: onList)
                    }
                }
                if let next = workout.skipTarget {
                    Text("Skip to \(next)")
                        .font(.rounded(.caption2, .medium))
                        .foregroundStyle(Theme.tertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Workout time and heart rate while the Health workout runs, else the day's progress.
    @ViewBuilder
    private var header: some View {
        HStack(spacing: 6) {
            if health.isActive {
                ElapsedTime(size: 20)
                if let bpm = health.heartRate {
                    Label("\(Int(bpm.rounded()))", systemImage: "heart.fill")
                        .font(.number(15))
                        .monospacedDigit()
                        .foregroundStyle(Theme.pulse)
                        .labelStyle(.titleAndIcon)
                }
            } else {
                Text(workout.isPaused ? "Paused" : "\(today.queue.doneCount) of \(today.queue.totalCount) done")
                    .font(.rounded(.headline, .bold))
                    .foregroundStyle(workout.isPaused ? Theme.amber : .white)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

/// A big tinted button with its name underneath.
private struct ControlButton: View {
    let title: String
    let symbol: String
    let tint: Color
    let height: CGFloat
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: height * 0.42, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .background(RoundedRectangle(cornerRadius: height / 2.6, style: .continuous)
                        .fill(tint.opacity(0.2)))
                Text(title)
                    .font(.rounded(.footnote, .semibold))
                    .lineLimit(1)
            }
            .opacity(isEnabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
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
        .font(.number(size, weight: .semibold))
        .monospacedDigit()
    }
}
