import XCTest
import SwiftData
@testable import RepCoachCore

final class HistoryStoreTests: StoreTestCase {

    func testEmptyStoreHasNoHistory() throws {
        XCTAssertEqual(try history.history(for: "incline-db-press"), [])
    }

    func testNewestFirst() throws {
        try logSession("incline-db-press", on: sept(7), [(20, 8), (20, 8)])
        try logSession("incline-db-press", on: sept(21), [(22.5, 7), (22.5, 6)])
        try logSession("incline-db-press", on: sept(14), [(20, 10), (20, 10)])

        XCTAssertEqual(try history.history(for: "incline-db-press"), [
            sets([(22.5, 7), (22.5, 6)]),
            sets([(20, 10), (20, 10)]),
            sets([(20, 8), (20, 8)]),
        ])
    }

    func testDeloadSessionsLeftOutOfHistoryButKeptAsEntries() throws {
        try logSession("leg-press", on: sept(8), dayKey: "tuesday", [(100, 10)])
        try logSession("leg-press", on: sept(15), dayKey: "tuesday", deload: true, [(90, 10)])

        XCTAssertEqual(try history.history(for: "leg-press"), [sets([(100, 10)])])
        let entries = try history.entries(for: "leg-press")
        XCTAssertEqual(entries.map(\.isDeload), [true, false])
        XCTAssertEqual(entries.first?.sets, sets([(90, 10)]))
    }

    func testTodaysSessionCanBeExcluded() throws {
        try logSession("face-pulls", on: sept(14), [(20, 15)])
        let today = try logSession("face-pulls", on: sept(21), [(22.5, 12)])

        XCTAssertEqual(try history.history(for: "face-pulls", excluding: today.id), [sets([(20, 15)])])
        XCTAssertEqual(try history.history(for: "face-pulls").count, 2)
    }

    func testSetsComeBackInTheOrderPerformed() throws {
        let session = try recorder.startSession(for: "monday", on: sept(14), isDeload: false)
        let log = try recorder.log(for: "hammer-curl", in: session)
        for (index, reps) in [(3, 10), (1, 12), (2, 11)] {
            let set = SetLog(index: index, weight: 12.5, reps: reps, timestamp: sept(14))
            context.insert(set)
            set.log = log
        }
        try context.save()

        XCTAssertEqual(try history.history(for: "hammer-curl"), [sets([(12.5, 12), (12.5, 11), (12.5, 10)])])
    }

    func testItemsWithoutSetsAreLeftOut() throws {
        let session = try recorder.startSession(for: "monday", on: sept(14), isDeload: false)
        try recorder.skip(try recorder.log(for: "incline-db-curl", in: session))
        try recorder.complete(try recorder.log(for: "recovery-run", in: session))

        XCTAssertEqual(try history.history(for: "incline-db-curl"), [])
        XCTAssertEqual(try history.loggedExerciseIds(), [])
    }

    func testOnlyTheRequestedExercise() throws {
        let session = try logSession("preacher-curl", on: sept(17), dayKey: "thursday", [(20, 10)])
        let other = try recorder.log(for: "reverse-pec-deck", in: session)
        try recorder.addSet(to: other, weight: 35, reps: 15)

        XCTAssertEqual(try history.history(for: "preacher-curl"), [sets([(20, 10)])])
        XCTAssertEqual(try history.loggedExerciseIds(), ["preacher-curl", "reverse-pec-deck"])
    }

    func testTimedSetsCarrySecondsAsReps() throws {
        let session = try recorder.startSession(for: "sunday", on: sept(20), isDeload: false)
        let log = try recorder.log(for: "weighted-plank", in: session)
        try recorder.addSet(to: log, weight: 10, reps: 0, seconds: 42)

        XCTAssertEqual(try history.history(for: "weighted-plank"), [[LoggedSet(weight: 10, reps: 42)]])
    }

    /// SPEC acceptance check 1, at the data level: 5 × 5 at 15 kg on two Mondays → 17.5 kg on the third.
    func testWeightedPullUpsProgressAfterTwoCleanMondays() throws {
        let item = try XCTUnwrap(try Plan.bundled().day(forWeekday: 2)?.items.first { $0.exerciseId == "weighted-pull-ups" })
        let p = try XCTUnwrap(Prescription(item: item))

        XCTAssertEqual(ProgressionEngine.firstTarget(for: p, history: try history.history(for: item.exerciseId)).reason,
                       .firstTime)

        try logSession(item.exerciseId, on: sept(7), Array(repeating: (15, 5), count: 5))
        XCTAssertEqual(ProgressionEngine.firstTarget(for: p, history: try history.history(for: item.exerciseId)),
                       SessionTarget(weight: 15, sets: 5, reason: .repeatWeight))

        try logSession(item.exerciseId, on: sept(14), Array(repeating: (15, 5), count: 5))
        XCTAssertEqual(ProgressionEngine.firstTarget(for: p, history: try history.history(for: item.exerciseId)),
                       SessionTarget(weight: 17.5, sets: 5, reason: .increase))
    }
}
