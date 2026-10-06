import Foundation
import OSLog
import RepCoachCore

/// Runs one exercise, or a superset pair, set by set: log → rest → next set → summary.
@MainActor @Observable
final class ExerciseFlow {
    enum Phase: Equatable {
        case set
        case rest(Countdown)
        case finished([Summary])
    }

    /// One lighter set before the first working set: tapped off, never counted.
    struct RampStep: Equatable {
        /// Index into `items`.
        var item: Int
        var weight: Double
        var reps: Int
        /// 1-based within its exercise, and how many that exercise has.
        var number: Int
        var of: Int
        /// The last of a round: a 60 s rest follows (a superset pair goes back to back first).
        var endsRound: Bool
        /// Bodyweight plus the working weight (weighted pull-ups): the first ramp-up is bodyweight alone.
        var bodyweight: Bool
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
    /// The weight of each item's last logged set, to tell whether the next set is heavier or lighter.
    private var lastLoggedWeight: [Double?]
    /// Each item's counted sessions before today, newest first: "Last 9" and the first prefill.
    private let past: [[[LoggedSet]]]
    /// The engine's verdict on each item's last set, shown while resting.
    private var coaching: [Coach.Line?]
    /// The ramp-up sets still to do before the first working set, in the order they come.
    private(set) var rampSteps: [RampStep] = []
    private(set) var rampIndex = 0
    private var undoStack: [Snapshot] = []
    @ObservationIgnored private let restAlarm = CountdownAlarm()
    @ObservationIgnored private var holdMarks: [Task<Void, Never>] = []
    @ObservationIgnored private let today: TodayModel
    @ObservationIgnored private let onActivity: () -> Void
    @ObservationIgnored private let onFinished: () -> Void

    private struct Snapshot {
        var stepIndex: Int
        var workingWeight: [Double]
        var lastLoggedWeight: [Double?]
        var coaching: [Coach.Line?]
    }

    /// - Parameters:
    ///   - onActivity: called when a set is saved or a hold starts.
    ///   - onFinished: called when the last set is logged, to move the workout on.
    init(items: [PlanItem], today: TodayModel, onActivity: @escaping () -> Void = {},
         onFinished: @escaping () -> Void = {}) {
        self.items = items
        self.today = today
        self.onActivity = onActivity
        self.onFinished = onFinished
        targets = items.map { today.target(for: $0) }
        steps = SetSequence.steps(sets: targets.map(\.sets), rest: items.map { $0.restSec ?? 60 })
        workingWeight = targets.map { $0.weight ?? 0 }
        lastLoggedWeight = items.map { _ in nil }
        past = items.map { today.pastSessions(of: $0.exerciseId) }
        coaching = items.map { _ in nil }
        offsets = items.map { _ in 0 }
        totals = items.map { _ in 0 }
        resume()
        planRampUps()
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

    /// What's coming after the rest, as the rest screen shows it.
    struct NextSet: Equatable {
        enum Change: Equatable { case up, down }
        /// "NEXT · SET 3 OF 4", or the exercise's name in a superset.
        var eyebrow: String
        /// "22.5 kg", or the reps for an exercise without a weight.
        var value: String
        /// The weight went up or down since the set just logged.
        var change: Change?
        /// The part of the engine's line before " · ": "5 reps, below 6".
        var reason: String?
    }

    var nextSet: NextSet {
        // Resting between ramp-ups: the next one, or set 1 after the last.
        if let ramp = currentRampStepAfterRest {
            let item = items[ramp.item]
            let value = ramp.bodyweight ? "Bodyweight" : Format.kg(ramp.weight)
            _ = item
            return NextSet(eyebrow: "Next · ramp-up \(ramp.number) of \(ramp.of)", value: value, change: nil,
                           reason: "\(ramp.reps) reps · not counted")
        }
        guard let step = current else { return NextSet(eyebrow: "", value: "", change: nil, reason: nil) }
        let item = items[step.item]
        let eyebrow = isSuperset ? "Next · \(item.name)" : "Next · set \(step.set) of \(targets[step.item].sets)"
        let weight = workingWeight[step.item]
        let value: String
        var change: NextSet.Change?
        if item.takesWeight, weight > 0 {
            value = Format.kg(weight)
            if let last = lastLoggedWeight[step.item], last != weight { change = weight > last ? .up : .down }
        } else {
            value = Format.perSet(item, targets[step.item]).map { item.kind == .timed || item.perSide == true ? $0 : "\($0) reps" }
                ?? ""
        }
        var reason = coaching[step.item].map { $0.text.components(separatedBy: " · ")[0] }
        // After the last ramp-up: how the same set went last time.
        if rampSteps.count > 0, rampIndex >= rampSteps.count, lastLoggedWeight[step.item] == nil,
           let last = lastTimeReps(of: step.item, set: step.set) {
            reason = "Last time \(last) reps"
        }
        return NextSet(eyebrow: eyebrow, value: value, change: change, reason: reason)
    }

    /// While resting after a ramp-up and another one is still to come.
    private var currentRampStepAfterRest: RampStep? {
        guard case .rest = phase, rampIndex < rampSteps.count else { return nil }
        return rampSteps[rampIndex]
    }

    /// The engine's verdict on the last set of the item coming up next.
    var coachingLine: Coach.Line? {
        current.flatMap { coaching[$0.item] }
    }

    /// The same set in the last counted session, for "Last 9": reps, or seconds for a hold. nil with no history.
    var lastTimeValue: Int? {
        guard let step = current, let last = past[step.item].first, step.set <= last.count else { return nil }
        return last[step.set - 1].reps
    }

    /// The exercise has been done before (sessions other than today's, deloads aside).
    var hasHistory: Bool {
        current.map { !past[$0.item].isEmpty } ?? false
    }

    /// The reps of the last set of `item` in the last session, for the rest after a ramp-up.
    func lastTimeReps(of item: Int, set: Int) -> Int? {
        guard let last = past[item].first, set >= 1, set <= last.count else { return nil }
        return last[set - 1].reps
    }

    // MARK: Ramp-ups

    /// The ramp-up on screen: the first working set isn't open yet.
    var currentRamp: RampStep? {
        guard case .set = phase, rampIndex < rampSteps.count else { return nil }
        return rampSteps[rampIndex]
    }

    /// The working weight a ramp-up leads to, as the ramp-up screen shows it: "22.5 kg", or "+15 kg" for
    /// weighted pull-ups.
    func workingWeightLabel(forItem index: Int) -> String {
        let weight = targets[index].weight ?? 0
        return items[index].bodyweightBase == true ? "+\(Format.kg(weight))" : Format.kg(weight)
    }

    /// Done on the ramp-up screen: saved as a set marked ramp-up, never counted. Between a superset pair the
    /// next one follows at once; otherwise a 60 s rest.
    func doneRampUp() {
        guard let step = currentRamp else { return }
        let item = items[step.item]
        do {
            let log = try today.recorder.log(for: item.exerciseId, in: try today.startSession())
            try today.recorder.addSet(to: log, weight: step.weight, reps: step.reps, isRampUp: true)
        } catch {
            Logger.store.error("Couldn't log a ramp-up: \(error.localizedDescription)")
            return
        }
        Haptics.play(.logged)
        onActivity()
        rampIndex += 1
        prefill()
        if step.endsRound {
            startRest(seconds: ProgressionEngine.restAfterRampUpSec)
        }
        today.refresh()
    }

    /// Skip on the ramp-up screen: no more ramp-ups for this exercise today; set 1 opens at once.
    func skipRampUps() {
        today.skipRampUps(items)
        rampSteps = []
        rampIndex = 0
    }

    /// Works out the ramp-ups: for weighted exercises with a working weight, no working set logged today and
    /// the ramp-ups not skipped, from the first one not yet done.
    private func planRampUps() {
        guard today.settings.rampUps != .off else { return }
        var perItem: [[(weight: Double, reps: Int)]] = items.map { _ in [] }
        for (index, item) in items.enumerated() where item.kind == .weighted {
            let log = today.log(for: item)
            guard log?.orderedCountedSets.isEmpty ?? true, !today.rampUpsSkipped(item),
                  let dayIndex = today.day.items.firstIndex(where: { $0.exerciseId == item.exerciseId })
            else { continue }
            let done = log?.orderedSets.filter(\.isRampUp).count ?? 0
            let all = ProgressionEngine.rampUps(
                working: targets[index].weight, increment: item.increment ?? 2.5,
                repMax: targets[index].repMax ?? 10,
                role: ProgressionEngine.rampUpRole(dayItems: today.day.items, index: dayIndex),
                setting: today.settings.rampUps, bodyweightBase: item.bodyweightBase == true)
            perItem[index] = Array(all.dropFirst(done))
            // Numbers count from the first ramp-up of the exercise, done or not.
            offsets[index] = done
            totals[index] = all.count
        }
        var steps: [RampStep] = []
        for round in 0..<(perItem.map(\.count).max() ?? 0) {
            let present = perItem.indices.filter { round < perItem[$0].count }
            for (position, index) in present.enumerated() {
                let set = perItem[index][round]
                steps.append(RampStep(item: index, weight: set.weight, reps: set.reps,
                                      number: offsets[index] + round + 1, of: totals[index],
                                      endsRound: position == present.count - 1,
                                      bodyweight: items[index].bodyweightBase == true && set.weight == 0))
            }
        }
        rampSteps = steps
        rampIndex = 0
    }
    @ObservationIgnored private var offsets: [Int] = []
    @ObservationIgnored private var totals: [Int] = []

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
        undoStack.append(Snapshot(stepIndex: stepIndex, workingWeight: workingWeight,
                                  lastLoggedWeight: lastLoggedWeight, coaching: coaching))
        Haptics.play(.logged)
        onActivity()

        lastLoggedWeight[step.item] = loggedWeight
        if item.kind == .weighted, let p = Prescription(item: item) {
            let next = ProgressionEngine.nextSet(for: p, weight: loggedWeight, reps: loggedReps,
                                                 setIndex: step.set, totalSets: targets[step.item].sets)
            workingWeight[step.item] = next.weight
            coaching[step.item] = Coach.nextSet(next, reps: loggedReps, repMin: p.repMin, repMax: p.repMax)
        } else {
            workingWeight[step.item] = loggedWeight
            coaching[step.item] = rangeLine(item, target: targets[step.item], value: seconds ?? loggedReps)
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
        stop()
        if isFinished {
            for item in items {
                if let log = today.log(for: item) { try? today.recorder.reopen(log) }
            }
        }
        let item = items[steps[snapshot.stepIndex].item]
        let removed = today.log(for: item).flatMap { try? today.recorder.removeLastSet(from: $0) }
        stepIndex = snapshot.stepIndex
        workingWeight = snapshot.workingWeight
        lastLoggedWeight = snapshot.lastLoggedWeight
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
        rest.add(TimeInterval(seconds))
        phase = .rest(rest)
        scheduleRest(rest)
    }

    func endRest() {
        restAlarm.cancel()
        if case .rest = phase { phase = .set }
    }

    /// The workout was paused: the rest holds where it is.
    func pauseRest() {
        guard case .rest(var rest) = phase, !rest.isPaused else { return }
        rest.pause()
        phase = .rest(rest)
        restAlarm.cancel()
    }

    func resumeRest() {
        guard case .rest(var rest) = phase, rest.isPaused else { return }
        rest.resume()
        phase = .rest(rest)
        scheduleRest(rest)
    }

    /// Cancels pending rest and hold haptics; call before dropping the flow.
    func stop() {
        restAlarm.cancel()
        holdMarks.forEach { $0.cancel() }
        holdMarks = []
    }

    func startHold() {
        let start = Date.now
        holdStartedAt = start
        stop()
        onActivity()
        let marks = Set([currentItem.secMin, currentItem.secMax].compactMap { $0 })
        holdMarks = marks.map { seconds in
            CountdownAlarm.after(start.addingTimeInterval(TimeInterval(seconds))) { Haptics.play(.holdMark) }
        }
    }

    func stopHold() {
        guard let start = holdStartedAt else { return }
        stop()
        logSet(seconds: Int(Date.now.timeIntervalSince(start).rounded()))
    }

    // MARK: Internals

    /// Picks up where today's log left off, e.g. after going back to Today mid-exercise.
    private func resume() {
        let logged = items.map { today.log(for: $0)?.countedLoggedSets ?? [] }
        stepIndex = steps.firstIndex { $0.set > logged[$0.item].count } ?? steps.count
        for (index, sets) in logged.enumerated() {
            guard let last = sets.last else { continue }
            workingWeight[index] = last.weight
            lastLoggedWeight[index] = last.weight
            if items[index].kind != .weighted {
                coaching[index] = rangeLine(items[index], target: targets[index], value: last.reps)
            }
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
        let previous = today.log(for: item)?.orderedCountedSets.last?.reps
        let sameSetLastTime = lastTimeValue
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

    /// Reps and timed exercises don't change weight; their rest just says where the last set landed.
    private func rangeLine(_ item: PlanItem, target: ItemTarget, value: Int) -> Coach.Line? {
        switch item.kind {
        case .reps:
            guard let low = target.repMin, let high = target.repMax else { return nil }
            return Coach.rangeLine(value, low: low, high: high)
        case .timed:
            guard let low = target.secMin, let high = target.secMax else { return nil }
            return Coach.rangeLine(value, low: low, high: high)
        default:
            return nil
        }
    }

    #if DEBUG
    /// Screenshots: the hold as it looks `elapsed` seconds in.
    func debugHold(elapsed: TimeInterval) {
        guard holdStartedAt != nil else { return }
        holdStartedAt = Date.now.addingTimeInterval(-elapsed)
    }

    /// Screenshots: the rest as it looks with `left` of its `length` seconds to go.
    func debugRest(left: TimeInterval, of length: TimeInterval) {
        guard case .rest = phase else { return }
        let rest = Countdown(seconds: length, from: Date.now.addingTimeInterval(left - length))
        phase = .rest(rest)
        scheduleRest(rest)
    }
    #endif

    private func startRest(seconds: Int) {
        let rest = Countdown(seconds: TimeInterval(seconds))
        phase = .rest(rest)
        scheduleRest(rest)
    }

    private func scheduleRest(_ rest: Countdown) {
        restAlarm.schedule(rest, haptics: today.settings.restHaptics) { [weak self] in self?.endRest() }
    }

    private func finish(haptic: Bool = true) {
        stop()
        guard let session = try? today.startSession() else { return }
        var summaries: [Summary] = []
        for (index, item) in items.enumerated() {
            guard let log = try? today.recorder.log(for: item.exerciseId, in: session) else { continue }
            if log.completedAt == nil { try? today.recorder.complete(log) }
            let sets = log.countedLoggedSets
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

}
