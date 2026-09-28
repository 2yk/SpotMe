import SwiftUI
import RepCoachCore

/// Hosts one exercise: the set screen, the rest timer, and the break before the next one, in place.
struct ExerciseView: View {
    @Environment(WorkoutModel.self) private var workout
    @Bindable var flow: ExerciseFlow
    let onList: () -> Void
    let onFinish: () -> Void

    var body: some View {
        content
            .navigationTitle(showsTitle ? flow.currentItem.name : "")
            .toolbar {
                if flow.canUndo {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { withAnimation(.snappy) { workout.undoLastSet() } } label: {
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
            NextUpView(summaries: summaries, onList: onList, onFinish: onFinish)
        }
    }

    /// Only the set screen has room for the exercise's name.
    private var showsTitle: Bool {
        if case .set = flow.phase { true } else { false }
    }

    private var tint: Color {
        switch flow.phase {
        case .set: flow.currentItem.tint
        case .rest: Theme.ice
        case .finished: workout.breakTime == nil ? Theme.mint : Theme.ice
        }
    }
}
