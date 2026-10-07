import XCTest
import SwiftData
@testable import RepCoachCore

/// Swap for today: the database's alternatives, what a swapped-in exercise is, and the marks that keep both
/// devices agreeing about it.
final class SwapTests: StoreTestCase {
    var database: ExerciseDatabase!
    var chest: PlanItem!
    var wednesday: PlanDay!

    override func setUpWithError() throws {
        try super.setUpWithError()
        database = try XCTUnwrap(ExerciseDatabase.shared)
        let plan = try Plan.bundled()
        wednesday = try XCTUnwrap(plan.days.first { $0.key == "wednesday" })
        chest = try XCTUnwrap(wednesday.items.first { $0.exerciseId == "machine-chest-press" })
    }

    // MARK: The database

    func testTheDatabaseLoads() {
        XCTAssertGreaterThan(database.exercises.count, 200)
        XCTAssertEqual(database.exercise(id: "db-bench-press")?.name, "DB Bench Press")
    }

    func testEveryPlanExerciseThatCanBeSwappedHasAnEntry() throws {
        let plan = try Plan.bundled()
        for item in plan.days.flatMap(\.items) where [.weighted, .reps, .timed].contains(item.kind) {
            XCTAssertNotNil(database.entry(forExerciseId: item.exerciseId), "\(item.exerciseId) has no database entry")
        }
    }

    // MARK: Choices

    func testTheChestPressOffersItsSixAlternativesInTheDatabasesOrder() {
        let rows = database.choices(for: chest, slot: chest, injuryAreas: ["lowerBack"])
        XCTAssertEqual(rows.map(\.id), ["db-bench-press", "smith-bench-press", "barbell-bench-press",
                                        "standing-cable-press", "db-floor-press", "push-up"])
        XCTAssertEqual(rows.map(\.name), ["DB Bench Press", "Smith Machine Bench Press", "Barbell Bench Press",
                                          "Standing Cable Chest Press", "DB Floor Press", "Push-Up"])
        XCTAssertEqual(rows.first?.why, "Free weights, deeper stretch, same flat press")
        XCTAssertTrue(rows.allSatisfy { !$0.takeCare && !$0.isOriginal })
    }

    func testAnExerciseRatedAvoidForAnInjuryAreaIsLeftOutAndTakeCareIsFlagged() throws {
        for area in database.exercise(id: "machine-chest-press")!.injury.keys {
            let rows = database.choices(for: chest, slot: chest, injuryAreas: [area])
            let alternatives = database.exercise(id: "machine-chest-press")!.alternatives
                .compactMap { database.exercise(id: $0.id) }
            XCTAssertEqual(rows.map(\.id), alternatives.filter { ($0.injury[area] ?? 0) < 3 }.map(\.id), area)
            for row in rows {
                XCTAssertEqual(row.takeCare, row.exercise?.injury[area] == 2, "\(row.id) for \(area)")
            }
        }
        // The shoulder is where the chest alternatives differ.
        XCTAssertLessThan(database.choices(for: chest, slot: chest, injuryAreas: ["shoulder"]).count, 7)
    }

    func testTheWorstRatingOfSeveralAreasCounts() {
        let one = database.choices(for: chest, slot: chest, injuryAreas: ["shoulder"])
        let both = database.choices(for: chest, slot: chest, injuryAreas: ["shoulder", "lowerBack"])
        XCTAssertEqual(one.map(\.id), both.map(\.id))
    }

    func testAnExerciseAlreadyInTodaysListIsNotOffered() {
        let rows = database.choices(for: chest, slot: chest, injuryAreas: [], excluding: ["db-bench-press"])
        XCTAssertFalse(rows.map(\.id).contains("db-bench-press"))
    }

    func testASwappedItemOffersTheWayBackFirst() throws {
        let bench = try XCTUnwrap(database.exercise(id: "db-bench-press"))
        let swapped = chest.swapped(to: bench)
        let rows = database.choices(for: swapped, slot: chest, injuryAreas: ["lowerBack"])
        XCTAssertEqual(rows.first?.id, "machine-chest-press")
        XCTAssertEqual(rows.first?.isOriginal, true)
        XCTAssertEqual(rows.first?.name, "Machine Chest Press")
        XCTAssertFalse(rows.dropFirst().map(\.id).contains("db-bench-press"))
        XCTAssertFalse(rows.dropFirst().map(\.id).contains("machine-chest-press"))
    }

    func testOnlyWeightedRepsAndTimedItemsCanBeSwapped() throws {
        let items = try Plan.bundled().days.flatMap(\.items)
        for item in items {
            switch item.kind {
            case .checklist, .amrap, .percentOfMax: XCTAssertFalse(database.canSwap(item), item.exerciseId)
            default: break
            }
        }
        XCTAssertTrue(database.canSwap(chest))
    }

    func testAHoldIsOnlyOfferedHolds() throws {
        let plank = try XCTUnwrap(try Plan.bundled().days.flatMap(\.items).first { $0.kind == .timed })
        let rows = database.choices(for: plank, slot: plank, injuryAreas: [])
        XCTAssertTrue(rows.allSatisfy { $0.exercise?.logAs == "timed" }, rows.map(\.id).joined(separator: ", "))
    }

    // MARK: What a swap is

    func testASwappedItemKeepsTheSlotsPrescriptionAndTakesTheExercisesOwnThings() throws {
        let bench = try XCTUnwrap(database.exercise(id: "db-bench-press"))
        let swapped = chest.swapped(to: bench)
        XCTAssertEqual(swapped.exerciseId, "db-bench-press")
        XCTAssertEqual(swapped.name, "DB Bench Press")
        XCTAssertEqual(swapped.kind, .weighted)
        XCTAssertEqual(swapped.increment, bench.incrementKg)
        XCTAssertEqual(swapped.perSide, bench.perSide)
        XCTAssertNil(swapped.note)
        XCTAssertEqual([swapped.sets, swapped.repMin, swapped.repMax, swapped.restSec],
                       [chest.sets, chest.repMin, chest.repMax, chest.restSec])
        XCTAssertEqual(swapped.group, chest.group)
        XCTAssertEqual(swapped.sessionsAtTopToProgress, chest.sessionsAtTopToProgress)
    }

    func testARepsExerciseInAWeightedSlotIsLoggedByReps() throws {
        let pushUp = try XCTUnwrap(database.exercise(id: "push-up"))
        let swapped = chest.swapped(to: pushUp)
        XCTAssertEqual(swapped.kind, .reps)
        XCTAssertEqual(swapped.repMin, 8)
        XCTAssertEqual(swapped.repMax, 10)
    }

    func testTheDayShowsTheSwapInTheSlotsPlace() throws {
        let result = database.applying(["machine-chest-press": "db-bench-press"], to: wednesday)
        let position = try XCTUnwrap(wednesday.items.firstIndex { $0.exerciseId == "machine-chest-press" })
        XCTAssertEqual(result.day.items[position].exerciseId, "db-bench-press")
        XCTAssertEqual(result.day.items.count, wednesday.items.count)
        XCTAssertEqual(result.slotOf, ["db-bench-press": "machine-chest-press"])
    }

    func testASwapForAnExerciseAlreadyInTheDayOrUnknownIsIgnored() {
        XCTAssertEqual(database.applying(["machine-chest-press": "incline-db-press"], to: wednesday).day, wednesday)
        XCTAssertEqual(database.applying(["machine-chest-press": "no-such-exercise"], to: wednesday).day, wednesday)
        XCTAssertEqual(database.applying([:], to: wednesday).day, wednesday)
    }

    func testASwappedInExerciseHasOnlyItsOwnHistory() throws {
        try logSession("machine-chest-press", on: sept(2), dayKey: "wednesday", [(45, 10), (45, 10), (45, 10)])
        let bench = try XCTUnwrap(database.exercise(id: "db-bench-press"))
        let swapped = chest.swapped(to: bench)

        let target = TargetPlanner.target(for: swapped, history: try history.history(for: swapped.exerciseId),
                                          deload: false)
        XCTAssertEqual(target.session?.reason, .firstTime)
        XCTAssertNil(target.weight)

        try logSession("db-bench-press", on: sept(9), dayKey: "wednesday", [(20, 9), (20, 8), (20, 8)])
        let next = TargetPlanner.target(for: swapped, history: try history.history(for: swapped.exerciseId),
                                        deload: false)
        XCTAssertEqual(next.weight, 20)
        XCTAssertEqual(try history.history(for: "machine-chest-press").count, 1)
    }

    func testTheSlotIsKeptOnTheLogAndTravelsWithTheSession() throws {
        let session = try recorder.startSession(for: "wednesday", on: sept(9), isDeload: false)
        let log = try recorder.log(for: "db-bench-press", slot: "machine-chest-press", in: session)
        try recorder.addSet(to: log, weight: 20, reps: 9)
        XCTAssertEqual(log.slotExerciseId, "machine-chest-press")
        XCTAssertEqual(try recorder.log(for: "db-bench-press", in: session), log)

        let phone = try ModelContainer(for: Schema(RepCoachStore.models), configurations: [
            ModelConfiguration("swap-phone", schema: Schema(RepCoachStore.models), isStoredInMemoryOnly: true),
        ])
        let received = try XCTUnwrap(SessionPayload(userInfo: SessionPayload(session).userInfo))
        let stored = try received.upsert(into: ModelContext(phone))
        XCTAssertEqual(stored.logs.first?.exerciseId, "db-bench-press")
        XCTAssertEqual(stored.logs.first?.slotExerciseId, "machine-chest-press")
    }

    func testTimeAndEnergyTravelWithTheSession() throws {
        let session = try recorder.startSession(for: "wednesday", on: sept(9), isDeload: false)
        session.activeSeconds = 2880
        session.energyKcal = 342
        let received = try XCTUnwrap(SessionPayload(userInfo: SessionPayload(session).userInfo))
        XCTAssertEqual(received.activeSeconds, 2880)
        XCTAssertEqual(received.energyKcal, 342)
    }

    func testPayloadsFromBeforeSwapsStillDecode() throws {
        let json = """
        {"id":"\(UUID().uuidString)","date":0,"dayKey":"monday","isDeload":false,
         "logs":[{"exerciseId":"x","order":0,"skipped":false,"sets":[]}]}
        """
        let payload = try JSONDecoder().decode(SessionPayload.self, from: Data(json.utf8))
        XCTAssertNil(payload.logs[0].slotExerciseId)
        XCTAssertNil(payload.activeSeconds)
    }

    // MARK: Marks

    let day = "2026-10-07"

    func mark(_ exercise: String, slot: String = "machine-chest-press", at: TimeInterval) -> SwapMark {
        SwapMark(dayKey: "wednesday", date: day, slot: slot, exercise: exercise, at: Date(timeIntervalSince1970: at))
    }

    func testTheLaterMarkForASlotWins() {
        var marks = SwapMarks()
        XCTAssertTrue(marks.record(mark("db-bench-press", at: 10)))
        XCTAssertTrue(marks.record(mark("smith-bench-press", at: 20)))
        XCTAssertFalse(marks.record(mark("push-up", at: 15)))
        XCTAssertEqual(marks.swaps(dayKey: "wednesday", date: day), ["machine-chest-press": "smith-bench-press"])
    }

    func testTakingASwapBackClearsIt() {
        var marks = SwapMarks()
        marks.record(mark("db-bench-press", at: 10))
        marks.record(mark("machine-chest-press", at: 20))
        XCTAssertEqual(marks.swaps(dayKey: "wednesday", date: day), [:])
    }

    func testSwapsAreForOneDayOnly() {
        var marks = SwapMarks()
        marks.record(mark("db-bench-press", at: 10))
        XCTAssertEqual(marks.swaps(dayKey: "wednesday", date: "2026-10-14"), [:])
        XCTAssertEqual(marks.swaps(dayKey: "friday", date: day), [:])
        marks.prune(before: "2026-10-14")
        XCTAssertTrue(marks.isEmpty)
    }

    func testTwoDevicesSettleOnTheSameAnswerInEitherOrder() {
        var watch = SwapMarks(marks: [mark("db-bench-press", at: 10)])
        var phone = SwapMarks(marks: [mark("push-up", at: 20), mark("db-incline-press", slot: "incline-db-press", at: 5)])
        let watchBefore = watch, phoneBefore = phone
        XCTAssertTrue(watch.merge(phoneBefore))
        XCTAssertFalse(phone.merge(watchBefore), "the phone already had the later mark")
        XCTAssertEqual(watch.swaps(dayKey: "wednesday", date: day), phone.swaps(dayKey: "wednesday", date: day))
        XCTAssertEqual(watch.swaps(dayKey: "wednesday", date: day)["machine-chest-press"], "push-up")
        XCTAssertFalse(watch.merge(phoneBefore))
    }

    func testClearingTheDayReachesTheOtherDevice() {
        var watch = SwapMarks(marks: [mark("db-bench-press", at: 10)])
        var phone = watch
        watch.clear(dayKey: "wednesday", date: day, at: Date(timeIntervalSince1970: 30))
        phone.merge(watch)
        XCTAssertEqual(phone.swaps(dayKey: "wednesday", date: day), [:])
    }

    func testMarksSurviveStorageAndTheMessage() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "SwapTests"))
        defaults.removePersistentDomain(forName: "SwapTests")
        let marks = SwapMarks(marks: [mark("db-bench-press", at: 10)])
        marks.save(to: defaults)
        XCTAssertEqual(SwapMarks.load(from: defaults), marks)
        XCTAssertEqual(SwapMarks(message: marks.message), marks)
        XCTAssertNil(SwapMarks(message: ["other": 1]))
        defaults.removePersistentDomain(forName: "SwapTests")
    }

    func testTheStampIsTheCalendarDay() {
        XCTAssertEqual(SwapMarks.stamp(sept(9), calendar: calendar), "2026-09-09")
    }

    func testSwapsRideTheApplicationContexts() throws {
        let marks = SwapMarks(marks: [mark("db-bench-press", at: 10)])
        let context = SyncContext(settings: TrainingSettings(), overrides: [:], swaps: marks)
        XCTAssertEqual(SyncContext(applicationContext: context.applicationContext)?.swaps, marks)
        let status = WatchStatus(healthAccess: .allowed, swaps: marks)
        XCTAssertEqual(WatchStatus(applicationContext: status.applicationContext)?.swaps, marks)
    }

    func testContextsAndStatusesFromBeforeSwapsStillRead() throws {
        let context = SyncContext(settings: TrainingSettings(), overrides: [:])
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(context)) as? [String: Any])
        object.removeValue(forKey: "swaps")
        let decoded = try JSONDecoder().decode(SyncContext.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertTrue(decoded.swaps.isEmpty)
        XCTAssertEqual(decoded.settings.injuryAreas, ["lowerBack"])
    }
}

/// The complication never starts a second session.
final class OpenFromOutsideTests: XCTestCase {
    func testAWorkoutUnderWayIsContinuedWhateverTheTapSays() {
        for start in [true, false] {
            XCTAssertEqual(OpenFromOutside.decide(isRunning: true, isFinished: false, isComplete: false, wantsStart: start),
                           .continueWorkout)
            // Even a finished-looking day: a running workout (Start again's) is the one to return to.
            XCTAssertEqual(OpenFromOutside.decide(isRunning: true, isFinished: true, isComplete: true, wantsStart: start),
                           .continueWorkout)
        }
    }

    func testAFinishedDayOpensFinishedAndNeverStartsAgain() {
        XCTAssertEqual(OpenFromOutside.decide(isRunning: false, isFinished: true, isComplete: false, wantsStart: true),
                       .showToday)
        XCTAssertEqual(OpenFromOutside.decide(isRunning: false, isFinished: true, isComplete: true, wantsStart: true),
                       .showToday)
    }

    func testOnlyADayWithNothingStartedStarts() {
        XCTAssertEqual(OpenFromOutside.decide(isRunning: false, isFinished: false, isComplete: false, wantsStart: true),
                       .startToday)
    }

    func testAPlainOpenOrAFullDayJustShowsToday() {
        XCTAssertEqual(OpenFromOutside.decide(isRunning: false, isFinished: false, isComplete: false, wantsStart: false),
                       .showToday)
        XCTAssertEqual(OpenFromOutside.decide(isRunning: false, isFinished: false, isComplete: true, wantsStart: true),
                       .showToday)
    }
}
