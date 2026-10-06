import XCTest
@testable import RepCoachCore

final class TargetPlannerTests: XCTestCase {

    func testWeightedFirstTime() throws {
        let rows = try planItem("chest-supported-db-row", on: "monday")
        let target = TargetPlanner.target(for: rows, history: [], deload: false)
        XCTAssertEqual(target.session?.reason, .firstTime)
        XCTAssertNil(target.weight)
        XCTAssertEqual(target.sets, 4)
        XCTAssertEqual(TargetPlanner.target(for: rows, history: [], deload: false, startWeight: 20).weight, 20)
    }

    func testWeightedFollowsTheEngine() throws {
        let rows = try planItem("chest-supported-db-row", on: "monday")
        let atTop = [Array(repeating: LoggedSet(weight: 20, reps: 10), count: 4)]

        let target = TargetPlanner.target(for: rows, history: atTop, deload: false)
        XCTAssertEqual(target.session, SessionTarget(weight: 22.5, sets: 4, reason: .increase))
        XCTAssertEqual(target.weight, 22.5)
        XCTAssertEqual([target.repMin, target.repMax], [8, 10])

        XCTAssertEqual(TargetPlanner.target(for: rows, history: atTop, deload: true).session,
                       SessionTarget(weight: 20, sets: 2, reason: .deload))
    }

    func testLoadableItemsReuseTheLastWeight() throws {
        let crunch = try planItem("cable-crunch", on: "wednesday")
        XCTAssertEqual(TargetPlanner.target(for: crunch, history: [[LoggedSet(weight: 32.5, reps: 15)]],
                                            deload: false).weight, 32.5)

        let legRaise = try planItem("hanging-leg-raise", on: "wednesday")
        XCTAssertNil(TargetPlanner.target(for: legRaise, history: [[LoggedSet(weight: 5, reps: 12)]],
                                          deload: false).weight)

        let plank = TargetPlanner.target(for: try planItem("weighted-plank", on: "sunday"),
                                         history: [[LoggedSet(weight: 10, reps: 40)]], deload: false)
        XCTAssertEqual(plank.weight, 10)
        XCTAssertEqual([plank.secMin, plank.secMax], [30, 45])
        XCTAssertEqual(plank.sets, 3)
    }

    /// SPEC acceptance check 5: a max-rep set of 12 → volume sets of 7.
    func testVolumeSetsFollowTheMaxRepSet() throws {
        let volume = try planItem("volume-sets", on: "thursday")
        let target = TargetPlanner.target(for: volume, history: [], deload: false, amrap: 12)
        XCTAssertEqual([target.repMin, target.repMax, target.amrap], [7, 7, 12])
        XCTAssertEqual(target.sets, 4)
        XCTAssertNil(TargetPlanner.target(for: volume, history: [], deload: false).repMin)
    }

    func testAmrapComesFromTodayThenHistory() {
        let last = [[LoggedSet(weight: 0, reps: 11)]]
        XCTAssertEqual(TargetPlanner.amrapReps(today: [LoggedSet(weight: 0, reps: 12)], history: last), 12)
        XCTAssertEqual(TargetPlanner.amrapReps(today: nil, history: last), 11)
        XCTAssertEqual(TargetPlanner.amrapReps(today: [], history: last), 11)
        XCTAssertNil(TargetPlanner.amrapReps(today: nil, history: []))
    }

    func testChecklistAndMaxRepSet() throws {
        XCTAssertEqual(TargetPlanner.target(for: try planItem("recovery-run", on: "monday"), history: [],
                                            deload: false).sets, 0)
        XCTAssertEqual(TargetPlanner.target(for: try planItem("max-rep-set", on: "thursday"), history: [],
                                            deload: false).sets, 1)
    }

    func testOverrides() throws {
        let rows = try planItem("chest-supported-db-row", on: "monday")
        let edited = rows.applying(ExerciseOverrides(increment: 1, repMin: 10, repMax: 12, sets: 3, restSec: 90))
        XCTAssertEqual([edited.sets, edited.repMin, edited.repMax, edited.restSec], [3, 10, 12, 90])
        XCTAssertEqual(edited.increment, 1)
        XCTAssertEqual(rows.applying(ExerciseOverrides(sets: 5)).repMin, 8)
        XCTAssertEqual(rows.applying(nil), rows)
        XCTAssertTrue(ExerciseOverrides().isEmpty)
        XCTAssertFalse(ExerciseOverrides(startWeight: 20).isEmpty)
    }
}

final class TodayQueueTests: XCTestCase {
    var monday: [PlanItem] = []
    let t0 = Date(timeIntervalSince1970: 1_790_000_000)

    override func setUpWithError() throws {
        monday = try XCTUnwrap(try Plan.bundled().day(forWeekday: 2)).items
    }

    func ids(_ items: [PlanItem]) -> [String] { items.map(\.exerciseId) }

    func testFreshDayStartsAtTheTop() {
        let queue = TodayQueue(items: monday, statuses: [:])
        XCTAssertEqual(ids(queue.upNext), ["recovery-run"])
        XCTAssertEqual(queue.remaining.count, 9)
        XCTAssertEqual(queue.finished, [])
        XCTAssertEqual([queue.doneCount, queue.totalCount], [0, 10])
        XCTAssertFalse(queue.isComplete)
    }

    /// SPEC acceptance check 3: finished items move to the bottom and the next item comes to the top.
    func testFinishedItemsMoveToTheBottomInOrder() {
        let queue = TodayQueue(items: monday, statuses: [
            "monday-warmup": .done(t0.addingTimeInterval(600)),
            "recovery-run": .done(t0),
        ])
        XCTAssertEqual(ids(queue.upNext), ["weighted-pull-ups"])
        XCTAssertEqual(ids(queue.finished), ["recovery-run", "monday-warmup"])
        XCTAssertEqual(queue.doneCount, 2)
    }

    /// SPEC acceptance check 4: tapping a later item makes it up next.
    func testPromotedItemIsUpNext() {
        let queue = TodayQueue(items: monday, statuses: [:], promoted: "face-pulls")
        XCTAssertEqual(ids(queue.upNext), ["face-pulls"])
        XCTAssertEqual(ids(queue.remaining).first, "recovery-run")
        XCTAssertFalse(ids(queue.remaining).contains("face-pulls"))
    }

    func testExerciseInProgressStaysUpNextUnlessAnotherIsPromoted() {
        let statuses: [String: ItemStatus] = ["hammer-curl": .inProgress(setsDone: 1)]
        XCTAssertEqual(ids(TodayQueue(items: monday, statuses: statuses).upNext), ["hammer-curl"])
        XCTAssertEqual(ids(TodayQueue(items: monday, statuses: statuses, promoted: "face-pulls").upNext), ["face-pulls"])
    }

    /// Skip puts an exercise off: it stays open where it is in the list, and the next one is up.
    func testAnExercisePutOffStaysOpenButIsNotUpNext() {
        let statuses: [String: ItemStatus] = [
            "recovery-run": .done(t0), "monday-warmup": .done(t0), "weighted-pull-ups": .inProgress(setsDone: 2),
        ]
        let queue = TodayQueue(items: monday, statuses: statuses, waiting: ["weighted-pull-ups"])
        XCTAssertEqual(ids(queue.upNext), ["chest-supported-db-row"])
        XCTAssertTrue(ids(queue.remaining).contains("weighted-pull-ups"))
        XCTAssertEqual(queue.totalCount, 10)
        XCTAssertFalse(queue.isComplete)
    }

    /// They come back after the last exercise, before the tick-off items (neck work, cooldown), in the order
    /// they were put off.
    func testExercisesPutOffComeBackBeforeTheCooldownInTheOrderPutOff() {
        let done = Set(["recovery-run", "monday-warmup", "chest-supported-db-row", "close-grip-lat-pulldown",
                        "face-pulls", "incline-db-curl", "hammer-curl"])
        var statuses = Dictionary(uniqueKeysWithValues: done.map { ($0, ItemStatus.done(t0)) })
        statuses["weighted-pull-ups"] = .inProgress(setsDone: 1)
        let queue = TodayQueue(items: monday, statuses: statuses, waiting: ["incline-db-curl", "weighted-pull-ups"])
        // incline-db-curl is done, so only the pull-ups wait.
        XCTAssertEqual(ids(queue.upNext), ["weighted-pull-ups"])

        var open = statuses
        open["face-pulls"] = nil
        open["close-grip-lat-pulldown"] = nil
        let two = TodayQueue(items: monday, statuses: open, waiting: ["weighted-pull-ups", "face-pulls"])
        XCTAssertEqual(ids(two.upNext), ["close-grip-lat-pulldown"])
        var rest = open
        rest["close-grip-lat-pulldown"] = .done(t0)
        XCTAssertEqual(ids(TodayQueue(items: monday, statuses: rest, waiting: ["weighted-pull-ups", "face-pulls"]).upNext),
                       ["weighted-pull-ups"])
        XCTAssertEqual(ids(TodayQueue(items: monday, statuses: rest, waiting: ["face-pulls", "weighted-pull-ups"]).upNext),
                       ["face-pulls"])
    }

    func testTappingAWaitingExerciseDoesItNow() {
        let queue = TodayQueue(items: monday, statuses: [:], promoted: "face-pulls", waiting: ["face-pulls"])
        XCTAssertEqual(ids(queue.upNext), ["face-pulls"])
    }

    func testPromotingAFinishedItemDoesNothing() {
        let queue = TodayQueue(items: monday, statuses: ["recovery-run": .skipped(t0)], promoted: "recovery-run")
        XCTAssertEqual(ids(queue.upNext), ["monday-warmup"])
        XCTAssertEqual(ids(queue.finished), ["recovery-run"])
    }

    func testSupersetComesUpAsAPair() throws {
        let friday = try XCTUnwrap(try Plan.bundled().day(forWeekday: 6)).items
        let pair = ["bayesian-cable-curl", "cable-overhead-extension"]

        let queue = TodayQueue(items: friday, statuses: [:], promoted: "cable-overhead-extension")
        XCTAssertEqual(ids(queue.upNext), pair)
        XCTAssertFalse(ids(queue.remaining).contains { pair.contains($0) })

        let half = TodayQueue(items: friday, statuses: ["bayesian-cable-curl": .done(t0)],
                              promoted: "cable-overhead-extension")
        XCTAssertEqual(ids(half.upNext), ["cable-overhead-extension"])
    }

    func testEverythingDone() {
        let statuses = Dictionary(uniqueKeysWithValues: monday.enumerated().map {
            ($1.exerciseId, ItemStatus.done(t0.addingTimeInterval(Double($0))))
        })
        let queue = TodayQueue(items: monday, statuses: statuses)
        XCTAssertTrue(queue.isComplete)
        XCTAssertEqual(ids(queue.finished), ids(monday))
    }
}

final class SetSequenceTests: XCTestCase {

    func testSingleExerciseRestsBetweenSets() {
        XCTAssertEqual(SetSequence.steps(sets: [3], rest: [75]), [
            SetStep(item: 0, set: 1, restAfter: 75),
            SetStep(item: 0, set: 2, restAfter: 75),
            SetStep(item: 0, set: 3, restAfter: nil),
        ])
    }

    /// SPEC acceptance check 6: the Friday superset alternates, with rest after each pair.
    func testSupersetAlternatesAndRestsAfterEachPair() {
        XCTAssertEqual(SetSequence.steps(sets: [3, 3], rest: [75, 90]), [
            SetStep(item: 0, set: 1, restAfter: nil), SetStep(item: 1, set: 1, restAfter: 90),
            SetStep(item: 0, set: 2, restAfter: nil), SetStep(item: 1, set: 2, restAfter: 90),
            SetStep(item: 0, set: 3, restAfter: nil), SetStep(item: 1, set: 3, restAfter: nil),
        ])
    }

    func testUnevenSuperset() {
        let steps = SetSequence.steps(sets: [3, 2], rest: [60, 60])
        XCTAssertEqual(steps.map { [$0.item, $0.set] }, [[0, 1], [1, 1], [0, 2], [1, 2], [0, 3]])
        XCTAssertEqual(steps.map(\.restAfter), [nil, 60, nil, 60, nil])
    }

    func testNoSets() {
        XCTAssertEqual(SetSequence.steps(sets: [0], rest: [60]), [])
        XCTAssertEqual(SetSequence.steps(sets: [], rest: []), [])
    }
}
