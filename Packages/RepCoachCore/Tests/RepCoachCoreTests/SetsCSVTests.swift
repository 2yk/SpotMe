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
            Date,Time,Day,Exercise,Exercise ID,Set,Weight (kg),Reps,Seconds,Deload,Skipped,Session
            2026-09-07,06:00,Monday,weighted-pull-ups,weighted-pull-ups,1,15,5,,yes,,\(monday.id.uuidString)
            2026-09-07,07:00,Monday,"Plank, weighted",weighted-plank,1,10,,42,yes,yes,\(monday.id.uuidString)
            2026-09-09,06:00,Wednesday,Incline DB Press,incline-db-press,1,22.5,8,,,,\(wednesday.id.uuidString)
            2026-09-09,06:00,Wednesday,Incline DB Press,incline-db-press,2,22.5,7,,,,\(wednesday.id.uuidString)

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
