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

    // MARK: Ten points

    func full(_ day: Int, _ values: [BodyPoint: Double]) -> BodyLog.Entry {
        BodyLog.Entry(date: self.day(day), values: values)
    }

    func testEveryPointIsComparedWithItsOwnEarlierMeasurement() throws {
        // The weight was left blank on day 15 and measured on 8 and 22: it compares 22 with 8.
        let entries = [
            full(1, [.arm: 14.25, .waist: 32, .weight: 72]),
            full(8, [.arm: 14.25, .weight: 72.2]),
            full(15, [.arm: 14.5, .waist: 32.25]),
            full(22, [.arm: 14.5, .waist: 32.25, .weight: 72.6]),
        ]
        let change = try XCTUnwrap(BodyLog.change(entries.shuffled(), calendar: calendar))
        XCTAssertEqual(change.since, day(8))
        XCTAssertEqual(try XCTUnwrap(change.deltas[.arm]), 0.25, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(change.deltas[.weight]), 0.4, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(change.deltas[.waist]), 0.25, accuracy: 1e-9)
        XCTAssertNil(change.deltas[.neck], "never measured")
    }

    func testAPointMeasuredOnceHasNoChange() throws {
        let change = try XCTUnwrap(BodyLog.change([full(1, [.arm: 14]), full(15, [.arm: 14.25, .calf: 14.5])],
                                                  calendar: calendar))
        XCTAssertNotNil(change.deltas[.arm])
        XCTAssertNil(change.deltas[.calf])
    }

    func testTheWaistRuleNeedsBothMeasured() throws {
        // Waist up two inches, arm never measured: nothing to compare, no warning.
        let change = try XCTUnwrap(BodyLog.change([full(1, [.waist: 32]), full(15, [.waist: 34])], calendar: calendar))
        XCTAssertEqual(change.waist, 2)
        XCTAssertNil(change.arm)
        XCTAssertFalse(change.waistWarning)
    }

    func testSeriesIsOldestFirstAndSkipsBlanks() {
        let entries = [full(15, [.arm: 14.5]), full(1, [.arm: 14.25, .weight: 72]), full(8, [.weight: 72.2])]
        XCTAssertEqual(BodyLog.series(entries, point: .arm).map(\.value), [14.25, 14.5])
        XCTAssertEqual(BodyLog.series(entries, point: .weight).map(\.value), [72, 72.2])
        XCTAssertTrue(BodyLog.series(entries, point: .neck).isEmpty)
    }

    func testPointFormatsAndSteps() {
        XCTAssertEqual(BodyPoint.weight.format(72.4), "72.4 kg")
        XCTAssertEqual(BodyPoint.arm.format(14.25), "14.25″")
        XCTAssertEqual(BodyPoint.weight.formatChange(0.3), "+0.3")
        XCTAssertEqual(BodyPoint.weight.formatChange(-0.04), "±0")
        XCTAssertEqual(BodyPoint.calf.formatChange(0.25), "+0.25″")
        XCTAssertEqual(BodyPoint.weight.step, 0.1)
        XCTAssertEqual(BodyPoint.neck.step, 0.25)
        XCTAssertEqual(BodyPoint.Group.allCases.flatMap(\.points), BodyPoint.allCases)
    }

    func testAStoredMeasurementReadsAndWritesByPoint() {
        let measurement = BodyMeasurement(date: day(1), arm: 14.5, waist: 32)
        measurement[.weight] = 72.4
        XCTAssertEqual(measurement.entry.values, [.arm: 14.5, .waist: 32, .weight: 72.4])
    }
}
