import Foundation
import OSLog
import RepCoachCore

/// The watch's workout: what's on screen (an exercise, a checklist item or the end of the day), the break that
/// moves it on to the next item by itself, and the Health workout around the whole session.
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

    /// What the workout screen shows.
    enum Step: Equatable {
        /// Logging sets. The flow keeps its rest timer while Today is on screen.
        case exercise(ExerciseFlow)
        /// A warmup, neck work or a cooldown: read it, tick it off.
        case checklist(PlanItem)
        /// Every item is done or skipped.
        case allDone

        static func == (lhs: Step, rhs: Step) -> Bool {
            switch (lhs, rhs) {
            case let (.exercise(a), .exercise(b)): a === b
            case let (.checklist(a), .checklist(b)): a == b
            case (.allDone, .allDone): true
            default: false
            }
        }
    }

    let today: TodayModel
    let health: HealthWorkout
    private(set) var step: Step? {
        didSet { stepDay = step == nil ? nil : today.dayKey }
    }
    /// The plan day `step` belongs to.
    @ObservationIgnored private var stepDay: String?
    /// The break after an exercise; when it runs out, the next item starts by itself.
    private(set) var breakTime: ExerciseFlow.Rest?
    /// While the next item is being picked the break waits, with this much left.
    @ObservationIgnored private var pausedBreak: TimeInterval?
    /// Shown once after Finish workout.
    var summary: Summary?
    /// Why Start workout couldn't start the Health workout, shown as an alert.
    var startProblem: String?
    /// Called after each Health start, when access may have just been allowed or refused, to tell the phone.
    @ObservationIgnored var onStartAttempted: (() -> Void)?
    /// Called with the session after Finish workout, to send it to the phone.
    @ObservationIgnored var onSessionFinished: ((WorkoutSession) -> Void)?
    /// Called with a discarded session's id, so the phone deletes its copy.
    @ObservationIgnored var onSessionDiscarded: ((UUID) -> Void)?
    /// A Health workout that failed to start by itself isn't tried again until Start workout is tapped.
    @ObservationIgnored private var autoStartFailed = false
    @ObservationIgnored private var breakTimers: [Task<Void, Never>] = []

    init(today: TodayModel, health: HealthWorkout? = nil) {
        self.today = today
        self.health = health ?? .shared
    }

    // MARK: What's on screen

    var flow: ExerciseFlow? {
        if case .exercise(let flow) = step { flow } else { nil }
    }

    /// Something was started today, so the main button reads Continue.
    var hasStarted: Bool {
        health.isRunning || currentStep != nil || today.session.map { !$0.logs.isEmpty } == true
    }

    /// Where Continue leads: the item on screen, else the next one in order.
    var currentName: String? {
        switch currentStep {
        case .exercise(let flow) where !flow.isFinished:
            return flow.items.map(\.name).joined(separator: " + ")
        case .checklist(let item):
            return item.name
        default:
            let next = today.queue.upNext.map(\.name).joined(separator: " + ")
            return next.isEmpty ? nil : next
        }
    }

    /// `step`, unless it no longer fits the day (see `reconcile`).
    private var currentStep: Step? {
        guard let step, isCurrent(step) else { return nil }
        return step
    }

    /// Whether `step` still fits Today: the same plan day, and its item still open (an exercise in its break
    /// counts until the break moves on).
    private func isCurrent(_ step: Step) -> Bool {
        guard stepDay == today.dayKey else { return false }
        let open = Set(today.day.items.filter { !today.status(of: $0).isFinished }.map(\.exerciseId))
        switch step {
        case .exercise(let flow):
            return flow.isFinished || flow.itemIds.contains(where: open.contains)
        case .checklist(let item):
            return open.contains(item.exerciseId)
        case .allDone:
            return today.queue.isComplete
        }
    }

    // MARK: Moving through the day

    /// Drops the step when it no longer fits the day: another day was picked, midnight passed, or its item was
    /// finished or skipped from the list. Its timers stop with it.
    func reconcile() {
        guard let step, !isCurrent(step) else { return }
        cancelBreak()
        flow?.stop()
        self.step = nil
    }

    /// Start workout, Continue and the complication: starts the Health workout if it should run, then shows the
    /// item on screen, or the next one.
    func startOrContinue() {
        reconcile()
        startHealth(explicitly: true)
        if step == nil || step == .allDone { advance() }
    }

    /// Opens `item` now, ahead of the plan's order, together with its superset partner.
    func open(_ item: PlanItem) {
        let partners = item.supersetGroup.map { group in
            today.day.items.filter { $0.supersetGroup == group && !today.status(of: $0).isFinished }
        }
        show(partners ?? [item])
        startHealth(explicitly: false)
    }

    /// On to the next open item in plan order (one already started comes first), or the end of the day.
    func advance() {
        cancelBreak()
        today.refresh()
        let next = today.queue.upNext
        if next.isEmpty {
            flow?.stop()
            step = today.queue.totalCount > 0 ? .allDone : nil
        } else {
            show(next)
        }
    }

    /// Shows `items`, keeping the flow on screen if it's already them.
    func show(_ items: [PlanItem]) {
        cancelBreak()
        guard let first = items.first else { return }
        if first.kind == .checklist {
            flow?.stop()
            step = .checklist(first)
            return
        }
        if let flow, flow.itemIds == items.map(\.exerciseId), !flow.isFinished { return }
        flow?.stop()
        step = .exercise(ExerciseFlow(items: items, today: today,
                                      onSetLogged: { [weak self] in self?.setLogged() },
                                      onFinished: { [weak self] in self?.exerciseFinished() }))
    }

    /// Ticks off, or skips, the checklist item on screen and moves on.
    func finishChecklist(_ item: PlanItem, skipped: Bool = false) {
        if skipped { today.skip(item) } else { today.complete(item) }
        Haptics.play(.logged)
        advance()
    }

    /// From Today's list: tick off a checklist item, skip an item, or put a finished one back.
    func tickOff(_ item: PlanItem) {
        today.complete(item)
        Haptics.play(.logged)
        reconcile()
    }

    func skip(_ item: PlanItem) {
        today.skip(item)
        reconcile()
    }

    func reopen(_ item: PlanItem) {
        today.reopen(item)
        reconcile()
    }

    /// Takes back the last set, including one that just finished an exercise.
    func undoLastSet() {
        cancelBreak()
        flow?.undo()
    }

    func extendBreak(by seconds: Int) {
        guard var rest = breakTime else { return }
        rest.endsAt += TimeInterval(seconds)
        rest.duration += TimeInterval(seconds)
        breakTime = rest
        scheduleBreak(rest)
    }

    /// Holds the break while the next item is being picked, so it can't move on underneath the list.
    func pauseBreak() {
        guard let rest = breakTime, pausedBreak == nil else { return }
        pausedBreak = max(0, rest.endsAt.timeIntervalSinceNow)
        breakTimers.forEach { $0.cancel() }
        breakTimers = []
    }

    /// Carries on with what was left of the break, at least a few seconds.
    func resumeBreak() {
        guard let left = pausedBreak, var rest = breakTime else { return }
        pausedBreak = nil
        rest.endsAt = .now.addingTimeInterval(max(left, 5))
        breakTime = rest
        scheduleBreak(rest)
    }

    // MARK: Finishing

    /// Today's session is open: logged into and not finished yet, or a Health workout is running.
    var canFinish: Bool {
        health.isRunning || today.session.map { $0.endedAt == nil && $0.logs.contains { !$0.sets.isEmpty } } == true
    }

    /// There's something today to throw away: anything logged, or a running Health workout.
    var canDiscard: Bool {
        health.isRunning || today.session.map { !$0.logs.isEmpty } == true
    }

    /// Ends the Health workout, if one is running, saving it to Health or not, and marks today's session finished.
    func finishWorkout(saveToHealth: Bool = true) async {
        cancelBreak()
        flow?.stop()
        step = nil
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

    /// Throws today's workout away: everything logged today is deleted, here and on the phone, a running Health
    /// workout isn't saved, and one saved at Finish is deleted from Health.
    func discardWorkout() {
        cancelBreak()
        flow?.stop()
        step = nil
        health.discard()
        if let session = today.session {
            let id = session.id
            let savedWorkout = session.healthKitWorkoutId
            do {
                try today.recorder.delete(session)
                onSessionDiscarded?(id)
            } catch {
                Logger.store.error("Couldn't discard the workout: \(error.localizedDescription)")
            }
            if let savedWorkout {
                Task { await health.deleteWorkout(id: savedWorkout) }
            }
        }
        autoStartFailed = false
        today.refresh()
    }

    // MARK: Health workout

    /// Health workouts are on in the phone's Settings, none is running, the day has sets to log and today's
    /// session isn't finished.
    var canStartHealth: Bool {
        LaunchOptions.healthKit && today.settings.healthWorkouts && health.isAvailable && health.state == .idle
            && today.day.items.contains { $0.kind != .checklist }
            && today.session?.endedAt == nil
    }

    static let accessDeniedMessage = "SpotMe isn't allowed to save workouts. On your iPhone, open the Health app, "
        + "tap your profile picture, then Apps → SpotMe, and turn everything on."

    /// Starts the Health workout when it should run. Tapping Start workout explains a failure; starting by
    /// itself (opening an exercise) stays quiet and isn't tried again.
    private func startHealth(explicitly: Bool) {
        guard canStartHealth, explicitly || !autoStartFailed else { return }
        Task {
            let started = await health.start()
            onStartAttempted?()
            autoStartFailed = !started
            guard !started, explicitly else { return }
            startProblem = health.access == .denied
                ? Self.accessDeniedMessage
                : "The Health workout didn't start. Your sets are still being logged."
        }
    }

    // MARK: Internals

    /// Called after every logged set. Logging after Finish reopens the session.
    private func setLogged() {
        guard let session = today.session, session.endedAt != nil else { return }
        session.endedAt = nil
        try? today.context.save()
    }

    /// An exercise's last set: a break as long as its rest (a short one before a checklist item), then the
    /// next item starts by itself.
    private func exerciseFinished() {
        guard let flow, let next = today.queue.upNext.first else { return }
        let seconds = next.kind == .checklist ? 15 : max(30, flow.items.last?.restSec ?? 90)
        let rest = ExerciseFlow.Rest(endsAt: .now.addingTimeInterval(TimeInterval(seconds)),
                                     duration: TimeInterval(seconds))
        breakTime = rest
        scheduleBreak(rest)
    }

    private func scheduleBreak(_ rest: ExerciseFlow.Rest) {
        breakTimers.forEach { $0.cancel() }
        let haptics = today.settings.restHaptics
        let warning = rest.endsAt.addingTimeInterval(-10)
        breakTimers = [after(rest.endsAt) { [weak self] in
            if haptics { Haptics.play(.restOver) }
            self?.advance()
        }]
        if warning > .now {
            breakTimers.append(after(warning) { if haptics { Haptics.play(.restWarning) } })
        }
    }

    private func cancelBreak() {
        breakTimers.forEach { $0.cancel() }
        breakTimers = []
        breakTime = nil
        pausedBreak = nil
    }

    private func after(_ date: Date, _ action: @escaping @MainActor () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            let delay = date.timeIntervalSinceNow
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            guard !Task.isCancelled else { return }
            action()
        }
    }
}
