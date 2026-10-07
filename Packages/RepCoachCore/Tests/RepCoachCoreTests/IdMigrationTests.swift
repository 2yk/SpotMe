import XCTest
import SwiftData
@testable import RepCoachCore

/// "Machine Chest Press (or Flat Bench)" became Machine Chest Press: everything stored under the old id moves.
final class IdMigrationTests: StoreTestCase {
    let old = "machine-chest-press-or-flat-bench"
    let new = "machine-chest-press"

    func testThePlanHasOneMachineChestPress() throws {
        let items = try Plan.bundled().days.flatMap(\.items)
        XCTAssertNil(items.first { $0.exerciseId == old })
        let chest = try XCTUnwrap(items.first { $0.exerciseId == new })
        XCTAssertEqual(chest.name, "Machine Chest Press")
        XCTAssertEqual(chest.note, "Machine lets you push close to failure safely. Feet planted.")
    }

    func testHistoryUnderTheOldIdCountsAsMachineChestPress() throws {
        try logSession(old, on: sept(2), dayKey: "wednesday", [(35, 10), (35, 10), (35, 9)])
        try logSession(old, on: sept(9), dayKey: "wednesday", [(40, 10), (40, 9)])
        try logSession(new, on: sept(16), dayKey: "wednesday", [(40, 10)])

        let report = try IdMigration.run(in: context)

        XCTAssertEqual(report.logs, 2)
        XCTAssertEqual(report.sets, 5)
        XCTAssertEqual(try history.history(for: new), [sets([(40, 10)]), sets([(40, 10), (40, 9)]),
                                                       sets([(35, 10), (35, 10), (35, 9)])])
        XCTAssertEqual(try history.history(for: old), [])
    }

    func testRunningItAgainChangesNothing() throws {
        try logSession(old, on: sept(2), dayKey: "wednesday", [(35, 10)])
        XCTAssertFalse(try IdMigration.run(in: context).isEmpty)
        XCTAssertTrue(try IdMigration.run(in: context).isEmpty)
    }

    func testAnEmptyStoreIsLeftAlone() throws {
        XCTAssertTrue(try IdMigration.run(in: context).isEmpty)
    }

    func testSettingsFollowTheRename() throws {
        let row = ExerciseSettings(exerciseId: old)
        row.increment = 2.5
        context.insert(row)
        try context.save()

        let report = try IdMigration.run(in: context)

        XCTAssertEqual(report.settings, 1)
        let rows = try context.fetch(FetchDescriptor<ExerciseSettings>())
        XCTAssertEqual(rows.map(\.exerciseId), [new])
        XCTAssertEqual(rows.first?.increment, 2.5)
    }

    func testAnExistingRowForTheNewIdWins() throws {
        let oldRow = ExerciseSettings(exerciseId: old)
        oldRow.increment = 2.5
        let newRow = ExerciseSettings(exerciseId: new)
        newRow.increment = 5
        context.insert(oldRow)
        context.insert(newRow)
        try context.save()

        try IdMigration.run(in: context)

        let rows = try context.fetch(FetchDescriptor<ExerciseSettings>())
        XCTAssertEqual(rows.map(\.exerciseId), [new])
        XCTAssertEqual(rows.first?.increment, 5)
    }

    func testPlanEditsFollowTheRename() throws {
        var edits = PlanEdits(days: ["wednesday": ["warmup", old, "seated-db-shoulder-press"]])
        edits.days["friday"] = [old, new]
        try edits.save(to: context)

        let report = try IdMigration.run(in: context)

        XCTAssertEqual(report.planEdits, 1)
        let loaded = PlanEdits.load(from: context)
        XCTAssertEqual(loaded.days["wednesday"], ["warmup", new, "seated-db-shoulder-press"])
        XCTAssertEqual(loaded.days["friday"], [new])
    }

    func testTheDaysMarksFollowTheRename() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "IdMigrationTests"))
        defaults.removePersistentDomain(forName: "IdMigrationTests")
        defaults.set(["incline-db-press", old], forKey: "waiting.wednesday.2026-10-07")
        defaults.set([old], forKey: "rampSkipped.wednesday.2026-10-07")
        defaults.set(["incline-db-press"], forKey: "waiting.monday.2026-10-05")

        let report = try IdMigration.run(in: context, defaults: defaults)

        XCTAssertEqual(report.marks, 2)
        XCTAssertEqual(defaults.stringArray(forKey: "waiting.wednesday.2026-10-07"), ["incline-db-press", new])
        XCTAssertEqual(defaults.stringArray(forKey: "rampSkipped.wednesday.2026-10-07"), [new])
        XCTAssertEqual(try IdMigration.run(in: context, defaults: defaults).marks, 0)
        defaults.removePersistentDomain(forName: "IdMigrationTests")
    }

    func testASessionFromADeviceThatStillHasTheOldIdIsStoredUnderTheNewOne() throws {
        let session = try logSession(old, on: sept(9), dayKey: "wednesday", [(40, 10), (40, 9)])
        var payload = SessionPayload(session)
        payload.logs[0].slotExerciseId = old
        try recorder.delete(session)

        try payload.upsert(into: context)

        XCTAssertEqual(try history.history(for: new), [sets([(40, 10), (40, 9)])])
        XCTAssertEqual(try history.history(for: old), [])
        let stored = try XCTUnwrap(try recorder.session(for: "wednesday", on: sept(9)))
        XCTAssertEqual(stored.logs.first?.slotExerciseId, new)
    }

    func testAMergedSessionTakesTheNewIdToo() throws {
        let local = try recorder.startSession(for: "wednesday", on: sept(9), isDeload: false)
        _ = try recorder.log(for: new, in: local)
        let other = try logSession(old, on: sept(2), dayKey: "wednesday", [(40, 10)])
        let payload = SessionPayload(other)
        try recorder.delete(other)

        try payload.merge(into: local, context: context)

        XCTAssertEqual(local.logs.map(\.exerciseId), [new])
    }

    func testTheFigureLibraryFindsTheRenamedExercise() throws {
        let library = try XCTUnwrap(FigureLibrary.shared)
        XCTAssertNotNil(library.figure(forExercise: new))
        XCTAssertNotNil(library.figure(forExercise: old))
    }

    func testTheDatabaseKnowsTheRenamedExerciseByEitherId() throws {
        let database = try XCTUnwrap(ExerciseDatabase.shared)
        XCTAssertEqual(database.entry(forExerciseId: new)?.name, "Machine Chest Press")
        XCTAssertEqual(database.entry(forExerciseId: old)?.name, "Machine Chest Press")
    }
}
