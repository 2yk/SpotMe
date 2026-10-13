import XCTest
import SwiftData
@testable import RepCoachCore

/// Plan 12 moved Push B from key "friday" to "saturday", Full Rest from "saturday" to "sunday", and put Legs B on
/// Friday: what was stored under the old meaning of a key follows its workout.
final class PlanKeyMigrationTests: StoreTestCase {
    let plan = try! Plan.bundled()

    /// Plan 11's Rearrange days and edits: no `planKeys`, plan 11's keys.
    let oldEdits = """
        {"days":{"friday":["friday-warmup","db-bench-press"],"saturday":["nothing-structured"],
                 "sunday":["long-run","pallof-press"],"tuesday":["tuesday-warmup","copenhagen-plank"],
                 "thursday":["max-rep-set","single-arm-cable-row"],
                 "wednesday":["wednesday-warmup","incline-db-press","pallof-press"]},
         "custom":{},"schedule":{"2":"wednesday","4":"monday"}}
        """

    /// One run of both migrations, in the order the app runs them.
    @discardableResult
    func migrate() throws -> PlanKeyMigration.Report {
        try IdMigration.run(in: context)
        return try PlanKeyMigration.run(in: context, plan: plan)
    }

    func keys() throws -> [String: [String]] {
        var byKey: [String: [String]] = [:]
        for session in try context.fetch(FetchDescriptor<WorkoutSession>()) {
            byKey[session.dayKey, default: []].append(contentsOf: session.logs.map(\.exerciseId))
        }
        return byKey.mapValues { $0.sorted() }
    }

    // MARK: Sessions

    func testPushBSessionsKeepTheirHistoryUnderSaturday() throws {
        try logSession("db-bench-press", on: sept(4), dayKey: "friday", [(20, 10)])
        try logSession("friday-warmup", on: sept(11), dayKey: "friday", [(0, 1)])

        let report = try migrate()

        XCTAssertEqual(report.sessions, 2)
        XCTAssertEqual(try keys(), ["saturday": ["db-bench-press", "saturday-warmup"]])
        XCTAssertEqual(try history.history(for: "db-bench-press"), [sets([(20, 10)])], "History is by exercise")
    }

    func testLegsBOnFridayStaysOnFriday() throws {
        try logSession("hack-squat", on: sept(18), dayKey: "friday", [(60, 8)])
        try logSession("legs-b-warmup", on: sept(25), dayKey: "friday", [(0, 1)])

        XCTAssertEqual(try migrate().sessions, 0)
        XCTAssertEqual(try keys(), ["friday": ["hack-squat", "legs-b-warmup"]])
    }

    func testASwappedExerciseIsJudgedByTheSlotItStoodIn() throws {
        // Push B's DB Bench Press swapped for a Smith press: it is logged under the swapped-in id.
        let session = try recorder.startSession(for: "friday", on: sept(4), isDeload: false)
        let log = try recorder.log(for: "smith-machine-bench-press", in: session)
        log.slotExerciseId = "db-bench-press"
        try recorder.addSet(to: log, weight: 40, reps: 8, at: sept(4))
        // Legs B's Hack Squat swapped for another squat stays on Friday.
        let legs = try recorder.startSession(for: "friday", on: sept(18), isDeload: false)
        let swapped = try recorder.log(for: "leg-press", in: legs)
        swapped.slotExerciseId = "hack-squat"
        try recorder.addSet(to: swapped, weight: 100, reps: 10, at: sept(18))

        XCTAssertEqual(try migrate().sessions, 1)
        XCTAssertEqual(session.dayKey, "saturday")
        XCTAssertEqual(legs.dayKey, "friday")
    }

    func testFullRestMovesToSundayAndPlan11sSundayKeepsItsKeyAndName() throws {
        let rest = try logSession("nothing-structured", on: sept(5), dayKey: "saturday", [(0, 1)])
        let longRun = try logSession("pallof-press", on: sept(6), dayKey: "sunday", [(10, 10)])
        let fullRest = try logSession("eat-sleep", on: sept(13), dayKey: "sunday", [(0, 1)])

        let report = try migrate()

        XCTAssertEqual(report.sessions, 1)
        XCTAssertEqual(rest.dayKey, "sunday")
        XCTAssertEqual(longRun.dayKey, "sunday", "Plan 11's Sunday has no workout to follow")
        XCTAssertEqual(PlanKeyMigration.retiredHeadline(of: longRun, in: plan), "Long Run + Mobility + Core B")
        XCTAssertNil(PlanKeyMigration.retiredHeadline(of: fullRest, in: plan))
        XCTAssertNil(PlanKeyMigration.retiredHeadline(of: rest, in: plan))
    }

    func testRunningItAgainMovesNothingAndLeavesNewSessionsAlone() throws {
        try logSession("db-bench-press", on: sept(4), dayKey: "friday", [(20, 10)])
        XCTAssertFalse(try migrate().isEmpty)
        XCTAssertTrue(try migrate().isEmpty)

        // Legs B, trained on a Friday after the move, is not mistaken for plan 11's Push B.
        try logSession("hack-squat", on: sept(18), dayKey: "friday", [(60, 8)])
        XCTAssertTrue(try migrate().isEmpty)
        XCTAssertEqual(try keys(), ["friday": ["hack-squat"], "saturday": ["db-bench-press"]])
    }

    func testAnEmptyStoreIsLeftAlone() throws {
        XCTAssertTrue(try migrate().isEmpty)
    }

    func testASessionFromAWatchStillOnPlan11IsStoredUnderItsWorkout() throws {
        let watch = try RepCoachStore.makeContainer(inMemory: true)
        let watchContext = ModelContext(watch)
        let watchRecorder = WorkoutRecorder(context: watchContext, calendar: calendar)
        let session = try watchRecorder.startSession(for: "friday", on: sept(4), isDeload: false)
        let log = try watchRecorder.log(for: "db-bench-press", in: session)
        try watchRecorder.addSet(to: log, weight: 20, reps: 10, at: sept(4))
        let sent = SessionPayload(session)
        XCTAssertEqual(sent.dayKey, "friday")

        let stored = try sent.upsert(into: context)

        XCTAssertEqual(stored.dayKey, "saturday")
    }

    // MARK: Plan edits

    func saveOldEdits() throws {
        context.insert(PlanEditsRecord(data: Data(oldEdits.utf8)))
        try context.save()
    }

    func testEditsMoveWithTheirWorkoutAndTheRemovedExercisesGo() throws {
        try saveOldEdits()

        let report = try migrate()
        let edits = PlanEdits.load(from: context)

        XCTAssertEqual(edits.planKeys, 12)
        XCTAssertEqual(edits.days["saturday"], ["saturday-warmup", "db-bench-press"], "Push B's edited list")
        XCTAssertEqual(edits.days["sunday"], ["nothing-structured"], "Full Rest's list, not plan 11's Sunday list")
        XCTAssertNil(edits.days["friday"], "Legs B starts from the plan")
        XCTAssertEqual(edits.days["tuesday"], ["tuesday-warmup", "weighted-plank"])
        XCTAssertEqual(edits.days["thursday"], ["max-rep-set", "seated-cable-row"])
        XCTAssertEqual(edits.days["wednesday"], ["wednesday-warmup", "barbell-bench-press", "incline-db-press"])
        XCTAssertTrue(edits.schedule.isEmpty, "A mapping made on plan 11's workouts is reset")

        XCTAssertEqual(report.listsMoved, 2)
        XCTAssertEqual(report.exercisesReplaced, 3)
        XCTAssertEqual(report.exercisesDropped, 3, "Sunday's two and the Pallof press moved onto Wednesday")
        XCTAssertTrue(report.scheduleReset)
    }

    func testEditsAreMovedOnce() throws {
        try saveOldEdits()
        try migrate()

        // After the move the user edits Legs B; the next launch leaves it where it is.
        var edits = PlanEdits.load(from: context)
        let legs = try XCTUnwrap(plan.days.first { $0.key == "friday" })
        edits.remove("tibialis-raise", from: legs)
        edits.swapWorkouts(on: 2, and: 3, plan: plan)
        try edits.save(to: context)

        XCTAssertTrue(try migrate().isEmpty)
        let again = PlanEdits.load(from: context)
        XCTAssertEqual(again.days["friday"], legs.items.map(\.exerciseId).filter { $0 != "tibialis-raise" })
        XCTAssertEqual(again.schedule, [2: "tuesday", 3: "monday"])
    }

    func testNewEditsAreOnTheCurrentKeys() {
        XCTAssertEqual(PlanEdits().planKeys, PlanEdits.currentPlanKeys)
        XCTAssertEqual(PlanEdits().onCurrentPlanKeys(), PlanEdits())
    }

    func testEditsFromAPhoneStillOnPlan11AreMovedWhenTheWatchStoresThem() throws {
        let sent = SyncContext(settings: TrainingSettings(), overrides: [:],
                               plan: try JSONDecoder().decode(PlanEdits.self, from: Data(oldEdits.utf8)))
        XCTAssertEqual(sent.plan.planKeys, 11)

        try sent.applyPlan(to: context)

        let stored = PlanEdits.load(from: context)
        XCTAssertEqual(stored.planKeys, 12)
        XCTAssertEqual(stored.days["saturday"]?.last, "db-bench-press")
        XCTAssertTrue(stored.schedule.isEmpty)
    }
}
