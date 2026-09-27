import Foundation
import RepCoachCore

/// The watch's workout state: the exercise in progress. Milestone 2 adds the HealthKit workout session here.
@MainActor @Observable
final class WorkoutModel {
    let today: TodayModel
    /// Kept while the user pops back to Today, so a running rest timer survives.
    private(set) var flow: ExerciseFlow?

    init(today: TodayModel) {
        self.today = today
    }

    /// Starts `items`, or picks the running flow back up if it's the same exercise.
    func begin(_ items: [PlanItem]) {
        if let flow, flow.itemIds == items.map(\.exerciseId), !flow.isFinished { return }
        flow?.stop()
        flow = ExerciseFlow(items: items, today: today)
    }

    func end() {
        flow?.stop()
        flow = nil
    }
}
