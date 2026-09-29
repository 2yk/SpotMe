import SwiftUI
import RepCoachCore

/// Countdown between sets, with the next set's target and the engine's one-line reason.
struct RestView: View {
    @Environment(HealthWorkout.self) private var health
    let flow: ExerciseFlow
    let rest: Countdown

    var body: some View {
        GeometryReader { geometry in
            let ring = max(64, min(geometry.size.width * 0.62, geometry.size.height - 54))
            VStack(spacing: 4) {
                CountdownRing(countdown: rest, digits: min(36, ring * 0.3)) {
                    if let bpm = health.heartRate {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill").font(.system(size: 10, weight: .bold))
                            Text("\(Int(bpm.rounded()))").font(.number(13)).monospacedDigit()
                        }
                        .foregroundStyle(Theme.pulse)
                        .accessibilityLabel("Heart rate \(Int(bpm.rounded()))")
                    } else {
                        Text("Rest").eyebrow(Theme.ice, size: 10)
                    }
                }
                .frame(width: ring, height: ring)

                Text(flow.nextSetLine)
                    .font(.rounded(.footnote, .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let line = flow.coachingLine {
                    Text(line.text)
                        .font(.rounded(.caption2, .semibold))
                        .foregroundStyle(line.tone.color)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button { flow.addRest(30) } label: {
                    Image(systemName: "goforward.30")
                }
                .accessibilityLabel("Add 30 seconds")
                Spacer()
                Button { withAnimation(.snappy) { flow.endRest() } } label: {
                    Image(systemName: "forward.end.fill")
                }
                .accessibilityLabel("Skip rest")
            }
        }
    }
}
