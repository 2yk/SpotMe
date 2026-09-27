import SwiftUI
import RepCoachCore

/// Countdown between sets, with the next set's target and the engine's one-line reason.
struct RestView: View {
    let flow: ExerciseFlow
    let rest: ExerciseFlow.Rest

    var body: some View {
        GeometryReader { geometry in
            let ring = max(64, min(geometry.size.width * 0.62, geometry.size.height - 54))
            VStack(spacing: 4) {
                ZStack {
                    TimelineView(.periodic(from: .now, by: 0.5)) { context in
                        ProgressRing(progress: rest.endsAt.timeIntervalSince(context.date) / rest.duration,
                                     tint: Theme.ice, lineWidth: 8)
                    }
                    VStack(spacing: -2) {
                        // The system timer text doesn't shrink to fit, so size it from the ring.
                        Text(timerInterval: Date.now...max(Date.now, rest.endsAt), countsDown: true)
                            .font(.number(min(36, ring * 0.3)))
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
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
