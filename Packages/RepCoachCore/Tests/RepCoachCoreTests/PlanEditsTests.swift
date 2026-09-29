import XCTest
import SwiftData
@testable import RepCoachCore

final class PlanEditsTests: XCTestCase {
    let plan = try! Plan.bundled().withoutRuns()

    var monday: PlanDay { plan.days.first { $0.key == "monday" }! }
    var thursday: PlanDay { plan.days.first { $0.key == "thursday" }! }

    func ids(_ plan: Plan, _ key: String) -> [String] {
        plan.days.first { $0.key == key }!.items.map(\.exerciseId)
    }

    func testNoEditsLeaveThePlanAlone() {
        XCTAssertEqual(PlanEdits().applied(to: plan), plan)
    }

    func testRemovingTakesAnExerciseOffOneDayOnly() {
        var edits = PlanEdits()
        edits.remove("manual-neck-resistance", from: monday)
        let edited = edits.applied(to: plan)
        XCTAssertFalse(ids(edited, "monday").contains("manual-neck-resistance"))
        XCTAssertTrue(ids(edited, "thursday").contains("manual-neck-resistance"))
        XCTAssertEqual(ids(edited, "monday").count, monday.items.count - 1)
    }

    func testMovingReordersTheDay() {
        var edits = PlanEdits()
        // Hammer Curl up above Incline DB Curl.
        let from = monday.items.firstIndex { $0.exerciseId == "hammer-curl" }!
        let to = monday.items.firstIndex { $0.exerciseId == "incline-db-curl" }!
        edits.move(from: [from], to: to, in: monday)
        let order = ids(edits.applied(to: plan), "monday")
        XCTAssertEqual(order.firstIndex(of: "hammer-curl")! + 1, order.firstIndex(of: "incline-db-curl")!)
        XCTAssertEqual(Set(order), Set(monday.items.map(\.exerciseId)))
    }

    func testMovingBackToThePlansOrderClearsTheEdit() {
        var edits = PlanEdits()
        edits.move(from: [2], to: 4, in: monday)
        XCTAssertTrue(edits.isEdited(monday))
        edits.move(from: [3], to: 2, in: monday)
        XCTAssertFalse(edits.isEdited(monday))
        XCTAssertTrue(edits.isEmpty)
    }

    func testAnExerciseFromAnotherDayKeepsItsPrescriptionAndGoesBeforeTheCooldown() {
        var edits = PlanEdits()
        let preacher = thursday.items.first { $0.exerciseId == "preacher-curl" }!
        edits.add(preacher, to: monday, plan: plan)
        let items = edits.applied(to: plan).days.first { $0.key == "monday" }!.items
        let added = items.first { $0.exerciseId == "preacher-curl" }
        XCTAssertEqual(added, preacher)
        // After Hammer Curl, the last exercise, ahead of neck work and the cooldown.
        let order = items.map(\.exerciseId)
        XCTAssertEqual(order.firstIndex(of: "preacher-curl"), order.firstIndex(of: "hammer-curl")! + 1)
        XCTAssertTrue(edits.custom.isEmpty, "A plan exercise isn't stored as the user's own")
    }

    func testAddingTwiceChangesNothing() {
        var edits = PlanEdits()
        let rows = monday.items.first { $0.exerciseId == "chest-supported-db-row" }!
        edits.add(rows, to: monday, plan: plan)
        XCTAssertTrue(edits.isEmpty)
    }

    func testTheUsersOwnExerciseIsStoredAndApplied() {
        var edits = PlanEdits()
        let id = PlanEdits.newExerciseId(name: "Barbell Row!", taken: [])
        XCTAssertEqual(id, "custom-barbell-row")
        let row = PlanItem(name: "Barbell Row", exerciseId: id, group: "Back · Thickness", kind: .weighted,
                           sets: 3, repMin: 8, repMax: 10, increment: 2.5, restSec: 120)
        edits.add(row, to: monday, at: 2, plan: plan)
        XCTAssertEqual(edits.custom[id], row)
        XCTAssertEqual(ids(edits.applied(to: plan), "monday")[2], id)
        XCTAssertTrue(edits.library(plan: plan).contains(row))
        XCTAssertEqual(PlanEdits.newExerciseId(name: "Barbell Row", taken: [id]), "custom-barbell-row-2")
    }

    func testIdsThatNoLongerExistAreLeftOut() {
        let edits = PlanEdits(days: ["monday": ["monday-warmup", "gone", "hammer-curl"]])
        XCTAssertEqual(ids(edits.applied(to: plan), "monday"), ["monday-warmup", "hammer-curl"])
    }

    func testRenamingAppliesEverywhere() {
        let item = monday.items.first { $0.exerciseId == "manual-neck-resistance" }!
        XCTAssertEqual(item.applying(ExerciseOverrides(name: "Neck Harness")).name, "Neck Harness")
    }

    func testEditsSurviveTheStore() throws {
        let container = try RepCoachStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        XCTAssertEqual(PlanEdits.load(from: context), PlanEdits())
        var edits = PlanEdits()
        edits.remove("face-pulls", from: monday)
        try edits.save(to: context)
        XCTAssertEqual(PlanEdits.load(from: context), edits)
        try PlanEdits().save(to: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanEditsRecord>()), 0)
    }

    func testEditsTravelToTheWatch() throws {
        var edits = PlanEdits()
        edits.remove("face-pulls", from: monday)
        let context = SyncContext(settings: TrainingSettings(), overrides: ["hammer-curl": ExerciseOverrides(name: "Hammers")],
                                  plan: edits)
        XCTAssertEqual(SyncContext(applicationContext: context.applicationContext), context)
    }

    func testContextsFromBeforePlanEditsStillRead() throws {
        let old = #"{"settings":{"restHaptics":true},"overrides":{},"received":[],"sentAt":0}"#
        let context = try JSONDecoder().decode(SyncContext.self, from: Data(old.utf8))
        XCTAssertEqual(context.plan, PlanEdits())
    }
}
