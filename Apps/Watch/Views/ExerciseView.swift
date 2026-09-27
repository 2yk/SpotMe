import SwiftUI
import RepCoachCore

/// Hosts one exercise: the set screen, the rest timer and the summary, in place.
struct ExerciseView: View {
    @Bindable var flow: ExerciseFlow
    let onDone: () -> Void

    var body: some View {
        content
            .navigationTitle(isResting ? "" : flow.currentItem.name)
            .toolbar {
                if flow.canUndo, !flow.isFinished {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { withAnimation(.snappy) { flow.undo() } } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .accessibilityLabel("Undo last set")
                    }
                }
            }
            .containerBackground(tint.gradient.opacity(0.3), for: .navigation)
            .animation(.snappy, value: flow.phase)
    }

    @ViewBuilder
    private var content: some View {
        switch flow.phase {
        case .set:
            if flow.currentItem.kind == .timed {
                HoldView(flow: flow)
            } else {
                SetView(flow: flow)
            }
        case .rest(let rest):
            RestView(flow: flow, rest: rest)
        case .finished(let summaries):
            FinishedView(summaries: summaries, onDone: onDone,
                         onUndo: flow.canUndo ? { withAnimation(.snappy) { flow.undo() } } : nil)
        }
    }

    private var isResting: Bool {
        if case .rest = flow.phase { true } else { false }
    }

    private var tint: Color {
        switch flow.phase {
        case .set: flow.currentItem.tint
        case .rest: Theme.ice
        case .finished: Theme.mint
        }
    }
}
