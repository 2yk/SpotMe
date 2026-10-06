import Foundation
import OSLog
import RepCoachCore

/// The watch's workout: what's on screen (an exercise, a checklist item or the end of the day), the break that
/// moves it on to the next item by itself, pause and skip, and the Health workout around the whole session.
@MainActor @Observable
final class WorkoutModel {
    struct Summary: Identifiable {
        let id = UUID()
        /// The day's name: "Push A".
        var title = ""
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
    private(set) var breakTime: Countdown?
    /// Paused from the controls (the Health workout, the rest and the break all wait), or a Health workout that's
    /// paused, as one picked up after a relaunch can be.
    var isPaused: Bool { pausedHere || health.state == .paused }
    private var pausedHere = false
    /// The break waits while the next item is being picked.
    @ObservationIgnored private var breakHeld = false
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
    @ObservationIgnored private let breakAlarm = CountdownAlarm()

    init(today: TodayModel, health: HealthWorkout? = nil) {
        self.today = today
        self.health = health ?? .shared
    }

    // MARK: What's on screen

    var flow: ExerciseFlow? {
        if case .exercise(let flow) = step { flow } else { nil }
    }

    /// A rest, a break or a hold is running: the screen has the edge timer.
    var showsEdgeTimer: Bool {
        guard case .exercise(let flow) = currentStep else { return false }
        switch flow.phase {
        case .rest: return true
        case .finished: return breakTime != nil
        case .set: return flow.holdStartedAt != nil
        }
    }

    /// The last logged set can be taken back (not after a ramp-up).
    var canUndo: Bool { flow?.canUndo ?? false }

    /// Something was started today, so the main button reads Continue.
    var hasStarted: Bool {
        health.isActive || currentStep != nil || today.session.map { !$0.logs.isEmpty } == true
    }

    /// Where Continue leads: the item on screen, else the next one in order.
    var currentName: String? {
        switch currentStep {
        case .exercise(let flow) where !flow.isFinished:
            return flow.items.map(\.name).joined(separator: " + ")
        case .checklist(let item):
            return item.name
        default:
            return Self.names(today.queue.upNext)
        }
    }

    /// Where Skip leads: after the item on screen, or straight to the next one from a break. nil when nothing's
    /// left to go to.
    var skipTarget: String? {
        switch currentStep {
        case .exercise(let flow) where !flow.isFinished:
            return Self.names(today.upNext(finishing: flow.items))
        case .checklist(let item):
            return Self.names(today.upNext(finishing: [item]))
        case .exercise:
            return Self.names(today.queue.upNext)
        case .allDone, nil:
            return nil
        }
    }

    /// Skip puts the item on screen off for later; from a break it just starts the next one now.
    var skipLeavesOpen: Bool {
        switch currentStep {
        case .exercise(let flow): !flow.isFinished
        case .checklist: true
        case .allDone, nil: false
        }
    }

    /// Skip does something: there's an item on screen, or a break before the next one.
    var canSkip: Bool {
        switch currentStep {
        case .exercise(let flow): !flow.isFinished || !today.queue.upNext.isEmpty
        case .checklist: true
        case .allDone, nil: false
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

    private static func names(_ items: [PlanItem]) -> String? {
        items.isEmpty ? nil : items.map(\.name).joined(separator: " + ")
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
                                      onActivity: { [weak self] in self?.activity() },
                                      onFinished: { [weak self] in self?.exerciseFinished() }))
    }

    /// Skip, from the controls: on to the next item now. The exercise on screen keeps what's logged (it's
    /// skipped if nothing is), a checklist item is skipped, and a break ends early.
    func skip() {
        resume()
        switch currentStep {
        case .exercise(let flow) where !flow.isFinished:
            flow.stop()
            for item in flow.items where !today.status(of: item).isFinished {
                if today.log(for: item)?.sets.isEmpty == false {
                    today.complete(item)
                } else {
                    today.skip(item)
                }
            }
            advance()
        case .exercise:
            advance()
        case .checklist(let item):
            finishChecklist(item, skipped: true)
        case .allDone, nil:
            break
        }
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

    // MARK: Pause and the break

    /// Pause, from the controls: the Health workout's time and heart rate, a rest and a break all wait.
    func pause() {
        guard !isPaused else { return }
        pausedHere = true
        health.pause()
        flow?.pauseRest()
        if var countdown = breakTime {
            countdown.pause()
            breakTime = countdown
            breakAlarm.cancel()
        }
    }

    /// Carries on after a pause. Logging a set or starting a hold does this too.
    func resume() {
        guard isPaused else { return }
        pausedHere = false
        health.resume()
        flow?.resumeRest()
        if !breakHeld, var countdown = breakTime {
            countdown.resume()
            breakTime = countdown
            scheduleBreak(countdown)
        }
    }

    func extendBreak(by seconds: Int) {
        guard var countdown = breakTime else { return }
        countdown.add(TimeInterval(seconds))
        breakTime = countdown
        scheduleBreak(countdown)
    }

    /// Holds the break while the next item is being picked, so it can't move on underneath the list.
    func holdBreak() {
        guard var countdown = breakTime, !countdown.isPaused else { return }
        countdown.pause()
        breakTime = countdown
        breakAlarm.cancel()
        breakHeld = true
    }

    /// Carries on with what was left of the break, at least a few seconds, unless the workout is paused.
    func releaseBreak() {
        guard breakHeld else { return }
        breakHeld = false
        guard !isPaused, var countdown = breakTime else { return }
        countdown.resume(minimum: 5)
        breakTime = countdown
        scheduleBreak(countdown)
    }

    // MARK: Finishing

    /// Today's session is open: logged into and not finished yet, or a Health workout is under way.
    var canFinish: Bool {
        health.isActive || today.session.map { $0.endedAt == nil && $0.logs.contains { !$0.sets.isEmpty } } == true
    }

    /// There's something today to throw away: anything logged, or a Health workout under way.
    var canDiscard: Bool {
        health.isActive || today.session.map { !$0.logs.isEmpty } == true
    }

    /// Ends the Health workout, if one is under way, and marks today's session finished. The workout is saved to
    /// Health without asking when saving is on in the phone's Settings, and thrown away when it's off.
    func finishWorkout() async {
        stopEverything()
        let duration = health.elapsed ?? today.session.map { Date.now.timeIntervalSince($0.date) }
        let average = health.averageHeartRate
        let energy = health.energy
        let workoutId: UUID?
        if today.settings.healthWorkouts {
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
        summary = Summary(title: today.day.headline, savedToHealth: workoutId != nil, duration: duration,
                          averageHeartRate: average, energy: energy, sets: sets)
        today.refresh()
    }

    /// Throws today's workout away: everything logged today is deleted, here and on the phone, a Health workout
    /// under way isn't saved, and one saved at Finish is deleted from Health.
    func discardWorkout() {
        stopEverything()
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

    /// None is under way, the day has sets to log and today's session isn't finished. A Health workout runs even
    /// with saving to Health off: it keeps the app awake with the wrist down, so rests end on time with their
    /// haptics, and Finish throws it away.
    var canStartHealth: Bool {
        LaunchOptions.healthKit && health.isAvailable && health.state == .idle
            && today.day.items.contains { $0.kind != .checklist }
            && today.session?.endedAt == nil
    }

    /// Finish will save a Health workout: one is under way and saving is on in the phone's Settings.
    var savesToHealth: Bool {
        health.isActive && today.settings.healthWorkouts
    }

    static let accessDeniedMessage = "SpotMe isn't allowed to save workouts. On your iPhone, open the Health app, "
        + "tap your profile picture, then Apps → SpotMe, and turn everything on."

    /// Starts the Health workout when it should run. Tapping Start workout explains a failure; starting by
    /// itself (opening an exercise) stays quiet and isn't tried again.
    private func startHealth(explicitly: Bool) {
        guard canStartHealth, explicitly || !autoStartFailed else { return }
        // With saving off it's only there to keep the app awake: it never asks for access or explains a failure.
        let saving = today.settings.healthWorkouts
        guard saving || health.access == .allowed else { return }
        Task {
            let started = await health.start()
            onStartAttempted?()
            autoStartFailed = !started
            if started, pausedHere { health.pause() }
            guard !started, explicitly, saving else { return }
            startProblem = health.access == .denied
                ? Self.accessDeniedMessage
                : "The Health workout didn't start. Your sets are still being logged."
        }
    }

    // MARK: Internals

    /// A set was logged or a hold started: a paused workout carries on, and logging after Finish reopens the
    /// session.
    private func activity() {
        resume()
        guard let session = today.session, session.endedAt != nil else { return }
        session.endedAt = nil
        try? today.context.save()
    }

    /// An exercise's last set: a break as long as its rest (a short one before a checklist item), then the
    /// next item starts by itself.
    private func exerciseFinished() {
        guard let flow, let next = today.queue.upNext.first else { return }
        let seconds = next.kind == .checklist ? 15 : max(30, flow.items.last?.restSec ?? 90)
        let countdown = Countdown(seconds: TimeInterval(seconds))
        breakTime = countdown
        scheduleBreak(countdown)
    }

    #if DEBUG
    /// Screenshots: the break as it looks with `left` of its `length` seconds to go.
    func debugBreak(left: TimeInterval, of length: TimeInterval) {
        guard breakTime != nil else { return }
        let countdown = Countdown(seconds: length, from: Date.now.addingTimeInterval(left - length))
        breakTime = countdown
        scheduleBreak(countdown)
    }
    #endif

    private func scheduleBreak(_ countdown: Countdown) {
        breakAlarm.schedule(countdown, haptics: today.settings.restHaptics) { [weak self] in self?.advance() }
    }

    private func cancelBreak() {
        breakAlarm.cancel()
        breakTime = nil
        breakHeld = false
    }

    /// The workout is over, finished or discarded: nothing on screen, nothing counting down, nothing paused.
    private func stopEverything() {
        cancelBreak()
        flow?.stop()
        step = nil
        pausedHere = false
    }
}
