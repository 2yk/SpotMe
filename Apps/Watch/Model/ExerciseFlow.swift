import Foundation
import OSLog
import RepCoachCore

/// Runs one exercise, or a superset pair, set by set: log → rest → next set → summary.
@MainActor @Observable
final class ExerciseFlow {
    enum Phase: Equatable {
        case set
        case rest(Rest)
        case finished([Summary])
    }

    struct Rest: Equatable {
        var endsAt: Date
        var duration: TimeInterval
    }

    struct Summary: Equatable, Identifiable {
        var id: String
        var name: String
        var line: Coach.Line
    }

    let items: [PlanItem]
    let targets: [ItemTarget]
    let steps: [SetStep]
    private(set) var stepIndex = 0
    private(set) var phase: Phase = .set

    /// The values on the set screen. Doubles because the Digital Crown works in floating point.
    var weight = 0.0
    var reps = 0.0
    /// Timed sets: when the current hold started.
    private(set) var holdStartedAt: Date?

    /// Working weight per item; `ProgressionEngine.nextSet` moves it after every logged set.
    private var workingWeight: [Double]
    /// The engine's verdict on each item's last set, shown while resting.
    private var coaching: [Coach.Line?]
    private var undoStack: [Snapshot] = []
    @ObservationIgnored private var timers: [Task<Void, Never>] = []
    @ObservationIgnored private let today: TodayModel
    @ObservationIgnored private let onSetLogged: () -> Void
    @ObservationIgnored private let onFinished: () -> Void

    private struct Snapshot {
        var stepIndex: Int
        var workingWeight: [Double]
        var coaching: [Coach.Line?]
    }

    /// - Parameters:
    ///   - onSetLogged: called after each set is saved.
    ///   - onFinished: called when the last set is logged, to move the workout on.
    init(items: [PlanItem], today: TodayModel, onSetLogged: @escaping () -> Void = {},
         onFinished: @escaping () -> Void = {}) {
        self.items = items
        self.today = today
        self.onSetLogged = onSetLogged
        self.onFinished = onFinished
        targets = items.map { today.target(for: $0) }
        steps = SetSequence.steps(sets: targets.map(\.sets), rest: items.map { $0.restSec ?? 60 })
        workingWeight = targets.map { $0.weight ?? 0 }
        coaching = items.map { _ in nil }
        resume()
    }

    // MARK: State

    var itemIds: [String] { items.map(\.exerciseId) }
    var current: SetStep? { stepIndex < steps.count ? steps[stepIndex] : nil }
    var currentItem: PlanItem { items[current?.item ?? 0] }
    var currentTarget: ItemTarget { targets[current?.item ?? 0] }
    var canUndo: Bool { !undoStack.isEmpty }
    var isSuperset: Bool { items.count > 1 }

    var isFinished: Bool {
        if case .finished = phase { true } else { false }
    }

    /// Crown step for the weight value.
    var increment: Double { currentItem.increment ?? 2.5 }

    /// First session on a weighted exercise: the weight has to be chosen.
    var needsStartingWeight: Bool {
        currentItem.kind == .weighted && workingWeight[current?.item ?? 0] == 0
    }

    /// What's coming after the rest: "Set 3 of 4 · 17.5 kg".
    var nextSetLine: String {
        guard let step = current else { return "" }
        let item = items[step.item]
        var parts = [isSuperset ? item.name : "Set \(step.set) of \(targets[step.item].sets)"]
        if item.takesWeight, workingWeight[step.item] > 0 {
            parts.append(Format.kg(workingWeight[step.item]))
        } else if let perSet = Format.perSet(item, targets[step.item]) {
            parts.append(perSet)
        }
        return parts.joined(separator: " · ")
    }

    /// The engine's verdict on the last set of the item coming up next.
    var coachingLine: Coach.Line? {
        current.flatMap { coaching[$0.item] }
    }

    // MARK: Actions

    func logSet(seconds: Int? = nil) {
        guard let step = current else { return }
        let item = items[step.item]
        let loggedWeight = item.takesWeight ? weight : 0
        let loggedReps = Int(reps.rounded())
        do {
            let log = try today.recorder.log(for: item.exerciseId, in: try today.startSession())
            try today.recorder.addSet(to: log, weight: loggedWeight, reps: seconds == nil ? loggedReps : 0,
                                      seconds: seconds)
        } catch {
            Logger.store.error("Couldn't log a set: \(error.localizedDescription)")
            return
        }
        undoStack.append(Snapshot(stepIndex: stepIndex, workingWeight: workingWeight, coaching: coaching))
        Haptics.play(.logged)
        onSetLogged()

        if item.kind == .weighted, let p = Prescription(item: item) {
            let next = ProgressionEngine.nextSet(for: p, weight: loggedWeight, reps: loggedReps,
                                                 setIndex: step.set, totalSets: targets[step.item].sets)
            workingWeight[step.item] = next.weight
            coaching[step.item] = Coach.nextSet(next, reps: loggedReps, repMin: p.repMin, repMax: p.repMax)
        } else {
            workingWeight[step.item] = loggedWeight
        }

        holdStartedAt = nil
        stepIndex += 1
        guard current != nil else { return finish() }
        prefill()
        if let rest = step.restAfter, rest > 0 {
            startRest(seconds: rest)
        } else {
            phase = .set
        }
        today.refresh()
    }

    func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        cancelTimers()
        if isFinished {
            for item in items {
                if let log = today.log(for: item) { try? today.recorder.reopen(log) }
            }
        }
        let item = items[steps[snapshot.stepIndex].item]
        let removed = today.log(for: item).flatMap { try? today.recorder.removeLastSet(from: $0) }
        stepIndex = snapshot.stepIndex
        workingWeight = snapshot.workingWeight
        coaching = snapshot.coaching
        holdStartedAt = nil
        phase = .set
        prefill()
        if let removed, item.kind != .timed {
            weight = removed.weight
            reps = Double(removed.reps)
        }
        today.refresh()
    }

    func addRest(_ seconds: Int) {
        guard case .rest(var rest) = phase else { return }
        rest.endsAt += TimeInterval(seconds)
        rest.duration += TimeInterval(seconds)
        phase = .rest(rest)
        scheduleRestHaptics(rest)
    }

    func endRest() {
        cancelTimers()
        if case .rest = phase { phase = .set }
    }

    /// Cancels pending rest and hold haptics; call before dropping the flow.
    func stop() {
        cancelTimers()
    }

    func startHold() {
        let start = Date.now
        holdStartedAt = start
        cancelTimers()
        let marks = Set([currentItem.secMin, currentItem.secMax].compactMap { $0 })
        timers = marks.map { seconds in
            after(start.addingTimeInterval(TimeInterval(seconds))) { Haptics.play(.holdMark) }
        }
    }

    func stopHold() {
        guard let start = holdStartedAt else { return }
        cancelTimers()
        logSet(seconds: Int(Date.now.timeIntervalSince(start).rounded()))
    }

    // MARK: Internals

    /// Picks up where today's log left off, e.g. after going back to Today mid-exercise.
    private func resume() {
        let logged = items.map { today.log(for: $0)?.orderedSets.map(\.loggedSet) ?? [] }
        stepIndex = steps.firstIndex { $0.set > logged[$0.item].count } ?? steps.count
        for (index, sets) in logged.enumerated() {
            guard let last = sets.last else { continue }
            workingWeight[index] = last.weight
            if items[index].kind == .weighted, let p = Prescription(item: items[index]) {
                let next = ProgressionEngine.nextSet(for: p, weight: last.weight, reps: last.reps,
                                                     setIndex: sets.count, totalSets: targets[index].sets)
                workingWeight[index] = next.weight
                coaching[index] = Coach.nextSet(next, reps: last.reps, repMin: p.repMin, repMax: p.repMax)
            }
        }
        if current == nil {
            finish(haptic: false)
        } else {
            prefill()
        }
    }

    /// Fills the set screen: the working weight, and reps from the last set today, else the same set last
    /// time, else the top of the range; kept inside the range.
    private func prefill() {
        guard let step = current else { return }
        let item = items[step.item]
        let target = targets[step.item]
        weight = workingWeight[step.item]
        let previous = today.log(for: item)?.orderedSets.last?.reps
        let lastTime = today.pastSessions(of: item.exerciseId).first
        let sameSetLastTime = lastTime.flatMap { step.set <= $0.count ? $0[step.set - 1].reps : nil }
        switch item.kind {
        case .percentOfMax:
            reps = Double(target.repMax ?? previous ?? 5)
        case .amrap:
            reps = Double(sameSetLastTime ?? 10)
        default:
            let guess = previous ?? sameSetLastTime ?? target.repMax ?? 10
            if let low = target.repMin, let high = target.repMax {
                reps = Double(min(max(guess, low), high))
            } else {
                reps = Double(guess)
            }
        }
    }

    private func startRest(seconds: Int) {
        let rest = Rest(endsAt: .now.addingTimeInterval(TimeInterval(seconds)), duration: TimeInterval(seconds))
        phase = .rest(rest)
        scheduleRestHaptics(rest)
    }

    private func scheduleRestHaptics(_ rest: Rest) {
        cancelTimers()
        let haptics = today.settings.restHaptics
        let warning = rest.endsAt.addingTimeInterval(-10)
        if warning > .now {
            timers.append(after(warning) { if haptics { Haptics.play(.restWarning) } })
        }
        timers.append(after(rest.endsAt) { [weak self] in
            if haptics { Haptics.play(.restOver) }
            self?.endRest()
        })
    }

    private func finish(haptic: Bool = true) {
        cancelTimers()
        guard let session = try? today.startSession() else { return }
        var summaries: [Summary] = []
        for (index, item) in items.enumerated() {
            guard let log = try? today.recorder.log(for: item.exerciseId, in: session) else { continue }
            if log.completedAt == nil { try? today.recorder.complete(log) }
            let sets = log.orderedSets.map(\.loggedSet)
            summaries.append(Summary(id: item.exerciseId, name: item.name,
                                     line: summary(item, target: targets[index], sets: sets, deload: session.isDeload)))
        }
        phase = .finished(summaries)
        today.refresh()
        // Only a set logged just now moves the workout on; reopening a finished exercise doesn't.
        if haptic {
            Haptics.play(.exerciseDone)
            onFinished()
        }
    }

    private func summary(_ item: PlanItem, target: ItemTarget, sets: [LoggedSet], deload: Bool) -> Coach.Line {
        switch item.kind {
        case .weighted:
            guard let p = Prescription(item: item) else { return Coach.Line("Logged", .done) }
            let next = ProgressionEngine.firstTarget(for: p, history: [sets] + today.pastSessions(of: item.exerciseId))
            return Coach.weightedSummary(today: sets, next: next, prescription: p, deload: deload)
        case .reps, .timed:
            let timed = item.kind == .timed
            let top = timed ? target.secMax : target.repMax
            let reached = top.map { ProgressionEngine.reachedTopOfRange(sets, top: $0, plannedSets: target.sets) }
            return Coach.rangeSummary(topReached: reached ?? false, top: top, timed: timed)
        case .amrap:
            let reps = sets.first?.reps ?? 0
            return Coach.amrapSummary(reps: reps, volumeReps: ProgressionEngine.volumeReps(amrap: reps))
        case .percentOfMax:
            return Coach.Line("\(sets.count) × \(target.repMax ?? sets.first?.reps ?? 0) done", .done)
        case .checklist:
            return Coach.Line("Done", .done)
        }
    }

    private func after(_ date: Date, _ action: @escaping @MainActor () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            let delay = date.timeIntervalSinceNow
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            guard !Task.isCancelled else { return }
            action()
        }
    }

    private func cancelTimers() {
        timers.forEach { $0.cancel() }
        timers = []
    }
}
