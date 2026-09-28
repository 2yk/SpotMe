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
    /// Why Start workout didn't start, shown as an alert.
    var startProblem: String?
    /// Called after each Start workout, when Health may have just been allowed or refused, to tell the phone.
    @ObservationIgnored var onStartAttempted: (() -> Void)?
    /// Called with the session after Finish workout, to send it to the phone.
    @ObservationIgnored var onSessionFinished: ((WorkoutSession) -> Void)?

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

    /// The Start button: Health workouts are on in the phone's Settings, none is running yet, the day has sets
    /// to log, and today's session isn't finished. It's the only way a Health workout starts, so a session
    /// logged after the fact stays out of Health.
    var canStart: Bool {
        LaunchOptions.healthKit && today.settings.healthWorkouts && health.isAvailable && health.state == .idle
            && today.day.items.contains { $0.kind != .checklist }
            && today.session?.endedAt == nil
    }

    func startWorkout() {
        Task {
            let started = await health.start()
            onStartAttempted?()
            guard !started else { return }
            startProblem = health.access == .denied ? Self.accessDeniedMessage : "The workout didn't start. Try again."
        }
    }

    static let accessDeniedMessage = "SpotMe isn't allowed to save workouts. On your iPhone, open the Health app, "
        + "tap your profile picture, then Apps → SpotMe, and turn everything on."

    /// Ends the Health workout, if one is running, saving it to Health or discarding it,
    /// and marks today's session finished.
    func finishWorkout(saveToHealth: Bool = true) async {
        flow?.stop()
        let started = health.startedAt ?? today.session?.date
        let average = health.averageHeartRate
        let energy = health.energy
        let workoutId: UUID?
        if saveToHealth {
            workoutId = await health.finish()
        } else {
            health.discard()
            workoutId = nil
        }
        if let session = today.session {
            if let workoutId { session.healthKitWorkoutId = workoutId }
            try? today.recorder.finish(session)
            onSessionFinished?(session)
        }
        let sets = today.session?.logs.reduce(0) { $0 + $1.sets.count } ?? 0
        summary = Summary(savedToHealth: workoutId != nil, duration: started.map { Date.now.timeIntervalSince($0) },
                          averageHeartRate: average, energy: energy, sets: sets)
        today.refresh()
    }

    /// Called after every logged set. Logging after Finish reopens the session.
    private func setLogged() {
        guard let session = today.session, session.endedAt != nil else { return }
        session.endedAt = nil
        try? today.context.save()
    }
}
