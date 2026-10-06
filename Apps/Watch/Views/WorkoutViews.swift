import SwiftUI
import RepCoachCore

/// Shown once after Finish workout.
struct WorkoutSummaryView: View {
    let summary: WorkoutModel.Summary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: pt(5)) {
            HStack(spacing: pt(4)) {
                Image(systemName: "checkmark")
                    .font(.system(size: pt(13), weight: .heavy))
                    .foregroundStyle(Theme.mint)
                Text(summary.savedToHealth ? "Saved to Health" : "Session finished").role(.row)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, pt(4))
            Grid(horizontalSpacing: pt(4), verticalSpacing: pt(4)) {
                GridRow {
                    stat("Time", summary.duration.map(duration) ?? "--")
                    stat("Sets", "\(summary.sets)")
                }
                GridRow {
                    stat("Avg bpm", summary.averageHeartRate.map { "\(Int($0.rounded()))" } ?? "--",
                         tint: Theme.red)
                    stat("kcal", summary.energy.map { "\(Int($0.rounded()))" } ?? "--")
                }
            }
            Spacer(minLength: 0)
            Button("Done") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Metrics.side)
        .padding(.top, Metrics.top - pt(2))
        .padding(.bottom, Metrics.bottom)
        .ignoresSafeArea()
        .barTitle(summary.title, close: true)
    }

    private func stat(_ label: String, _ value: String, tint: Color = .white) -> some View {
        VStack(spacing: 0) {
            Text(value).role(TextRole(size: 20, line: 22, weight: .bold), tint, single: true)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label).role(.eyebrow, Theme.text3, single: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, pt(5))
        .surface(radius: 14)
    }

    private func duration(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: seconds >= 3600 ? .hourMinuteSecond : .minuteSecond))
    }
}
