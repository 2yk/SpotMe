import XCTest
@testable import RepCoachCore

final class SetsCSVTests: StoreTestCase {

    func testEverySetOneRowOldestFirst() throws {
        // Two sessions, stored newest first: rows still come out oldest first.
        let wednesday = try logSession("incline-db-press", on: sept(9), dayKey: "wednesday", [(22.5, 8), (22.5, 7)])
        let monday = try recorder.startSession(for: "monday", on: sept(7), isDeload: true)
        let pullUps = try recorder.log(for: "weighted-pull-ups", in: monday)
        try recorder.addSet(to: pullUps, weight: 15, reps: 5, at: sept(7))
        let plank = try recorder.log(for: "weighted-plank", in: monday)
        try recorder.addSet(to: plank, weight: 10, reps: 0, seconds: 42, at: sept(7, hour: 7))
        try recorder.skip(plank)

        let csv = SetsCSV.make(sessions: [wednesday, monday],
                               names: ["incline-db-press": "Incline DB Press", "weighted-plank": "Plank, weighted"],
                               dayTitles: ["monday": "Monday", "wednesday": "Wednesday"], calendar: calendar)
        XCTAssertEqual(csv, """
            Date,Time,Day,Exercise,Exercise ID,Set,Weight (kg),Reps,Seconds,Deload,Skipped,Session,Ramp-up,Effort
            2026-09-07,06:00,Monday,weighted-pull-ups,weighted-pull-ups,1,15,5,,yes,,\(monday.id.uuidString),,
            2026-09-07,07:00,Monday,"Plank, weighted",weighted-plank,1,10,,42,yes,yes,\(monday.id.uuidString),,
            2026-09-09,06:00,Wednesday,Incline DB Press,incline-db-press,1,22.5,8,,,,\(wednesday.id.uuidString),,
            2026-09-09,06:00,Wednesday,Incline DB Press,incline-db-press,2,22.5,7,,,,\(wednesday.id.uuidString),,

            """)
    }

    /// Ramp-up sets are exported, marked; the effort is on every row of its session.
    func testRampUpSetsAreMarkedAndEffortIsOnEveryRow() throws {
        let wednesday = try recorder.startSession(for: "wednesday", on: sept(9), isDeload: false)
        let press = try recorder.log(for: "incline-db-press", in: wednesday)
        try recorder.addSet(to: press, weight: 10, reps: 8, at: sept(9), isRampUp: true)
        try recorder.addSet(to: press, weight: 15, reps: 4, at: sept(9), isRampUp: true)
        try recorder.addSet(to: press, weight: 22.5, reps: 8, at: sept(9))
        let curls = try recorder.log(for: "incline-db-curl", in: wednesday)
        try recorder.addSet(to: curls, weight: 10, reps: 12, at: sept(9, hour: 7))
        try recorder.finish(wednesday, at: sept(9, hour: 8))
        try recorder.setEffort(7, on: wednesday)
        let friday = try logSession("incline-db-curl", on: sept(11), dayKey: "friday", [(10, 12)])

        let csv = SetsCSV.make(sessions: [friday, wednesday],
                               names: ["incline-db-press": "Incline DB Press", "incline-db-curl": "Incline DB Curl"],
                               dayTitles: ["wednesday": "Wednesday", "friday": "Friday"], calendar: calendar)
        let id = wednesday.id.uuidString
        XCTAssertEqual(csv, """
            Date,Time,Day,Exercise,Exercise ID,Set,Weight (kg),Reps,Seconds,Deload,Skipped,Session,Ramp-up,Effort
            2026-09-09,06:00,Wednesday,Incline DB Press,incline-db-press,1,10,8,,,,\(id),yes,7
            2026-09-09,06:00,Wednesday,Incline DB Press,incline-db-press,2,15,4,,,,\(id),yes,7
            2026-09-09,06:00,Wednesday,Incline DB Press,incline-db-press,3,22.5,8,,,,\(id),,7
            2026-09-09,07:00,Wednesday,Incline DB Curl,incline-db-curl,1,10,12,,,,\(id),,7
            2026-09-11,06:00,Friday,Incline DB Curl,incline-db-curl,1,10,12,,,,\(friday.id.uuidString),,

            """)
    }

    func testNothingLoggedIsJustTheHeader() {
        XCTAssertEqual(SetsCSV.make(sessions: [], names: [:], dayTitles: [:]), SetsCSV.header.joined(separator: ",") + "\n")
    }

    func testQuotesAndCommasAreEscaped() {
        XCTAssertEqual(SetsCSV.escape("Biceps · 15\" Goal"), "\"Biceps · 15\"\" Goal\"")
        XCTAssertEqual(SetsCSV.escape("Row, bent over"), "\"Row, bent over\"")
        XCTAssertEqual(SetsCSV.escape("Face Pulls"), "Face Pulls")
    }
}
