import SwiftUI
import RepCoachCore

/// End of an exercise: what happens next time, then back to Today.
struct FinishedView: View {
    let summaries: [ExerciseFlow.Summary]
    let onDone: () -> Void
    let onUndo: (() -> Void)?
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Theme.mint)
                    .symbolEffect(.bounce, value: appeared)
                ForEach(summaries) { summary in
                    VStack(spacing: 3) {
                        Text(summary.name)
                            .font(.rounded(.headline, .bold))
                        Text(summary.line.text)
                            .font(.rounded(.footnote, .semibold))
                            .foregroundStyle(summary.line.tone.color)
                    }
                    .multilineTextAlignment(.center)
                }
                Button("Done", action: onDone)
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.mint))
                    .padding(.top, 2)
                if let onUndo {
                    Button("Undo last set", action: onUndo)
                        .buttonStyle(.plain)
                        .font(.rounded(.footnote, .medium))
                        .foregroundStyle(Theme.secondary)
                }
            }
        }
        .onAppear { appeared = true }
    }
}
