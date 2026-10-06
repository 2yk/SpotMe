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

    func testWatchStatusSurvivesTheTrip() throws {
        for access in [HealthAccess.notAsked, .allowed, .denied] {
            let sent = WatchStatus(healthAccess: access)
            XCTAssertEqual(WatchStatus(applicationContext: sent.applicationContext), sent)
        }
        // Each side's application context is only ever read as its own kind.
        let status = WatchStatus(healthAccess: .allowed).applicationContext
        let context = SyncContext(settings: TrainingSettings(), overrides: [:]).applicationContext
        XCTAssertNil(SyncContext(applicationContext: status))
        XCTAssertNil(WatchStatus(applicationContext: context))
    }

    /// A status from before the session lists existed means "unknown", and nothing is sent back for it.
    func testStatusesFromBeforeSessionListsStillRead() throws {
        let old = ["watchStatus": Data(#"{"healthAccess":"denied"}"#.utf8)]
        let status = try XCTUnwrap(WatchStatus(applicationContext: old))
        XCTAssertEqual(status, WatchStatus(healthAccess: .denied))
        XCTAssertNil(status.sessions)
        XCTAssertEqual(status.missing(fromPhone: [(id: UUID(), date: sept(21))]), [])
    }

    /// A reinstalled watch app starts empty: the phone sends back what the watch lost, and nothing else.
    func testRestoreSendsTheWatchOnlyWhatItLost() throws {
        let mondayId = try loggedMonday().id
        try logSession("hip-thrust", on: sept(22), dayKey: "tuesday", [(60, 12)])
        for session in try context.fetch(FetchDescriptor<WorkoutSession>()) {
            try SessionPayload(session).upsert(into: phone)
        }
        XCTAssertEqual(try recorder.deleteSessions([mondayId]), 1)

        let status = WatchStatus(healthAccess: .allowed, sessions: try recorder.sessionIds())
        let phoneSessions = try phone.fetch(FetchDescriptor<WorkoutSession>())
        XCTAssertEqual(status.missing(fromPhone: try WorkoutRecorder(context: phone).sessionStamps()), [mondayId])

        let lost = try XCTUnwrap(phoneSessions.first { $0.id == mondayId })
        XCTAssertTrue(try SessionPayload(lost).insertIfMissing(into: context))
        XCTAssertEqual(try history.history(for: "weighted-pull-ups"), [sets([(15, 5), (15, 5), (15, 4)])])
        XCTAssertEqual(Set(try recorder.sessionIds()), Set(phoneSessions.map(\.id)))
    }

    /// The watch keeps logging after the phone's copy was made; the phone's older copy never replaces it.
    func testARestoredCopyNeverOverwritesTheWatch() throws {
        let tuesday = try logSession("hip-thrust", on: sept(22), dayKey: "tuesday", [(60, 12)])
        try SessionPayload(tuesday).upsert(into: phone)
        try recorder.addSet(to: try recorder.log(for: "hip-thrust", in: tuesday), weight: 60, reps: 11,
                            at: sept(22, hour: 7))

        let phoneCopy = try XCTUnwrap(try phone.fetch(FetchDescriptor<WorkoutSession>()).first)
        XCTAssertFalse(try SessionPayload(phoneCopy).insertIfMissing(into: context))
        XCTAssertEqual(try history.history(for: "hip-thrust"), [sets([(60, 12), (60, 11)])])
    }

    /// Discarding on the watch deletes the phone's copy, and the phone never sends it back.
    func testDiscardedSessionsLeaveThePhoneForGood() throws {
        let tuesday = try logSession("hip-thrust", on: sept(22), dayKey: "tuesday", [(60, 12), (60, 11)])
        let id = tuesday.id
        try SessionPayload(tuesday).upsert(into: phone)
        try recorder.delete(tuesday)

        let status = WatchStatus(healthAccess: nil, sessions: try recorder.sessionIds(), deleted: [id])
        let phoneRecorder = WorkoutRecorder(context: phone)
        XCTAssertEqual(status.missing(fromPhone: try phoneRecorder.sessionStamps()), [])
        XCTAssertEqual(try phoneRecorder.deleteSessions(status.deleted), 1)
        XCTAssertEqual(try phone.fetchCount(FetchDescriptor<SetLog>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SetLog>()), 0)
    }

    /// Only sessions inside the watch's window come back; older ones stay on the phone.
    func testRestoreStaysInsideTheWindow() throws {
        let old = try logSession("hip-thrust", on: sept(1), dayKey: "tuesday", [(60, 12)]).id
        let recent = try logSession("hip-thrust", on: sept(22), dayKey: "tuesday", [(60, 12)]).id
        for session in try context.fetch(FetchDescriptor<WorkoutSession>()) {
            try SessionPayload(session).upsert(into: phone)
        }
        let status = WatchStatus(healthAccess: nil, sessions: [], since: sept(15))
        XCTAssertEqual(status.missing(fromPhone: try WorkoutRecorder(context: phone).sessionStamps()), [recent])
        XCTAssertNotEqual(old, recent)
    }

    /// The watch started today again before today's copy came back from the phone: the copy's items join the
    /// watch's session, and the watch's own log wins for an item both have.
    func testARestoredCopyOfTodayMergesIntoTheWatchsSession() throws {
        let earlier = try loggedMonday()
        try SessionPayload(earlier).upsert(into: phone)
        let copy = SessionPayload(try XCTUnwrap(try phone.fetch(FetchDescriptor<WorkoutSession>()).first))
        try recorder.delete(earlier)

        // Logged again on the reinstalled watch, same Monday: pull-ups only, different numbers.
        let again = try recorder.startSession(for: "monday", on: sept(21, hour: 11), isDeload: false)
        let pullUps = try recorder.log(for: "weighted-pull-ups", in: again)
        try recorder.addSet(to: pullUps, weight: 17.5, reps: 3, at: sept(21, hour: 11))

        try copy.merge(into: again, context: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WorkoutSession>()), 1)
        XCTAssertEqual(again.log(for: "weighted-pull-ups")?.orderedSets.map(\.loggedSet), sets([(17.5, 3)]))
        XCTAssertEqual(again.statuses["recovery-run"]?.isFinished, true)
        XCTAssertEqual(again.statuses["incline-db-curl"], .skipped(sept(21, hour: 9)))
        XCTAssertEqual(again.log(for: "weighted-plank")?.orderedSets.first?.seconds, 41)
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
            received: [UUID(), UUID()],
            sentAt: sept(27))
        let received = try XCTUnwrap(SyncContext(applicationContext: sent.applicationContext))
        XCTAssertEqual(received, sent)

        try received.applyOverrides(to: context)
        XCTAssertEqual(try SyncContext.overrides(in: context), received.overrides)
    }

    /// The ramp-up setting reaches the watch with the other settings; a context from before it reads as the default.
    func testTheRampUpSettingTravelsToTheWatch() throws {
        for setting in RampUpSetting.allCases {
            let sent = SyncContext(settings: TrainingSettings(rampUps: setting), overrides: [:], sentAt: sept(27))
            let received = try XCTUnwrap(SyncContext(applicationContext: sent.applicationContext))
            XCTAssertEqual(received.settings.rampUps, setting)
        }
        let old = ["context": Data(#"{"settings":{"restHaptics":true},"overrides":{},"sentAt":780710400}"#.utf8)]
        XCTAssertEqual(SyncContext(applicationContext: old)?.settings.rampUps, .mainLifts)
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
