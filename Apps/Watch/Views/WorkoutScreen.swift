import SwiftUI
import RepCoachCore

/// The workout in progress: the exercise on screen, a checklist item, or the end of the day. It moves on by
/// itself; Today, one tap back, is where to pick something else first.
struct WorkoutScreen: View {
    @Environment(WorkoutModel.self) private var workout
    /// Back to Today's list.
    let onList: () -> Void
    /// Finish workout, from the end of the day.
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            switch workout.step {
            case .exercise(let flow):
                ExerciseView(flow: flow, onFinish: onFinish)
                    .id(ObjectIdentifier(flow))
                    .transition(.moveIn)
            case .checklist(let item):
                ChecklistView(item: item)
                    .id(item.exerciseId)
                    .transition(.moveIn)
            case .allDone:
                AllDoneView(summaries: [], onFinish: onFinish)
                    .transition(.moveIn)
            case nil:
                Color.clear.onAppear(perform: onList)
            }
        }
        .animation(.snappy, value: workout.step)
    }
}

private extension AnyTransition {
    /// The next item slides in; the finished one fades away.
    static var moveIn: AnyTransition { .asymmetric(insertion: .move(edge: .trailing), removal: .opacity) }
}
