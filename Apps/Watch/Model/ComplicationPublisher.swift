import Foundation
import WidgetKit
import RepCoachCore

/// Tells the Start workout complication where today's session stands: Start workout, the next item, or Done. The
/// complication reads it from the app group; it is only asked to redraw when the state changed.
@MainActor
enum ComplicationPublisher {
    static func publish(today: TodayModel, workout: WorkoutModel) {
        // The complication is about the calendar day's plan day, not another day picked in the app.
        guard today.isToday, today.queue.totalCount > 0 else { return }
        let started = workout.isRunning || today.session.map { !$0.logs.isEmpty } == true
        let phase: ComplicationState.Phase = today.isFinished ? .finished : started ? .running : .notStarted
        let state = ComplicationState(
            date: SwapMarks.stamp(.now, calendar: today.calendar), phase: phase,
            next: phase == .running ? today.queue.upNext.map(\.name).joined(separator: " + ") : nil,
            done: today.queue.doneCount, total: today.queue.totalCount)
        if state.save() { WidgetCenter.shared.reloadTimelines(ofKind: "StartWorkout") }
    }
}
