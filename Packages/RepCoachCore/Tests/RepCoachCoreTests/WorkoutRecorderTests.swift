import XCTest
import SwiftData
@testable import RepCoachCore

final class WorkoutRecorderTests: StoreTestCase {

    func testOneSessionPerDayAndPlanDay() throws {
        let first = try recorder.startSession(for: "monday", on: sept(14, hour: 6), isDeload: false)
        let again = try recorder.startSession(for: "monday", on: sept(14, hour: 7), isDeload: false)
        let otherDay = try recorder.startSession(for: "monday", on: sept(21), isDeload: false)
        let otherPlanDay = try recorder.startSession(for: "wednesday", on: sept(14), isDeload: false)

        XCTAssertEqual(first.id, again.id)
        XCTAssertNotEqual(first.id, otherDay.id)
        XCTAssertNotEqual(first.id, otherPlanDay.id)
        XCTAssertEqual(try recorder.session(for: "monday", on: sept(14, hour: 20))?.id, first.id)
        XCTAssertNil(try recorder.session(for: "tuesday", on: sept(14)))
    }

    func testLogsAreNumberedInTheOrderStarted() throws {
        let session = try recorder.startSession(for: "monday", on: sept(14), isDeload: false)
        let run = try recorder.log(for: "recovery-run", in: session)
        let pullUps = try recorder.log(for: "weighted-pull-ups", in: session)

        XCTAssertEqual([run.order, pullUps.order], [0, 1])
        XCTAssertEqual(try recorder.log(for: "recovery-run", in: session).order, 0)
        XCTAssertEqual(session.logs.count, 2)
    }

    func testUndoRemovesTheLastSetAndReopens() throws {
        let session = try recorder.startSession(for: "wednesday", on: sept(16), isDeload: false)
        let log = try recorder.log(for: "incline-db-press", in: session)
        try recorder.addSet(to: log, weight: 22.5, reps: 8)
        try recorder.addSet(to: log, weight: 22.5, reps: 5)
        try recorder.complete(log)

        XCTAssertEqual(try recorder.removeLastSet(from: log), LoggedSet(weight: 22.5, reps: 5))
        XCTAssertEqual(log.orderedSets.map(\.loggedSet), [LoggedSet(weight: 22.5, reps: 8)])
        XCTAssertEqual(log.status, .inProgress(setsDone: 1))

        try recorder.addSet(to: log, weight: 20, reps: 7)
        XCTAssertEqual(log.orderedSets.map(\.index), [1, 2])
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SetLog>()), 2)
    }

    func testUndoWithNothingLogged() throws {
        let session = try recorder.startSession(for: "wednesday", on: sept(16), isDeload: false)
        XCTAssertNil(try recorder.removeLastSet(from: try recorder.log(for: "rope-pushdown", in: session)))
    }

    func testStatuses() throws {
        let session = try recorder.startSession(for: "monday", on: sept(14), isDeload: false)
        let run = try recorder.log(for: "recovery-run", in: session)
        let rows = try recorder.log(for: "chest-supported-db-row", in: session)
        let curls = try recorder.log(for: "incline-db-curl", in: session)

        XCTAssertEqual(rows.status, .pending)
        try recorder.complete(run, at: sept(14, hour: 7))
        try recorder.addSet(to: rows, weight: 20, reps: 9)
        try recorder.skip(curls, at: sept(14, hour: 8))

        XCTAssertEqual(session.statuses, [
            "recovery-run": .done(sept(14, hour: 7)),
            "chest-supported-db-row": .inProgress(setsDone: 1),
            "incline-db-curl": .skipped(sept(14, hour: 8)),
        ])

        try recorder.reopen(curls)
        XCTAssertEqual(curls.status, .pending)
    }

    func testFinishStampsTheSession() throws {
        let session = try recorder.startSession(for: "friday", on: sept(18), isDeload: false)
        try recorder.finish(session, at: sept(18, hour: 8))
        XCTAssertEqual(session.endedAt, sept(18, hour: 8))
    }

    func testDeletingASessionDeletesItsLogsAndSets() throws {
        let session = try logSession("hip-thrust", on: sept(15), dayKey: "tuesday", [(60, 12), (60, 11)])
        context.delete(session)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ExerciseLog>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SetLog>()), 0)
    }
}
