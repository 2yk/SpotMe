import SwiftUI
import RepCoachCore

/// Hosts one exercise: the set screen, the rest timer, and the break before the next one, in place.
struct ExerciseView: View {
    @Environment(WorkoutModel.self) private var workout
    @Environment(\.dimmed) private var dimmed
    @Bindable var flow: ExerciseFlow
    let onFinish: () -> Void

    var body: some View {
        content
            .barTitle(title.text, title.color)
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
            NextUpView(summaries: summaries, onFinish: onFinish)
        }
    }

    /// The bar holds only a short title; the exercise's name is in the content.
    private var title: (text: String, color: Color) {
        if workout.isPaused { return ("Paused", Theme.amber) }
        switch flow.phase {
        case .set:
            if flow.currentItem.kind == .amrap { return ("Max reps", Theme.volt) }
            return ("Set \(flow.current?.set ?? 1) of \(flow.currentTarget.sets)", Theme.volt)
        case .rest:
            return ("Rest", dimmed ? Theme.ice.opacity(0.55) : Theme.ice)
        case .finished:
            return workout.breakTime == nil ? ("", Theme.mint) : ("Next", dimmed ? Theme.ice.opacity(0.55) : Theme.ice)
        }
    }
}
