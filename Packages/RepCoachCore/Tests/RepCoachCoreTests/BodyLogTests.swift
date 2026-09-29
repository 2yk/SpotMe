import XCTest
@testable import RepCoachCore

final class BodyLogTests: XCTestCase {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return calendar
    }()

    func day(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: 7))!
    }

    func entry(_ day: Int, arm: Double, waist: Double) -> BodyLog.Entry {
        BodyLog.Entry(date: self.day(day), arm: arm, waist: waist)
    }

    func testWaistUpMoreThanAnInchWithFlatArmsWarns() throws {
        let change = try XCTUnwrap(BodyLog.change([entry(1, arm: 14.5, waist: 32), entry(15, arm: 14.5, waist: 33.25)],
                                                  calendar: calendar))
        XCTAssertEqual(change.waist, 1.25)
        XCTAssertEqual(change.arm, 0)
        XCTAssertEqual(change.since, day(1))
        XCTAssertTrue(change.waistWarning)
    }

    func testGrowingArmsOrASmallWaistChangeDontWarn() throws {
        // Arms up a quarter inch: muscle came with it.
        XCTAssertFalse(try XCTUnwrap(BodyLog.change([entry(1, arm: 14.5, waist: 32), entry(15, arm: 14.75, waist: 33.5)],
                                                    calendar: calendar)).waistWarning)
        // Exactly an inch isn't more than an inch.
        XCTAssertFalse(try XCTUnwrap(BodyLog.change([entry(1, arm: 14.5, waist: 32), entry(15, arm: 14.5, waist: 33)],
                                                    calendar: calendar)).waistWarning)
        // Arms shrinking counts as not growing.
        XCTAssertTrue(try XCTUnwrap(BodyLog.change([entry(1, arm: 14.5, waist: 32), entry(15, arm: 14.25, waist: 33.5)],
                                                   calendar: calendar)).waistWarning)
    }

    func testComparesWithAboutTwoWeeksBack() throws {
        // Measured weekly: the latest is compared with two weeks back, not last week.
        let entries = [entry(1, arm: 14.5, waist: 32), entry(8, arm: 14.5, waist: 32.5), entry(15, arm: 14.5, waist: 33.25)]
        let change = try XCTUnwrap(BodyLog.change(entries.shuffled(), calendar: calendar))
        XCTAssertEqual(change.since, day(1))
        XCTAssertTrue(change.waistWarning)
        // Only a week apart: compared with that one anyway.
        XCTAssertEqual(BodyLog.change([entry(8, arm: 14.5, waist: 32.5), entry(15, arm: 14.5, waist: 33)],
                                      calendar: calendar)?.since, day(8))
        XCTAssertNil(BodyLog.change([entry(15, arm: 14.5, waist: 33)], calendar: calendar))
    }

    func testDueEveryTwoWeeks() {
        XCTAssertTrue(BodyLog.isDue([], on: day(1), calendar: calendar))
        XCTAssertFalse(BodyLog.isDue([entry(1, arm: 14.5, waist: 32)], on: day(14), calendar: calendar))
        XCTAssertTrue(BodyLog.isDue([entry(1, arm: 14.5, waist: 32)], on: day(15), calendar: calendar))
    }

    func testInchFormats() {
        XCTAssertEqual(Format.inches(14.25), "14.25″")
        XCTAssertEqual(Format.inchesChange(1.25), "+1.25″")
        XCTAssertEqual(Format.inchesChange(-0.5), "−0.5″")
        XCTAssertEqual(Format.inchesChange(0.001), "±0″")
    }
}
