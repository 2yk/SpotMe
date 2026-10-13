import XCTest
import SwiftData
@testable import RepCoachCore

/// Rearranging the days: a workout keeps its key (history is keyed on it) and takes another weekday.
final class PlanScheduleTests: StoreTestCase {
    let plan = try! Plan.bundled().withoutRuns()

    // Calendar weekdays: Monday 2 … Saturday 7, Sunday 1.
    let monday = 2, tuesday = 3, wednesday = 4, saturday = 7, sunday = 1

    var edits: PlanEdits {
        var edits = PlanEdits()
        edits.swapWorkouts(on: monday, and: wednesday, plan: plan)
        return edits
    }

    func day(_ plan: Plan, weekday: Int) -> PlanDay {
        plan.days.first { $0.weekday == weekday }!
    }

    func workout(_ plan: Plan, key: String) -> PlanDay {
        plan.days.first { $0.key == key }!
    }

    func testNoScheduleLeavesThePlanAlone() {
        XCTAssertEqual(PlanEdits().applied(to: plan), plan)
        XCTAssertFalse(PlanEdits().isRearranged(plan))
        XCTAssertEqual(PlanEdits().workoutKeys(in: plan), plan.days.map(\.key))
    }

    func testTheMappingPutsEachWorkoutOnItsNewWeekday() {
        let result = edits.applied(to: plan)

        // The workout on Monday is Push A now: the first day, with Monday's weekday and name, and its own key.
        let onMonday = day(result, weekday: monday)
        XCTAssertEqual(onMonday.key, "wednesday")
        XCTAssertEqual(onMonday.title, "Monday")
        XCTAssertEqual(onMonday.focus, workout(plan, key: "wednesday").focus)
        XCTAssertEqual(onMonday.items, workout(plan, key: "wednesday").items)

        let onWednesday = day(result, weekday: wednesday)
        XCTAssertEqual(onWednesday.key, "monday")
        XCTAssertEqual(onWednesday.title, "Wednesday")
        XCTAssertEqual(onWednesday.focus, workout(plan, key: "monday").focus)

        // The others stay where they were, and the days stay in order, Monday to Sunday.
        XCTAssertEqual(result.days.map(\.title), plan.days.map(\.title))
        XCTAssertEqual(result.days.map(\.weekday), plan.days.map(\.weekday))
        XCTAssertEqual(result.days.map(\.key), ["wednesday", "tuesday", "monday", "thursday", "friday", "saturday", "sunday"])
        XCTAssertEqual(Set(result.days.map(\.key)), Set(plan.days.map(\.key)))
    }

    func testSwappingTwoDaysAndSwappingBackIsTheIdentity() {
        var edits = self.edits
        XCTAssertEqual(edits.schedule, [monday: "wednesday", wednesday: "monday"])
        XCTAssertTrue(edits.isRearranged(plan))
        XCTAssertFalse(edits.isEmpty)

        edits.swapWorkouts(on: wednesday, and: monday, plan: plan)
        XCTAssertTrue(edits.schedule.isEmpty)
        XCTAssertFalse(edits.isRearranged(plan))
        XCTAssertTrue(edits.isEmpty, "The plan's own weekdays are no edit, so nothing is stored")
        XCTAssertEqual(edits.applied(to: plan), plan)
    }

    func testARestDayMovesLikeAnyWorkout() {
        var edits = PlanEdits()
        edits.swapWorkouts(on: saturday, and: tuesday, plan: plan)
        let result = edits.applied(to: plan)

        let rest = day(result, weekday: tuesday)
        XCTAssertEqual(rest.key, "saturday")
        XCTAssertEqual(rest.title, "Tuesday")
        XCTAssertEqual(rest.focus, "Full Rest")
        XCTAssertEqual(rest.items, workout(plan, key: "saturday").items)

        let legs = day(result, weekday: saturday)
        XCTAssertEqual(legs.key, "tuesday")
        XCTAssertEqual(legs.title, "Saturday")
        XCTAssertTrue(legs.items.contains { $0.kind == .weighted })
        XCTAssertEqual(result.day(forWeekday: saturday)?.key, "tuesday")
    }

    func testThreeWorkoutsCanMoveAtOnce() {
        var edits = PlanEdits()
        edits.swapWorkouts(on: monday, and: tuesday, plan: plan)
        edits.swapWorkouts(on: tuesday, and: wednesday, plan: plan)
        // Monday has Legs, Tuesday has Push A, Wednesday has Pull A.
        XCTAssertEqual(edits.workoutKeys(in: plan).prefix(3), ["tuesday", "wednesday", "monday"])
        XCTAssertEqual(edits.schedule.count, 3)
        let result = edits.applied(to: plan)
        XCTAssertEqual(result.day(forWeekday: monday)?.key, "tuesday")
        XCTAssertEqual(result.day(forWeekday: tuesday)?.key, "wednesday")
        XCTAssertEqual(result.day(forWeekday: wednesday)?.key, "monday")
    }

    func testTodayFollowsTheWeekday() {
        // Wednesday 7 Oct 2026 is a Wednesday: Pull A (key "monday") after the swap, not Push A.
        let wednesdayDate = calendar.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 9))!
        XCTAssertEqual(plan.day(for: wednesdayDate, calendar: calendar)?.key, "wednesday")
        let result = edits.applied(to: plan)
        XCTAssertEqual(result.day(for: wednesdayDate, calendar: calendar)?.key, "monday")
        let mondayDate = calendar.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 9))!
        XCTAssertEqual(result.day(for: mondayDate, calendar: calendar)?.key, "wednesday")
        // The same lookup on the schedule alone, which is what the watch face has: the plan as shipped.
        XCTAssertEqual(edits.scheduled(plan).day(for: wednesdayDate, calendar: calendar)?.key, "monday")
    }

    func testAppliedTwiceIsTheSameAsOnce() {
        let once = edits.applied(to: plan)
        XCTAssertEqual(edits.applied(to: once), once)
        XCTAssertEqual(edits.scheduled(edits.scheduled(plan)), edits.scheduled(plan))
    }

    func testArrangeTakesWholeOrdersOnly() {
        var edits = PlanEdits()
        let keys = plan.days.map(\.key)
        edits.arrange(Array(keys.reversed()), on: plan)
        XCTAssertEqual(edits.workoutKeys(in: plan), Array(keys.reversed()))

        // Not a rearrangement of the seven workouts: nothing changes.
        let before = edits
        edits.arrange(Array(keys.dropLast()), on: plan)
        edits.arrange(Array(keys.dropLast()) + ["monday"], on: plan)
        edits.arrange(Array(keys.dropLast()) + ["nonsense"], on: plan)
        XCTAssertEqual(edits, before)

        edits.arrange(keys, on: plan)
        XCTAssertTrue(edits.isEmpty)
    }

    /// A stored schedule that doesn't put every workout on a weekday once (a plan that changed under it) is
    /// ignored rather than dropping a workout.
    func testAnInvalidScheduleIsIgnored() {
        let doubled = PlanEdits(schedule: [monday: "wednesday"])
        XCTAssertEqual(doubled.applied(to: plan), plan)
        XCTAssertEqual(doubled.workoutKeys(in: plan), plan.days.map(\.key))
        let unknown = PlanEdits(schedule: [monday: "gone", 9: "monday"])
        XCTAssertEqual(unknown.applied(to: plan), plan)
    }

    func testExerciseEditsStayWithTheWorkout() {
        var edits = self.edits
        let monday = workout(plan, key: "monday")
        edits.remove("face-pulls", from: monday)
        let result = edits.applied(to: plan)
        // Pull A is on Wednesday now, without Face Pulls; the weekday it left has Push A's list untouched.
        XCTAssertFalse(day(result, weekday: wednesday).items.contains { $0.exerciseId == "face-pulls" })
        XCTAssertEqual(day(result, weekday: self.monday).items, workout(plan, key: "wednesday").items)
        XCTAssertEqual(edits.itemIds(for: monday).contains("face-pulls"), false)
    }

    func testHistoryStaysWithTheWorkout() throws {
        // Two Push A sessions (key "wednesday"), then Push A is moved to Monday.
        try logSession("incline-db-press", on: sept(9), dayKey: "wednesday", [(20, 10), (20, 9)])
        try logSession("incline-db-press", on: sept(16), dayKey: "wednesday", [(20, 10), (20, 10)])
        let before = try history.history(for: "incline-db-press")

        try edits.save(to: context)
        let stored = PlanEdits.load(from: context)
        let result = stored.applied(to: plan)

        // Nothing in the store changed: same sessions, same keys, same history.
        XCTAssertEqual(try history.history(for: "incline-db-press"), before)
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        XCTAssertEqual(Set(sessions.map(\.dayKey)), ["wednesday"])
        XCTAssertNotNil(try recorder.session(for: "wednesday", on: sept(9)))
        // The workout those sessions belong to is still found by its key, now on a Monday.
        let pushA = workout(result, key: "wednesday")
        XCTAssertEqual(pushA.weekday, monday)
        XCTAssertEqual(pushA.title, "Monday")
        XCTAssertTrue(pushA.items.contains { $0.exerciseId == "incline-db-press" })
    }

    func testTheScheduleSurvivesTheStore() throws {
        var edits = self.edits
        edits.remove("face-pulls", from: workout(plan, key: "monday"))
        try edits.save(to: context)
        XCTAssertEqual(PlanEdits.load(from: context), edits)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanEditsRecord>()), 1)

        // Only the schedule: still stored; putting the days back leaves no row.
        try PlanEdits(schedule: self.edits.schedule).save(to: context)
        XCTAssertEqual(PlanEdits.load(from: context).schedule, [monday: "wednesday", wednesday: "monday"])
        var back = PlanEdits.load(from: context)
        back.resetSchedule()
        try back.save(to: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanEditsRecord>()), 0)
    }

    func testEditsSavedBeforeSchedulesStillRead() throws {
        let old = #"{"days":{"monday":["monday-warmup"]},"custom":{}}"#
        let edits = try JSONDecoder().decode(PlanEdits.self, from: Data(old.utf8))
        XCTAssertEqual(edits.days, ["monday": ["monday-warmup"]])
        XCTAssertTrue(edits.schedule.isEmpty)
    }

    /// The phone's edits reach the watch through the sync context; both apply them with `applied(to:)`.
    func testTheScheduleTravelsToTheWatch() throws {
        var phoneEdits = edits
        phoneEdits.remove("face-pulls", from: workout(plan, key: "monday"))
        let sent = SyncContext(settings: TrainingSettings(), overrides: [:], plan: phoneEdits)

        // Over WatchConnectivity and back.
        let received = try XCTUnwrap(SyncContext(applicationContext: sent.applicationContext))
        XCTAssertEqual(received, sent)
        XCTAssertEqual(received.plan.schedule, [monday: "wednesday", wednesday: "monday"])

        // The watch's own store (the base class's) takes it and reads the same plan back.
        try received.applyPlan(to: context)
        let onTheWatch = PlanEdits.load(from: context)
        XCTAssertEqual(onTheWatch, phoneEdits)
        XCTAssertEqual(onTheWatch.applied(to: plan), phoneEdits.applied(to: plan))
        XCTAssertEqual(onTheWatch.applied(to: plan).day(forWeekday: monday)?.key, "wednesday")

        // And a later context without the schedule puts the days back.
        let reset = SyncContext(settings: TrainingSettings(), overrides: [:], plan: PlanEdits())
        try reset.applyPlan(to: context)
        XCTAssertEqual(PlanEdits.load(from: context).applied(to: plan), plan)
    }

    func testTheComplicationReadsTheScheduleFromTheAppGroup() throws {
        let suite = "PlanScheduleTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertEqual(ComplicationState.loadSchedule(from: defaults), [:])
        XCTAssertTrue(ComplicationState.saveSchedule(edits.schedule, to: defaults))
        XCTAssertFalse(ComplicationState.saveSchedule(edits.schedule, to: defaults), "Unchanged: no redraw")
        let schedule = ComplicationState.loadSchedule(from: defaults)
        XCTAssertEqual(PlanEdits(schedule: schedule).scheduled(plan).day(forWeekday: wednesday)?.key, "monday")
    }
}
