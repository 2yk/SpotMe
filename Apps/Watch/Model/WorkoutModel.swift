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
        /// How hard it was, 1 to 10, once answered.
        var effort: Int?
    }

    /// The Effort sheet shown after Finish, before the summary.
    struct EffortPrompt: Identifiable {
        let id = UUID()
        /// Where the Crown starts: the last workout's value, or 5.
        let initial: Int
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
    /// Paused from the controls (the workout's clock and heart rate stop; a running rest or break doesn't), or a
    /// Health workout that's paused, as one picked up after a relaunch can be.
    var isPaused: Bool { pausedHere || health.state == .paused }
    private var pausedHere = false
    /// The break waits while the next item is being picked.
    @ObservationIgnored private var breakHeld = false
    /// Shown once after Finish workout, after the Effort sheet.
    var summary: Summary?
    /// Asked after every Finish; closing it saves the workout without an effort.
    var effortPrompt: EffortPrompt?
    @ObservationIgnored private var pendingSummary: Summary?
    @ObservationIgnored private var finishedSession: WorkoutSession?
    @ObservationIgnored private var finishedWorkoutId: UUID?
    /// When the part of the session being run now began: Start again moves it. nil: with the session.
    @ObservationIgnored private var partStart: Date?
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

    /// The tick-off screen with steps scrolls to its Done button; the page dots stay out of its way.
    var stepScrolls: Bool {
        if case .checklist(let item) = currentStep { item.steps != nil } else { false }
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
            return Self.names(today.skipDestination(puttingOff: flow.items))
        case .checklist(let item):
            return Self.names(today.skipDestination(puttingOff: [item]))
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
        case .exercise(let flow): flow.isFinished ? !today.queue.upNext.isEmpty : !today.skipDestination(puttingOff: flow.items).isEmpty
        case .checklist(let item): !today.skipDestination(puttingOff: [item]).isEmpty
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
        today.stopWaiting(items)
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

    /// Skip, from the controls: puts the exercise on screen (or a tick-off item) off for later and moves on to
    /// the next open one. It stays open with its sets, and comes back after the last other exercise. During a
    /// rest the rest is dropped; coming back opens the next set. From a break it starts the next item now.
    func skip() {
        resume()
        switch currentStep {
        case .exercise(let flow) where !flow.isFinished:
            putOff(flow.items) { flow.stop() }
        case .exercise:
            advance()
        case .checklist(let item):
            putOff([item]) {}
        case .allDone, nil:
            break
        }
    }

    private func putOff(_ items: [PlanItem], stopping: () -> Void) {
        let destination = today.skipDestination(puttingOff: items)
        guard !destination.isEmpty else { return }
        stopping()
        cancelBreak()
        today.putOff(items)
        show(destination)
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

    /// Pause, from the controls: the workout's time and heart rate stop. A rest or a break that is running
    /// keeps counting and still ends with its haptic.
    func pause() {
        guard !isPaused else { return }
        pausedHere = true
        health.pause()
    }

    /// Carries on after a pause. Logging a set or starting a hold does this too.
    func resume() {
        guard isPaused else { return }
        pausedHere = false
        health.resume()
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

    /// Carries on with what was left of the break, at least a few seconds.
    func releaseBreak() {
        guard breakHeld else { return }
        breakHeld = false
        guard var countdown = breakTime else { return }
        countdown.resume(minimum: 5)
        breakTime = countdown
        scheduleBreak(countdown)
    }

    // MARK: Finishing

    /// The day is finished (Finish workout): Today shows Finished until Start again.
    var isDayFinished: Bool { today.isFinished }

    /// A workout is under way: a Health workout, or a screen on show. Whatever opens the app from outside (the
    /// complication, the icon) returns to it instead of starting another.
    var isRunning: Bool { step != nil || health.isActive }

    /// Today's session is open: logged into and not finished yet, or a Health workout is under way.
    var canFinish: Bool {
        health.isActive || today.session.map { $0.endedAt == nil && $0.logs.contains { !$0.orderedCountedSets.isEmpty } } == true
    }

    /// There's something today to throw away: anything logged, or a Health workout under way.
    var canDiscard: Bool {
        health.isActive || today.session.map { !$0.logs.isEmpty } == true
    }

    /// Ends the Health workout, if one is under way, and marks today's session finished. The workout is saved to
    /// Health without asking when saving is on in the phone's Settings, and thrown away when it's off. Finishing
    /// again after Start again saves a second Health workout; the session adds up their time and energy.
    func finishWorkout() async {
        stopEverything()
        let started = partStart ?? today.session?.date ?? .now
        let duration = health.elapsed ?? Date.now.timeIntervalSince(started)
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
            if let workoutId { session.saveWorkout(workoutId) }
            session.addPart(seconds: duration, energy: energy, averageHeartRate: average)
            try? today.recorder.finish(session)
            onSessionFinished?(session)
        }
        partStart = nil
        finishedSession = today.session
        finishedWorkoutId = workoutId
        let sets = today.session?.countedSetCount ?? 0
        pendingSummary = Summary(title: today.day.headline, savedToHealth: workoutId != nil, duration: duration,
                                 averageHeartRate: average, energy: energy, sets: sets)
        today.refresh()
        // The first time it starts from the last rated workout; after Start again, from the first answer.
        effortPrompt = EffortPrompt(initial: today.session?.effort ?? today.lastEffort() ?? 5)
    }

    /// The summary of a finished day, for the Finished card: what the session kept (time, energy, average heart
    /// rate, effort), over every part.
    func finishedSummary() -> Summary? {
        guard let session = today.session, let ended = session.endedAt else { return nil }
        var summary = Summary(title: today.day.headline, savedToHealth: session.healthKitWorkoutId != nil,
                              duration: session.activeSeconds ?? ended.timeIntervalSince(session.date),
                              averageHeartRate: session.averageHeartRate, energy: session.energyKcal,
                              sets: session.countedSetCount)
        summary.effort = session.effort
        return summary
    }

    /// Start again, from a finished Today: the same session picks up its open items. Done items stay done, a
    /// new Health workout starts, and the next open item (or the one tapped) opens as Start workout would.
    func startAgain(opening item: PlanItem? = nil) {
        guard let session = today.session, session.endedAt != nil else { return }
        try? today.recorder.reopen(session)
        today.refresh()
        partStart = .now
        autoStartFailed = false
        reconcile()
        startHealth(explicitly: true)
        if let item { open(item) } else { advance() }
    }

    /// Save on the Effort sheet: kept with the session (and sent to the phone again) and given to Health as the
    /// workout's effort rating when the workout was saved there. A second answer replaces the first.
    func saveEffort(_ effort: Int) {
        pendingSummary?.effort = effort
        if let session = finishedSession {
            try? today.recorder.setEffort(effort, on: session)
            onSessionFinished?(session)
        }
        if let id = finishedWorkoutId {
            Task { await health.saveEffort(effort, workoutId: id) }
        }
    }

    /// The Effort sheet is gone, saved or closed: on to the summary.
    func effortClosed() {
        effortPrompt = nil
        summary = pendingSummary
        pendingSummary = nil
        finishedSession = nil
        finishedWorkoutId = nil
    }

    /// Throws today's workout away: everything logged today is deleted, here and on the phone, a Health workout
    /// under way isn't saved, and every workout SpotMe saved to Health for it (Finish saves one, Start again
    /// another) is deleted. Today's swaps go too.
    func discardWorkout() {
        stopEverything()
        health.discard()
        if let session = today.session {
            let id = session.id
            let savedWorkouts = session.savedWorkoutIds
            do {
                try today.recorder.delete(session)
                onSessionDiscarded?(id)
            } catch {
                Logger.store.error("Couldn't discard the workout: \(error.localizedDescription)")
            }
            if !savedWorkouts.isEmpty {
                Task { for saved in savedWorkouts { await health.deleteWorkout(id: saved) } }
            }
        }
        partStart = nil
        autoStartFailed = false
        today.clearWaiting()
        today.clearSwaps()
    }

    // MARK: Swap

    /// Swaps `item` (on screen, or next up) for today; the screen on show moves to the swapped-in exercise.
    func swap(_ item: PlanItem, to choice: SwapChoice) {
        today.swap(item, to: choice)
        swapsChanged()
    }

    /// Today's swaps changed, here or on the phone: an exercise on screen that was swapped becomes the
    /// swapped-in one, wherever it is in its sets, with its own history. A break shows the new one by itself.
    func swapsChanged() {
        guard case .exercise(let flow) = step, !flow.isFinished else { return }
        let items = flow.slotIds.compactMap { slot in
            today.day.items.first { $0.exerciseId == slot || today.slotOf[$0.exerciseId] == slot }
        }
        guard items.count == flow.items.count, items.map(\.exerciseId) != flow.itemIds else { return }
        show(items)
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
        today.refresh()
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
