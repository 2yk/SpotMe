import XCTest
import SwiftData
@testable import RepCoachCore

/// The base class's store plays the watch; `phone` is a second, separate in-memory store.
final class SyncTests: StoreTestCase {
    var phoneContainer: ModelContainer!
    var phone: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let schema = Schema(RepCoachStore.models)
        phoneContainer = try ModelContainer(for: schema, configurations: [
            ModelConfiguration("phone", schema: schema, isStoredInMemoryOnly: true),
        ])
        phone = ModelContext(phoneContainer)
    }

    override func tearDown() {
        phone = nil
        phoneContainer = nil
        super.tearDown()
    }

    /// A Monday on the watch: run ticked, pull-ups logged, curls skipped, a timed set, finished.
    func loggedMonday() throws -> WorkoutSession {
        let session = try recorder.startSession(for: "monday", on: sept(21), isDeload: false)
        try recorder.complete(try recorder.log(for: "recovery-run", in: session), at: sept(21, hour: 7))
        let pullUps = try recorder.log(for: "weighted-pull-ups", in: session)
        for reps in [5, 5, 4] { try recorder.addSet(to: pullUps, weight: 15, reps: reps, at: sept(21, hour: 8)) }
        try recorder.complete(pullUps, at: sept(21, hour: 8))
        try recorder.skip(try recorder.log(for: "incline-db-curl", in: session), at: sept(21, hour: 9))
        let plank = try recorder.log(for: "weighted-plank", in: session)
        try recorder.addSet(to: plank, weight: 10, reps: 0, seconds: 41, at: sept(21, hour: 9))
        session.healthKitWorkoutId = UUID()
        try recorder.finish(session, at: sept(21, hour: 10))
        return session
    }

    /// SPEC acceptance check 7, at the data level: a session logged on the watch shows up in the phone's history.
    func testSessionSurvivesTheTrip() throws {
        let session = try loggedMonday()
        let received = try XCTUnwrap(SessionPayload(userInfo: SessionPayload(session).userInfo))
        let stored = try received.upsert(into: phone)

        XCTAssertEqual(stored.id, session.id)
        XCTAssertEqual(stored.endedAt, sept(21, hour: 10))
        XCTAssertEqual(stored.healthKitWorkoutId, session.healthKitWorkoutId)
        XCTAssertEqual(stored.statuses, session.statuses)
        XCTAssertEqual(try HistoryStore(context: phone).history(for: "weighted-pull-ups"),
                       [sets([(15, 5), (15, 5), (15, 4)])])
        XCTAssertEqual(try HistoryStore(context: phone).history(for: "weighted-plank"),
                       [[LoggedSet(weight: 10, reps: 41)]])
        XCTAssertEqual(SessionPayload(stored), received)
    }

    func testResendingKeepsOneCopy() throws {
        let payload = SessionPayload(try loggedMonday())
        try payload.upsert(into: phone)
        try payload.upsert(into: phone)

        XCTAssertEqual(try phone.fetchCount(FetchDescriptor<WorkoutSession>()), 1)
        XCTAssertEqual(try phone.fetchCount(FetchDescriptor<ExerciseLog>()), 4)
        XCTAssertEqual(try phone.fetchCount(FetchDescriptor<SetLog>()), 4)
    }

    func testResendingAfterMoreLoggingUpdatesInPlace() throws {
        let session = try loggedMonday()
        try SessionPayload(session).upsert(into: phone)

        let pullUps = try recorder.log(for: "weighted-pull-ups", in: session)
        try recorder.addSet(to: pullUps, weight: 15, reps: 5, at: sept(21, hour: 10))
        try SessionPayload(session).upsert(into: phone)

        XCTAssertEqual(try phone.fetchCount(FetchDescriptor<WorkoutSession>()), 1)
        XCTAssertEqual(try HistoryStore(context: phone).history(for: "weighted-pull-ups"),
                       [sets([(15, 5), (15, 5), (15, 4), (15, 5)])])
    }

    func testMalformedUserInfoIsIgnored() {
        XCTAssertNil(SessionPayload(userInfo: [:]))
        XCTAssertNil(SessionPayload(userInfo: ["session": Data("nope".utf8)]))
    }

    // MARK: Phone → watch

    func testContextReplacesTheWatchOverrides() throws {
        for (id, sets) in [("face-pulls", 4), ("hammer-curl", 2)] {
            let row = ExerciseSettings(exerciseId: id)
            row.sets = sets
            context.insert(row)
        }
        try context.save()

        let sent = SyncContext(
            settings: TrainingSettings(programStart: sept(28), restHaptics: false),
            overrides: ["hammer-curl": ExerciseOverrides(sets: 4, restSec: 60),
                        "leg-press": ExerciseOverrides(increment: 5)],
            sentAt: sept(27))
        let received = try XCTUnwrap(SyncContext(applicationContext: sent.applicationContext))
        XCTAssertEqual(received, sent)

        try received.applyOverrides(to: context)
        XCTAssertEqual(try SyncContext.overrides(in: context), received.overrides)
    }

    func testReadingOverridesSkipsEmptyRows() throws {
        context.insert(ExerciseSettings(exerciseId: "face-pulls"))
        let row = ExerciseSettings(exerciseId: "leg-press")
        row.increment = 5
        context.insert(row)
        try context.save()
        XCTAssertEqual(try SyncContext.overrides(in: context), ["leg-press": ExerciseOverrides(increment: 5)])
    }

    // MARK: Forgotten sessions

    func testForgottenSessionsAreFinishedAtTheirLastSet() throws {
        let yesterday = try recorder.startSession(for: "monday", on: sept(21, hour: 6), isDeload: false)
        let rows = try recorder.log(for: "chest-supported-db-row", in: yesterday)
        try recorder.addSet(to: rows, weight: 20, reps: 9, at: sept(21, hour: 7))
        try recorder.addSet(to: rows, weight: 20, reps: 8, at: sept(21, hour: 8))
        let today = try recorder.startSession(for: "tuesday", on: sept(22, hour: 6), isDeload: false)

        let forgotten = try recorder.unfinishedSessions(before: sept(22, hour: 9))
        XCTAssertEqual(forgotten.map(\.id), [yesterday.id])
        XCTAssertFalse(forgotten.contains { $0.id == today.id })

        try recorder.finishAtLastActivity(yesterday)
        XCTAssertEqual(yesterday.endedAt, sept(21, hour: 8))
        XCTAssertEqual(try recorder.unfinishedSessions(before: sept(22, hour: 9)), [])
    }
}
