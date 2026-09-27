import XCTest
import SwiftData
@testable import RepCoachCore

/// Base class for tests that need an in-memory SwiftData store.
class StoreTestCase: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var recorder: WorkoutRecorder!
    var history: HistoryStore!

    let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return cal
    }()

    override func setUpWithError() throws {
        container = try RepCoachStore.makeContainer(inMemory: true)
        context = ModelContext(container)
        recorder = WorkoutRecorder(context: context, calendar: calendar)
        history = HistoryStore(context: context)
    }

    override func tearDown() {
        history = nil
        recorder = nil
        context = nil
        container = nil
    }

    /// 06:00 on the given day of September 2026. The 7th, 14th, 21st and 28th are Mondays.
    func sept(_ day: Int, hour: Int = 6) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour))!
    }

    /// Logs one finished session of `exerciseId` with the given (weight, reps) sets.
    @discardableResult
    func logSession(_ exerciseId: String, on date: Date, dayKey: String = "monday", deload: Bool = false,
                    _ sets: [(Double, Int)]) throws -> WorkoutSession {
        let session = try recorder.startSession(for: dayKey, on: date, isDeload: deload)
        let log = try recorder.log(for: exerciseId, in: session)
        for (weight, reps) in sets {
            try recorder.addSet(to: log, weight: weight, reps: reps, at: date)
        }
        try recorder.complete(log, at: date)
        return session
    }

    func sets(_ pairs: [(Double, Int)]) -> [LoggedSet] {
        pairs.map { LoggedSet(weight: $0.0, reps: $0.1) }
    }
}
