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
}
