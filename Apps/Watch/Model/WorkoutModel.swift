import Foundation
import RepCoachCore

/// The watch's workout state: the exercise in progress and the HealthKit workout around the whole session.
@MainActor @Observable
final class WorkoutModel {
    struct Summary: Identifiable {
        let id = UUID()
        let savedToHealth: Bool
        let duration: TimeInterval?
        let averageHeartRate: Double?
        let energy: Double?
        let sets: Int
    }

    let today: TodayModel
    let health: HealthWorkout
    /// Kept while the user pops back to Today, so a running rest timer survives.
    private(set) var flow: ExerciseFlow?
    /// Shown once after Finish workout.
    var summary: Summary?
    /// Set after a failed automatic start (e.g. Health access denied) so every set doesn't retry.
    @ObservationIgnored private var autoStartFailed = false

    init(today: TodayModel, health: HealthWorkout? = nil) {
        self.today = today
        self.health = health ?? .shared
    }

    /// Starts `items`, or picks the running flow back up if it's the same exercise.
    func begin(_ items: [PlanItem]) {
        if let flow, flow.itemIds == items.map(\.exerciseId), !flow.isFinished { return }
        flow?.stop()
        flow = ExerciseFlow(items: items, today: today) { [weak self] in self?.setLogged() }
    }

    func end() {
        flow?.stop()
        flow = nil
    }

    // MARK: Health workout

    /// Today's session is open: logged into and not finished yet, or a Health workout is running.
    var canFinish: Bool {
        health.isRunning || today.session.map { $0.endedAt == nil && $0.logs.contains { !$0.sets.isEmpty } } == true
    }

    /// The Start button: whether the day has anything with sets to log.
    var canStart: Bool {
        LaunchOptions.healthKit && health.isAvailable && health.state == .idle
            && today.day.items.contains { $0.kind != .checklist }
    }

    func startWorkout() {
        Task { await health.start() }
    }

    /// Ends the Health workout, if one is running, and marks today's session finished.
    func finishWorkout() async {
        flow?.stop()
        let started = health.startedAt ?? today.session?.date
        let average = health.averageHeartRate
        let energy = health.energy
        let workoutId = await health.finish()
        if let session = today.session {
            if let workoutId { session.healthKitWorkoutId = workoutId }
            try? today.recorder.finish(session)
        }
        let sets = today.session?.logs.reduce(0) { $0 + $1.sets.count } ?? 0
        summary = Summary(savedToHealth: workoutId != nil, duration: started.map { Date.now.timeIntervalSince($0) },
                          averageHeartRate: average, energy: energy, sets: sets)
        today.refresh()
    }

    /// Called after every logged set. The first set of the day starts the Health workout; ticking checklist
    /// items (runs included) never does. Logging after Finish reopens the session.
    private func setLogged() {
        guard let session = today.session else { return }
        if session.endedAt != nil {
            session.endedAt = nil
            try? today.context.save()
        }
        guard LaunchOptions.healthKit, !autoStartFailed, health.state == .idle,
              session.healthKitWorkoutId == nil else { return }
        Task {
            if await !health.start() { autoStartFailed = true }
        }
    }
}
