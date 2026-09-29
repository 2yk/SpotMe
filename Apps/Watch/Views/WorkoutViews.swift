import SwiftUI
import RepCoachCore

/// Heart rate and workout time while the Health workout is under way.
struct WorkoutBar: View {
    @Environment(HealthWorkout.self) private var health

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "heart.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.pulse)
            Text(health.heartRate.map { "\(Int($0.rounded()))" } ?? "--")
                .font(.number(17))
                .monospacedDigit()
            Text("bpm").eyebrow(Theme.tertiary, size: 9)
            Spacer(minLength: 4)
            ElapsedTime()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .card(Theme.card, radius: 14)
        .accessibilityElement(children: .combine)
    }
}

/// Shown once after Finish workout.
struct WorkoutSummaryView: View {
    let summary: WorkoutModel.Summary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Theme.mint)
                Text(summary.savedToHealth ? "Saved to Health" : "Session finished")
                    .font(.rounded(.headline, .bold))
                Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                    GridRow {
                        stat("Time", summary.duration.map(duration) ?? "--")
                        stat("Sets", "\(summary.sets)")
                    }
                    if summary.averageHeartRate != nil || summary.energy != nil {
                        GridRow {
                            stat("Avg bpm", summary.averageHeartRate.map { "\(Int($0.rounded()))" } ?? "--",
                                 tint: Theme.pulse)
                            stat("kcal", summary.energy.map { "\(Int($0.rounded()))" } ?? "--", tint: Theme.ember)
                        }
                    }
                }
                Button("Done") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.mint))
            }
        }
    }

    private func stat(_ label: String, _ value: String, tint: Color = .white) -> some View {
        VStack(spacing: 0) {
            Text(value).font(.number(20)).monospacedDigit().foregroundStyle(tint)
            Text(label).eyebrow(Theme.tertiary, size: 9)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .card(Theme.card, radius: 12)
    }

    private func duration(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: seconds >= 3600 ? .hourMinuteSecond : .minuteSecond))
    }
}
