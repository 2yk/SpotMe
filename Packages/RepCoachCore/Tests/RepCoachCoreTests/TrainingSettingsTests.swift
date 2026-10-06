import XCTest
@testable import RepCoachCore

final class TrainingSettingsTests: XCTestCase {
    let plan = try! Plan.bundled()
    let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return cal
    }()

    func date(_ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 7))!
    }

    func testSettingsSavedBeforeTheHealthSwitchKeepHealthOn() throws {
        let saved = #"{"programStart":780710400,"restHaptics":false}"#
        let settings = try JSONDecoder().decode(TrainingSettings.self, from: Data(saved.utf8))
        XCTAssertTrue(settings.healthWorkouts)
        XCTAssertFalse(settings.restHaptics)
        XCTAssertEqual(settings.programStart, Date(timeIntervalSinceReferenceDate: 780710400))

        var off = settings
        off.healthWorkouts = false
        XCTAssertEqual(try JSONDecoder().decode(TrainingSettings.self, from: JSONEncoder().encode(off)), off)
    }

    func testProgramWeeks() {
        let settings = TrainingSettings(programStart: date(9, 28))
        XCTAssertEqual(settings.programWeek(on: date(9, 28), calendar: calendar), 1)
        XCTAssertEqual(settings.programWeek(on: date(10, 4), calendar: calendar), 1)
        XCTAssertEqual(settings.programWeek(on: date(10, 5), calendar: calendar), 2)
        XCTAssertNil(settings.programWeek(on: date(9, 27), calendar: calendar))
        XCTAssertNil(TrainingSettings().programWeek(on: date(9, 28), calendar: calendar))
    }

    /// SPEC acceptance check 9, at the settings level: week 6 is a deload.
    func testScheduledDeload() {
        let settings = TrainingSettings(programStart: date(9, 28))
        XCTAssertTrue(settings.isDeload(on: date(11, 2), plan: plan, calendar: calendar))
        XCTAssertFalse(settings.isDeload(on: date(11, 1), plan: plan, calendar: calendar))
        XCTAssertFalse(TrainingSettings().isDeload(on: date(11, 2), plan: plan, calendar: calendar))
    }

    func testWeeksUntilDeload() {
        let settings = TrainingSettings(programStart: date(9, 28))
        XCTAssertEqual(settings.weeksUntilDeload(on: date(10, 12), plan: plan, calendar: calendar), 3)
        XCTAssertEqual(settings.weeksUntilDeload(on: date(11, 2), plan: plan, calendar: calendar), 0)
        XCTAssertEqual(settings.weeksUntilDeload(on: date(11, 9), plan: plan, calendar: calendar), 5)
        XCTAssertNil(TrainingSettings().weeksUntilDeload(on: date(11, 9), plan: plan, calendar: calendar))
    }

    func testManualDeloadLastsForTheProgramWeekItWasSetIn() {
        let settings = TrainingSettings(programStart: date(9, 28), manualDeloadSetOn: date(10, 7))
        XCTAssertTrue(settings.isDeload(on: date(10, 5), plan: plan, calendar: calendar))
        XCTAssertTrue(settings.isDeload(on: date(10, 11), plan: plan, calendar: calendar))
        XCTAssertFalse(settings.isDeload(on: date(10, 12), plan: plan, calendar: calendar))
    }

    func testManualDeloadWithoutAStartDateUsesTheCalendarWeek() {
        let settings = TrainingSettings(manualDeloadSetOn: date(10, 7))
        XCTAssertTrue(settings.manualDeloadActive(on: date(10, 8), calendar: calendar))
        XCTAssertFalse(settings.manualDeloadActive(on: date(10, 20), calendar: calendar))
    }

    func testRoundTripsThroughJSON() throws {
        let settings = TrainingSettings(programStart: date(9, 28), manualDeloadSetOn: nil, restHaptics: false)
        let decoded = try JSONDecoder().decode(TrainingSettings.self, from: JSONEncoder().encode(settings))
        XCTAssertEqual(decoded, settings)
    }
}

final class DemoDataTests: StoreTestCase {

    func testSeedsWeeksOfProgressAndTodaysSession() throws {
        let today = sept(27, hour: 9)
        try DemoData.seed(context, plan: try Plan.bundled(), weeks: 8, today: today, calendar: calendar,
                          inProgress: "monday")

        let session = try XCTUnwrap(try recorder.session(for: "monday", on: today))
        XCTAssertEqual(session.log(for: "weighted-pull-ups")?.status, .inProgress(setsDone: 2))
        XCTAssertEqual(session.statuses["recovery-run"]?.isFinished, true)
        XCTAssertEqual(session.statuses["monday-warmup"]?.isFinished, true)

        let pullUps = try history.history(for: "weighted-pull-ups", excluding: session.id)
        XCTAssertEqual(pullUps.count, 8)
        let weights = pullUps.reversed().map { $0[0].weight }
        XCTAssertEqual(weights, weights.sorted(), "weights never go down")

        let press = try history.history(for: "incline-db-press").reversed().map { $0[0].weight }
        XCTAssertGreaterThan(press.last!, press.first!)

        let plank = try XCTUnwrap(try history.history(for: "weighted-plank").first?.first)
        XCTAssertGreaterThan(plank.reps, 0, "timed sets store seconds")
    }

    func testRampUpsDefaultToMainLiftsAndSettingsSavedBeforeThemKeepThat() throws {
        XCTAssertEqual(TrainingSettings().rampUps, .mainLifts)
        let saved = #"{"programStart":780710400,"restHaptics":false,"healthWorkouts":false}"#
        let settings = try JSONDecoder().decode(TrainingSettings.self, from: Data(saved.utf8))
        XCTAssertEqual(settings.rampUps, .mainLifts)
        XCTAssertFalse(settings.healthWorkouts)
    }

    func testRampUpSettingRoundTripsAndAnUnknownValueFallsBack() throws {
        for setting in RampUpSetting.allCases {
            let settings = TrainingSettings(restHaptics: false, rampUps: setting)
            XCTAssertEqual(try JSONDecoder().decode(TrainingSettings.self, from: JSONEncoder().encode(settings)), settings)
        }
        let future = #"{"restHaptics":false,"rampUps":"everySet"}"#
        let settings = try JSONDecoder().decode(TrainingSettings.self, from: Data(future.utf8))
        XCTAssertEqual(settings.rampUps, .mainLifts)
        XCTAssertFalse(settings.restHaptics)
    }
}
