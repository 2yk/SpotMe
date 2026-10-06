import XCTest
import SwiftData
@testable import RepCoachCore

/// Ramp-up sets are saved and exported but never counted, and the effort rating of a finished workout.
final class RampUpStoreTests: StoreTestCase {

    /// Wednesday's incline press: two ramp-ups, then three working sets at 20 kg.
    @discardableResult
    func loggedWithRampUps(on date: Date, working: [(Double, Int)] = [(20, 12), (20, 12), (20, 12)],
                           deload: Bool = false) throws -> (WorkoutSession, ExerciseLog) {
        let session = try recorder.startSession(for: "wednesday", on: date, isDeload: deload)
        let log = try recorder.log(for: "incline-db-press", in: session)
        try recorder.addSet(to: log, weight: 10, reps: 8, at: date, isRampUp: true)
        try recorder.addSet(to: log, weight: 15, reps: 4, at: date, isRampUp: true)
        for (weight, reps) in working { try recorder.addSet(to: log, weight: weight, reps: reps, at: date) }
        try recorder.complete(log, at: date)
        return (session, log)
    }

    // MARK: Not counted

    func testRampUpsKeepOneSequenceButAreMarked() throws {
        let (_, log) = try loggedWithRampUps(on: sept(16))
        XCTAssertEqual(log.orderedSets.map(\.index), [1, 2, 3, 4, 5])
        XCTAssertEqual(log.orderedSets.map(\.isRampUp), [true, true, false, false, false])
        XCTAssertEqual(log.orderedCountedSets.map(\.index), [3, 4, 5])
        XCTAssertEqual(log.countedSets.count, 3)
        XCTAssertEqual(log.countedLoggedSets, sets([(20, 12), (20, 12), (20, 12)]))
    }

    /// Today's rows and "Set 2 of 4" must not move because ramp-ups were done.
    func testAnItemWithOnlyRampUpsIsStillPending() throws {
        let session = try recorder.startSession(for: "wednesday", on: sept(16), isDeload: false)
        let log = try recorder.log(for: "incline-db-press", in: session)
        try recorder.addSet(to: log, weight: 10, reps: 8, isRampUp: true)
        try recorder.addSet(to: log, weight: 15, reps: 4, isRampUp: true)

        XCTAssertEqual(log.status, .pending)
        XCTAssertEqual(session.statuses["incline-db-press"], .pending)
        XCTAssertEqual(log.sets.count, 2, "they are saved")

        try recorder.addSet(to: log, weight: 20, reps: 10)
        XCTAssertEqual(log.status, .inProgress(setsDone: 1))
        try recorder.addSet(to: log, weight: 20, reps: 9)
        XCTAssertEqual(log.status, .inProgress(setsDone: 2))
        try recorder.complete(log, at: sept(16, hour: 7))
        XCTAssertEqual(log.status, .done(sept(16, hour: 7)))
    }

    func testSkippingOrCompletingAnItemWithOnlyRampUpsStillFinishesIt() throws {
        let session = try recorder.startSession(for: "wednesday", on: sept(16), isDeload: false)
        let log = try recorder.log(for: "incline-db-press", in: session)
        try recorder.addSet(to: log, weight: 10, reps: 8, isRampUp: true)
        try recorder.skip(log, at: sept(16, hour: 7))
        XCTAssertEqual(log.status, .skipped(sept(16, hour: 7)))
        try recorder.reopen(log)
        XCTAssertEqual(log.status, .pending)
    }

    func testHistoryLeavesRampUpsOut() throws {
        let (past, _) = try loggedWithRampUps(on: sept(2), working: [(20, 12), (20, 11), (20, 10)])
        try logSession("incline-db-press", on: sept(9), [(20, 12), (20, 12)])
        let (today, _) = try loggedWithRampUps(on: sept(16))

        XCTAssertEqual(try history.history(for: "incline-db-press", excluding: today.id),
                       [sets([(20, 12), (20, 12)]), sets([(20, 12), (20, 11), (20, 10)])])
        let entries = try history.entries(for: "incline-db-press")
        XCTAssertEqual(entries.map(\.sessionId).last, past.id)
        XCTAssertTrue(entries.flatMap(\.sets).allSatisfy { $0.weight == 20 })
    }

    func testASessionOfOnlyRampUpsLeavesNoHistory() throws {
        let session = try recorder.startSession(for: "wednesday", on: sept(9), isDeload: false)
        let log = try recorder.log(for: "incline-db-press", in: session)
        try recorder.addSet(to: log, weight: 10, reps: 8, isRampUp: true)
        try recorder.skip(log, at: sept(9, hour: 7))

        XCTAssertEqual(try history.history(for: "incline-db-press"), [])
        XCTAssertEqual(try history.entries(for: "incline-db-press"), [])
        XCTAssertFalse(try history.loggedExerciseIds().contains("incline-db-press"))
    }

    /// The same target as if the ramp-ups had never been logged.
    func testRampUpsNeverReachProgression() throws {
        let p = Prescription(sets: 3, repMin: 8, repMax: 12, increment: 2.5)
        try loggedWithRampUps(on: sept(9))
        let past = try history.history(for: "incline-db-press")
        XCTAssertEqual(ProgressionEngine.firstTarget(for: p, history: past),
                       SessionTarget(weight: 22.5, sets: 3, reason: .increase))

        // Unfiltered, the ramp-ups would have been the first sets of the session.
        let raw = try XCTUnwrap(try context.fetch(FetchDescriptor<ExerciseLog>()).first).orderedSets.map(\.loggedSet)
        XCTAssertNotEqual(ProgressionEngine.firstTarget(for: p, history: [raw]).reason, .increase)
    }

    func testDeloadRampUpsStayOutToo() throws {
        try loggedWithRampUps(on: sept(9), working: [(17.5, 10), (17.5, 10)], deload: true)
        try logSession("incline-db-press", on: sept(2), dayKey: "wednesday", [(20, 12), (20, 12), (20, 12)])
        XCTAssertEqual(try history.history(for: "incline-db-press"), [sets([(20, 12), (20, 12), (20, 12)])])
        XCTAssertEqual(try history.entries(for: "incline-db-press").first?.sets, sets([(17.5, 10), (17.5, 10)]))
    }

    func testSetsPerWeekSkipRampUps() throws {
        try loggedWithRampUps(on: sept(16), working: [(20, 12), (20, 11)])
        try logSession("incline-db-press", on: sept(9), [(20, 12)])
        XCTAssertEqual(try history.countedSetTimestamps().count, 3)
    }

    func testSessionSetCountsSkipRampUps() throws {
        let (session, _) = try loggedWithRampUps(on: sept(16), working: [(20, 12), (20, 11)])
        let row = try recorder.log(for: "machine-chest-press-or-flat-bench", in: session)
        try recorder.addSet(to: row, weight: 30, reps: 5, isRampUp: true)
        try recorder.addSet(to: row, weight: 45, reps: 10)
        XCTAssertEqual(session.countedSetCount, 3)
        XCTAssertEqual(session.logs.flatMap(\.sets).count, 6)
    }

    func testUndoStillRemovesTheLastSetAndKeepsEarlierRampUps() throws {
        let session = try recorder.startSession(for: "wednesday", on: sept(16), isDeload: false)
        let log = try recorder.log(for: "incline-db-press", in: session)
        try recorder.addSet(to: log, weight: 10, reps: 8, isRampUp: true)
        try recorder.addSet(to: log, weight: 20, reps: 10)
        XCTAssertEqual(try recorder.removeLastSet(from: log), LoggedSet(weight: 20, reps: 10))
        XCTAssertEqual(log.orderedSets.map(\.isRampUp), [true])
        XCTAssertEqual(log.status, .pending)
    }

    func testForgottenSessionsFinishAtTheirLastRampUp() throws {
        let session = try recorder.startSession(for: "wednesday", on: sept(16, hour: 6), isDeload: false)
        let log = try recorder.log(for: "incline-db-press", in: session)
        try recorder.addSet(to: log, weight: 10, reps: 8, at: sept(16, hour: 7), isRampUp: true)
        try recorder.finishAtLastActivity(session)
        XCTAssertEqual(session.endedAt, sept(16, hour: 7))
    }

    // MARK: Effort

    func testEffortIsStoredClampedAndCleared() throws {
        let session = try logSession("incline-db-press", on: sept(16), dayKey: "wednesday", [(20, 12)])
        try recorder.finish(session, at: sept(16, hour: 8))
        XCTAssertNil(session.effort)

        try recorder.setEffort(7, on: session)
        XCTAssertEqual(session.effort, 7)
        XCTAssertEqual(session.endedAt, sept(16, hour: 8), "finishing is left as it was")
        try recorder.setEffort(0, on: session)
        XCTAssertEqual(session.effort, 1)
        try recorder.setEffort(14, on: session)
        XCTAssertEqual(session.effort, 10)
        try recorder.setEffort(nil, on: session)
        XCTAssertNil(session.effort)

        try recorder.setEffort(4, on: session)
        let stored = try XCTUnwrap(try context.fetch(FetchDescriptor<WorkoutSession>()).first)
        XCTAssertEqual(stored.effort, 4)
    }

    func testFinishLeavesAnEffortAlreadyGiven() throws {
        let session = try recorder.startSession(for: "friday", on: sept(18), isDeload: false)
        try recorder.setEffort(6, on: session)
        try recorder.finish(session, at: sept(18, hour: 8))
        XCTAssertEqual(session.effort, 6)
    }
}
