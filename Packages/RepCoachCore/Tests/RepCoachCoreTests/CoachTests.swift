import XCTest
@testable import RepCoachCore

func planItem(_ exerciseId: String, on dayKey: String) throws -> PlanItem {
    try XCTUnwrap(try Plan.bundled().days.first { $0.key == dayKey }?.items.first { $0.exerciseId == exerciseId })
}

final class FormatTests: XCTestCase {

    func testWeights() {
        XCTAssertEqual(Format.weight(22.5), "22.5")
        XCTAssertEqual(Format.weight(20), "20")
        XCTAssertEqual(Format.weight(6.25), "6.25")
        XCTAssertEqual(Format.weight(17.500000001), "17.5")
        XCTAssertEqual(Format.weight(0), "0")
        XCTAssertEqual(Format.kg(22.5), "22.5 kg")
    }

    func testRangesAndClock() {
        XCTAssertEqual(Format.range(6, 10), "6–10")
        XCTAssertEqual(Format.range(15, 15), "15")
        XCTAssertEqual(Format.clock(150), "2:30")
        XCTAssertEqual(Format.clock(45), "0:45")
        XCTAssertEqual(Format.clock(-3), "0:00")
    }

    func testSetLines() {
        func sets(_ pairs: [(Double, Int)]) -> [LoggedSet] { pairs.map { LoggedSet(weight: $0.0, reps: $0.1) } }
        XCTAssertEqual(Format.sets(sets([(25, 10), (25, 10), (25, 9)])), "25 kg × 10, 10, 9")
        XCTAssertEqual(Format.sets(sets([(25, 10), (22.5, 12)])), "25×10, 22.5×12")
        XCTAssertEqual(Format.sets(sets([(0, 12), (0, 11)])), "12, 11")
        XCTAssertEqual(Format.sets(sets([(0, 40), (0, 38)]), timed: true), "40s, 38s")
        XCTAssertEqual(Format.sets(sets([(10, 40), (10, 38)]), timed: true), "10 kg · 40s, 38s")
        XCTAssertEqual(Format.sets([]), "")
    }

    func testPrescriptions() throws {
        func line(_ id: String, _ day: String, deload: Bool = false, amrap: Int? = nil) throws -> String {
            let item = try planItem(id, on: day)
            return Format.prescription(item, TargetPlanner.target(for: item, history: [], deload: deload, amrap: amrap))
        }
        XCTAssertEqual(try line("incline-db-press", "wednesday"), "4 × 6–10")
        XCTAssertEqual(try line("incline-db-press", "wednesday", deload: true), "2 × 6–10")
        XCTAssertEqual(try line("bulgarian-split-squat-dbs", "tuesday"), "3 × 8–10/side")
        XCTAssertEqual(try line("copenhagen-plank", "tuesday"), "2 × 20s/side")
        XCTAssertEqual(try line("hollow-body-hold", "friday"), "3 × 20–30s")
        XCTAssertEqual(try line("max-rep-set", "thursday"), "1 × max")
        XCTAssertEqual(try line("volume-sets", "thursday", amrap: 12), "4 × 7")
        XCTAssertEqual(try line("volume-sets", "thursday"), "4 × 60%")
        XCTAssertEqual(try line("recovery-run", "monday"), "30 min")
    }
}

final class CoachLineTests: XCTestCase {

    /// SPEC acceptance check 2: Incline DB Press at 22.5 kg, 5 reps (range 6–10) → drop to 20 kg.
    func testDropLine() throws {
        let p = try XCTUnwrap(Prescription(item: try planItem("incline-db-press", on: "wednesday")))
        let next = ProgressionEngine.nextSet(for: p, weight: 22.5, reps: 5, setIndex: 1, totalSets: 4)
        XCTAssertEqual(Coach.nextSet(next, reps: 5, repMin: p.repMin, repMax: p.repMax),
                       Coach.Line("5 reps, below 6 · drop to 20 kg", .down))
    }

    func testOtherNextSetLines() {
        XCTAssertEqual(Coach.nextSet(.init(weight: 22.5, reason: .raiseWeight), reps: 15, repMin: 8, repMax: 12),
                       Coach.Line("Too light · 22.5 kg next", .up))
        XCTAssertEqual(Coach.nextSet(.init(weight: 20, reason: .keep), reps: 10, repMin: 8, repMax: 12),
                       Coach.Line("In range · stay at 20 kg", .neutral))
        XCTAssertEqual(Coach.nextSet(.init(weight: 20, reason: .keep), reps: 13, repMin: 8, repMax: 12),
                       Coach.Line("Above range · stay at 20 kg", .neutral))
    }

    func testTags() {
        func tag(_ reason: SessionTargetReason) -> String {
            Coach.tag(SessionTarget(weight: 20, sets: 3, reason: reason), increment: 2.5)
        }
        XCTAssertEqual(tag(.increase), "+2.5 kg")
        XCTAssertEqual(tag(.repeatWeight), "+reps")
        XCTAssertEqual(tag(.decrease), "lighter")
        XCTAssertEqual(tag(.deload), "deload")
        XCTAssertEqual(tag(.firstTime), "set weight")
    }

    func testExplanations() {
        func explain(_ reason: SessionTargetReason) -> String {
            Coach.explain(SessionTarget(weight: 20, sets: 3, reason: reason), increment: 2.5)
        }
        XCTAssertEqual(explain(.increase), "Every set hit the top of the range last time. Up 2.5 kg.")
        XCTAssertEqual(explain(.repeatWeight), "Same weight as last time. Aim to beat its reps.")
        XCTAssertEqual(explain(.firstTime), "No history yet. Pick a starting weight on the watch.")
        XCTAssertEqual(explain(.deload), "Deload week: half the sets at about 85%.")
    }

    func testWeightedSummaries() {
        let p = Prescription(sets: 3, repMin: 6, repMax: 10, increment: 2.5)
        func summary(_ today: [(Double, Int)], before: [[LoggedSet]] = [], deload: Bool = false) -> Coach.Line {
            let sets = today.map { LoggedSet(weight: $0.0, reps: $0.1) }
            let next = ProgressionEngine.firstTarget(for: p, history: [sets] + before)
            return Coach.weightedSummary(today: sets, next: next, prescription: p, deload: deload)
        }
        let missed = [LoggedSet(weight: 20, reps: 5), LoggedSet(weight: 20, reps: 5), LoggedSet(weight: 20, reps: 5)]

        XCTAssertEqual(summary([(20, 10), (20, 10), (20, 10)]), Coach.Line("All sets 10 · next time 22.5 kg", .up))
        XCTAssertEqual(summary([(20, 11), (20, 10), (20, 12)]), Coach.Line("Top of the range · next time 22.5 kg", .up))
        XCTAssertEqual(summary([(20, 9), (20, 8), (20, 8)]),
                       Coach.Line("Same weight next time · aim for more reps", .neutral))
        XCTAssertEqual(summary([(20, 5), (20, 5), (20, 5)], before: [missed]),
                       Coach.Line("Two tough sessions · next time 17.5 kg", .down))
        XCTAssertEqual(summary([(17.5, 10), (17.5, 10)], deload: true),
                       Coach.Line("Deload logged · progression picks up next week", .done))
    }

    func testPullUpsAtTheTopOnceSayRepeatIt() {
        let pullUps = Prescription(sets: 5, repMin: 3, repMax: 5, increment: 2.5, sessionsAtTopToProgress: 2)
        let today = Array(repeating: LoggedSet(weight: 15, reps: 5), count: 5)
        let next = ProgressionEngine.firstTarget(for: pullUps, history: [today])
        XCTAssertEqual(Coach.weightedSummary(today: today, next: next, prescription: pullUps, deload: false),
                       Coach.Line("At the top · repeat it next time to go up", .up))
    }

    func testRangeAndAmrapSummaries() {
        XCTAssertEqual(Coach.rangeSummary(topReached: true, top: 12, timed: false),
                       Coach.Line("Top of range. Add weight or make it harder next time.", .up))
        XCTAssertEqual(Coach.rangeSummary(topReached: false, top: 12, timed: false),
                       Coach.Line("Aim for 12 reps on every set", .neutral))
        XCTAssertEqual(Coach.rangeSummary(topReached: false, top: 30, timed: true),
                       Coach.Line("Aim for 30s on every set", .neutral))
        XCTAssertEqual(Coach.amrapSummary(reps: 12, volumeReps: 7), Coach.Line("12 reps · volume sets of 7", .up))
    }
}
