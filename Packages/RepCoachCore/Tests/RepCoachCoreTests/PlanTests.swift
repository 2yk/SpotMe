import XCTest
@testable import RepCoachCore

final class PlanTests: XCTestCase {

    func testBundledPlanLoads() throws {
        let plan = try Plan.bundled()
        XCTAssertEqual(plan.planVersion, 11)
        XCTAssertEqual(plan.days.count, 7)
        XCTAssertEqual(Set(plan.days.map(\.weekday)), Set(1...7))
    }

    func testEveryWeightedItemHasAPrescription() throws {
        let plan = try Plan.bundled()
        for day in plan.days {
            for item in day.items where item.kind == .weighted {
                XCTAssertNotNil(Prescription(item: item), "\(day.key): \(item.name)")
            }
        }
    }

    func testItemIdsUniqueWithinEachDay() throws {
        let plan = try Plan.bundled()
        for day in plan.days {
            let ids = day.items.map(\.exerciseId)
            XCTAssertEqual(ids.count, Set(ids).count, day.key)
        }
    }

    func testMondayStartsWithRunThenPullUps() throws {
        let monday = try XCTUnwrap(try Plan.bundled().day(forWeekday: 2))
        XCTAssertEqual(monday.items.first?.name, "Recovery Run")
        let pullUps = try XCTUnwrap(monday.items.first { $0.exerciseId == "weighted-pull-ups" })
        XCTAssertEqual(pullUps.sessionsAtTopToProgress, 2)
        XCTAssertEqual(pullUps.restSec, 180)
    }

    func testWithoutRunsDropsOnlyTheRuns() throws {
        let plan = try Plan.bundled()
        let runs = plan.days.flatMap(\.items).filter(\.isRun).map(\.exerciseId)
        XCTAssertEqual(runs, ["recovery-run", "speed-intervals", "recovery-run", "tempo-run", "long-run"])

        let gym = plan.withoutRuns()
        XCTAssertEqual(gym.days.map(\.key), plan.days.map(\.key))
        XCTAssertEqual(gym.days.flatMap(\.items).count, 77 - 5)
        XCTAssertEqual(gym.day(forWeekday: 2)?.items.first?.exerciseId, "monday-warmup")
        // "Legs · Muscle + Running Durability" is gym work, not a run.
        XCTAssertEqual(gym.day(forWeekday: 3)?.items.filter { $0.group.contains("Running") }.count, 7)
        XCTAssertFalse(try XCTUnwrap(gym.day(forWeekday: 1)).items.isEmpty)
    }

    func testWithoutRunsTakesTheRunOutOfFocusAndTime() throws {
        let gym = try Plan.bundled().withoutRuns()
        XCTAssertEqual(gym.days.map { "\($0.focus) | \($0.time)" }, [
            "Pull A · Strength & Thickness | ~65 min gym",
            "Legs · Run-Supportive | ~55 min gym",
            "Push A · Chest & Shoulders + Core A | ~70 min",
            "Pull B · Pull-up Endurance | ~65 min gym",
            "Push B · Arms Focus + Core C | ~70 min gym",
            "Full Rest | Nothing planned",
            "Mobility + Core B | ~30 min",
        ])
    }

    func testDeloadEverySixthWeek() throws {
        let plan = try Plan.bundled()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let start = cal.date(from: DateComponents(year: 2026, month: 9, day: 28))!
        let week6 = cal.date(byAdding: .day, value: 35, to: start)!
        let week5 = cal.date(byAdding: .day, value: 34, to: start)!
        XCTAssertTrue(plan.isDeloadWeek(programStart: start, today: week6, calendar: cal))
        XCTAssertFalse(plan.isDeloadWeek(programStart: start, today: week5, calendar: cal))
    }

    /// Only the weighted pull-ups add their logged weight to bodyweight, which ramp-up sets need to know.
    func testOnlyWeightedPullUpsAddToBodyweight() throws {
        let flagged = try Plan.bundled().days.flatMap(\.items).filter { $0.bodyweightBase == true }
        XCTAssertEqual(flagged.map(\.exerciseId), ["weighted-pull-ups"])

        let without = #"{"name":"Row","exerciseId":"row","group":"","kind":"weighted"}"#
        XCTAssertNil(try JSONDecoder().decode(PlanItem.self, from: Data(without.utf8)).bodyweightBase)
    }
}
