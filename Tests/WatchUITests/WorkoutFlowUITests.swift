import XCTest

/// Real taps through the watch workout, on the simulator, against the demo store (`-demo YES`). Wednesday's
/// demo session has Incline DB Press under way, then Machine Chest Press, Seated DB Shoulder Press and more.
final class WorkoutFlowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: The break

    /// ▶ on the break starts what's next, every time, however many exercises in.
    func testStartNowStartsTheNextExerciseEveryTime() {
        let app = launch(screen: "next")
        for round in 1...3 {
            let button = startNow(app)
            XCTAssertTrue(button.waitForExistence(timeout: 10), "No break in round \(round)")
            let next = String(button.label.dropFirst("Start ".count).dropLast(" now".count))
            button.tap()
            skipRampUpIfShown(app)
            XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 5), "▶ didn't start \(next)")
            XCTAssertTrue(app.staticTexts[next].exists, "Expected \(next) on screen")
            finishExercise(app)
        }
    }

    /// The ring itself starts what's next too.
    func testTappingTheRingStartsTheNextExercise() {
        let app = launch(screen: "next")
        let ring = app.buttons["Break before the next exercise"]
        XCTAssertTrue(ring.waitForExistence(timeout: 10))
        let next = nextName(app)
        ring.tap()
        skipRampUpIfShown(app)
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[next].exists)
    }

    // MARK: Skip

    func testSkipDuringASetMovesToTheNextExercise() {
        let app = launch(screen: "set")
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 10))
        skipAndExpectTheNextExercise(app)
    }

    func testSkipDuringARestMovesToTheNextExercise() {
        let app = launch(screen: "rest")
        XCTAssertTrue(app.buttons["Skip rest"].waitForExistence(timeout: 10))
        skipAndExpectTheNextExercise(app)
    }

    func testSkipDuringTheBreakStartsTheNextExercise() {
        let app = launch(screen: "next")
        XCTAssertTrue(startNow(app).waitForExistence(timeout: 10))
        skipAndExpectTheNextExercise(app)
    }

    /// Skip shows where it leads; tapping it goes there and the workout page comes back.
    private func skipAndExpectTheNextExercise(_ app: XCUIApplication) {
        app.swipeRight()
        let skip = app.buttons["Skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        let hint = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Skip to '")).firstMatch
        XCTAssertTrue(hint.waitForExistence(timeout: 5))
        let next = String(hint.label.dropFirst("Skip to ".count))
        skip.tap()
        skipRampUpIfShown(app)
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 5), "Skip didn't reach \(next)")
        XCTAssertTrue(app.staticTexts[next].waitForExistence(timeout: 5), "Expected \(next) on screen")
    }

    /// Skip puts the exercise off: it stays open, and Today says it is waiting.
    func testSkipPutsTheExerciseOffAndTodayShowsItWaiting() {
        let app = launch(screen: "set")
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 10))
        app.swipeRight()
        let skip = app.buttons["Skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["This one stays open"].exists, "Skip should say the exercise stays open")
        skip.tap()
        skipRampUpIfShown(app)
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 5))
        app.swipeRight()
        app.buttons["List"].tap()
        let waiting = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'waiting'")).firstMatch
        XCTAssertTrue(waiting.waitForExistence(timeout: 5), "The skipped exercise isn't marked waiting")
    }

    // MARK: Ramp-ups

    /// A main lift opens on its ramp-up: tap Done, rest 60 s with no Undo, then the next ramp-up, then set 1.
    func testRampUpsComeBeforeTheFirstWorkingSet() {
        let app = launch(screen: "item", extra: ["-fresh", "YES", "-item", "incline-db-press"])
        let first = app.staticTexts["1 of 2 · not counted"]
        XCTAssertTrue(first.waitForExistence(timeout: 10), "No ramp-up first")
        XCTAssertFalse(app.buttons["Log set"].exists)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Skip rest"].waitForExistence(timeout: 5), "No rest after the ramp-up")
        XCTAssertFalse(app.buttons["Undo last set"].exists, "A ramp-up can't be undone")
        app.buttons["Skip rest"].tap()
        XCTAssertTrue(app.staticTexts["2 of 2 · not counted"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.buttons["Skip rest"].tap()
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 5), "Set 1 didn't open after the ramp-ups")
    }

    /// Skip on the ramp-up screen drops the rest of them and opens set 1 with no rest.
    func testSkippingTheRampUpOpensSetOne() {
        let app = launch(screen: "item", extra: ["-fresh", "YES", "-item", "incline-db-press"])
        let skip = app.buttons["Skip the ramp-up"]
        XCTAssertTrue(skip.waitForExistence(timeout: 10))
        skip.tap()
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Skip rest"].exists)
    }

    // MARK: Pause

    /// Pause stops the workout's clock and heart rate, never a running rest: it keeps counting.
    func testPauseNeverPausesTheRest() {
        let app = launch(screen: "rest")
        let time = app.staticTexts["countdown"]
        XCTAssertTrue(time.waitForExistence(timeout: 10))

        app.swipeRight()
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5))
        app.swipeLeft()
        XCTAssertTrue(pausedLabel(app).waitForExistence(timeout: 5), "The paused workout isn't shown")
        let paused = time.label
        sleep(3)
        XCTAssertNotEqual(time.label, paused, "The rest stopped counting while the workout was paused")

        app.swipeRight()
        app.buttons["Resume"].tap()
        XCTAssertTrue(app.buttons["Skip rest"].waitForExistence(timeout: 5), "Resume didn't go back to the rest")
        XCTAssertFalse(pausedLabel(app).exists)
    }

    // MARK: No back button, no reasons

    /// A workout screen has no back button, and Today is reached from the controls page's List.
    func testWorkoutScreensHaveNoBackButton() {
        let app = launch(screen: "set")
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Back"].exists, "The set screen has a back button")
        XCTAssertEqual(app.navigationBars.buttons.count, 0, "The bar holds a button on the set screen")
        app.swipeRight()
        XCTAssertTrue(app.buttons["List"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Back"].exists, "The controls page has a back button")
        app.buttons["List"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Continue'")).firstMatch
            .waitForExistence(timeout: 5), "List didn't go to Today")
    }

    /// A rest has no "Rest" title and never says why the weight moved.
    func testARestHasNoTitleAndNoReason() {
        let app = launch(screen: "rest")
        XCTAssertTrue(app.buttons["Skip rest"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Rest"].exists, "A rest has a title")
        let reasons = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS[c] 'below' OR label CONTAINS[c] 'above' OR label CONTAINS[c] 'in range' "
                + "OR label CONTAINS[c] 'stay at' OR label CONTAINS[c] 'drop to' OR label CONTAINS[c] 'up to'"))
        XCTAssertEqual(reasons.count, 0, "The rest explains the weight: \(reasons.firstMatch.label)")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH[c] 'next'")).firstMatch.exists)
    }

    /// The break shows what's next and nothing about how the last exercise went.
    func testTheBreakHasNoResultLine() {
        let app = launch(screen: "next")
        XCTAssertTrue(startNow(app).waitForExistence(timeout: 10))
        let results = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS[c] 'next time' OR label CONTAINS[c] 'all sets' OR label CONTAINS[c] 'aim for' "
                + "OR label CONTAINS[c] 'top of range' OR label == 'Logged'"))
        XCTAssertEqual(results.count, 0, "The break says how it went: \(results.firstMatch.label)")
    }

    // MARK: Finished

    /// After a Finish with items left, Today says Finished and offers Start again; the same day picks up.
    func testAFinishedDayOffersStartAgain() {
        let app = launch(screen: "finished", extra: ["-fresh", "YES"])
        XCTAssertTrue(app.staticTexts["Finished"].waitForExistence(timeout: 10), "No Finished card")
        let again = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Start again'")).firstMatch
        XCTAssertTrue(again.exists, "No Start again")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Continue'")).firstMatch.exists)
        XCTAssertFalse(app.buttons["Finish workout"].exists)
        again.tap()
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 10), "Start again didn't open the next item")
    }

    /// A day finished with everything done has no Start again.
    func testAFinishedDayWithNothingLeftHasNoStartAgain() {
        let app = launch(screen: "finished-all", extra: ["-fresh", "YES"])
        XCTAssertTrue(app.staticTexts["Finished"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Start again'")).firstMatch.exists)
    }

    // MARK: Swap

    /// Swap exercise, from the How sheet: pick an alternative and the set screen shows it.
    func testSwapFromTheHowSheet() {
        let app = launch(screen: "item", extra: ["-fresh", "YES", "-item", "machine-chest-press"])
        skipRampUpIfShown(app)
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 10))
        app.buttons["How to do it"].tap()
        let swap = app.buttons["Swap exercise"]
        XCTAssertTrue(swap.waitForExistence(timeout: 5), "How has no Swap exercise")
        swap.tap()
        XCTAssertTrue(app.staticTexts["Instead of Machine Chest Press"].waitForExistence(timeout: 5))
        let bench = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'DB Bench Press'")).firstMatch
        XCTAssertTrue(bench.exists, "No DB Bench Press among the alternatives")
        bench.tap()
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 10), "Back on the set screen")
        XCTAssertTrue(app.staticTexts["DB Bench Press"].waitForExistence(timeout: 5), "The swapped-in exercise isn't shown")
        XCTAssertFalse(app.staticTexts["Machine Chest Press"].exists)
    }

    // MARK: Outside

    /// A complication tap while a rest runs returns to that rest: no second session, no fresh start.
    func testTheComplicationReturnsToTheWorkoutUnderWay() {
        let app = launch(screen: "tap-running")
        XCTAssertTrue(app.buttons["Skip rest"].waitForExistence(timeout: 10), "No rest under way")
        let time = app.staticTexts["countdown"]
        let before = time.label
        sleep(5) // the tap comes after two seconds
        XCTAssertTrue(app.buttons["Skip rest"].exists, "The tap left the rest")
        XCTAssertFalse(app.buttons["Skip the ramp-up"].exists, "The tap started something again")
        XCTAssertNotEqual(time.label, before, "The rest stopped")
    }

    // MARK: Pages

    /// Now Playing is to the right; coming back, the workout and its title are still there.
    func testMusicIsOnTheRightAndTheWorkoutComesBack() {
        let app = launch(screen: "set")
        let log = app.buttons["Log set"]
        XCTAssertTrue(log.waitForExistence(timeout: 10))
        let title = "Incline DB Press"
        XCTAssertTrue(app.staticTexts[title].exists)
        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["Not Playing"].waitForExistence(timeout: 15)
            || app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'play'")).firstMatch.exists,
                      "Now Playing isn't to the right")
        app.swipeRight()
        XCTAssertTrue(log.waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 15), "The title didn't come back")
    }

    // MARK: End

    /// End from the controls asks first, then finishes and goes back to Today with the summary.
    func testEndFinishesTheWorkout() {
        let app = launch(screen: "set")
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 10))
        app.swipeRight()
        app.buttons["End"].tap()
        let finish = app.buttons["Finish"]
        XCTAssertTrue(finish.waitForExistence(timeout: 5), "End didn't ask first")
        finish.tap()
        // How hard was it? comes first; Save keeps the answer, then the summary shows it.
        XCTAssertTrue(app.staticTexts["How hard was it?"].waitForExistence(timeout: 10), "No effort question")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Session finished"].waitForExistence(timeout: 5), "No summary after End")
        app.buttons["Done"].tap()
        XCTAssertFalse(app.buttons["Log set"].exists, "Still on the workout after End")
    }

    /// End offers Discard too: it throws the day away and goes back to Today, where it starts afresh.
    func testEndCanDiscardTheWorkout() {
        let app = launch(screen: "set")
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 10))
        app.swipeRight()
        app.buttons["End"].tap()
        let discard = app.buttons["Discard workout"]
        XCTAssertTrue(discard.waitForExistence(timeout: 5), "End didn't offer Discard")
        XCTAssertFalse(app.buttons["Save to Health"].exists, "Finishing shouldn't ask about Health")
        discard.tap()
        // Discard asks once more.
        let confirm = app.buttons["Discard"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Discard didn't ask again")
        confirm.tap()
        let start = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Start workout'")).firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Not back on a fresh Today after Discard")
        XCTAssertFalse(app.buttons["Log set"].exists)
    }

    // MARK: Weight and reps

    /// No − or +: tap the weight and the Crown moves it by whole increments, and back to exactly where it was.
    func testWeightMovesByWholeIncrementsWithTheCrown() {
        let app = launch(screen: "set")
        let weight = app.descendants(matching: .any)["weight-value"]
        XCTAssertTrue(weight.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["More reps"].exists)
        XCTAssertFalse(app.buttons["Less weight"].exists)
        let start = number(weight)

        weight.tap()
        XCUIDevice.shared.rotateDigitalCrown(delta: 0.25)
        let turned = number(weight)
        XCTAssertGreaterThan(turned, start)
        let steps = (turned - start) / 2.5
        XCTAssertEqual(steps, steps.rounded(), accuracy: 1e-9, "Weight landed between increments")

        XCUIDevice.shared.rotateDigitalCrown(delta: -0.25)
        XCTAssertEqual(number(weight), start, "Turning back didn't return to the start")
    }

    /// Turning the Crown moves reps in whole steps, and turning it back lands exactly where it started.
    func testTheCrownMovesWholeStepsAndComesBack() {
        let app = launch(screen: "set")
        let reps = app.descendants(matching: .any)["reps-value"]
        XCTAssertTrue(reps.waitForExistence(timeout: 10))
        let start = number(reps)

        XCUIDevice.shared.rotateDigitalCrown(delta: 0.25)
        let turned = number(reps)
        XCTAssertGreaterThan(turned, start)
        XCTAssertEqual(turned, turned.rounded(), "Reps landed between steps")

        XCUIDevice.shared.rotateDigitalCrown(delta: -0.25)
        XCTAssertEqual(number(reps), start, "Turning back didn't return to the start")
    }

    // MARK: Helpers

    private func launch(day: String = "wednesday", screen: String, extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "YES", "-day", day, "-screen", screen] + extra
        app.launch()
        return app
    }

    /// A main lift opens on its ramp-up first; the tests of the working sets skip it.
    private func skipRampUpIfShown(_ app: XCUIApplication) {
        let skip = app.buttons["Skip the ramp-up"]
        if skip.waitForExistence(timeout: 2) { skip.tap() }
    }

    /// The break's ▶, whose label names what it starts: "Start Machine Chest Press now".
    private func startNow(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Start ' AND label ENDSWITH ' now'")).firstMatch
    }

    /// The ring's "Paused", in capitals on screen.
    private func pausedLabel(_ app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label ==[c] 'paused'")).firstMatch
    }

    private func nextName(_ app: XCUIApplication) -> String {
        String(startNow(app).label.dropFirst("Start ".count).dropLast(" now".count))
    }

    /// Logs every set of the exercise on screen, skipping each rest, until its break.
    private func finishExercise(_ app: XCUIApplication) {
        for _ in 0..<20 {
            if startNow(app).waitForExistence(timeout: 1) { return }
            if app.buttons["Skip the ramp-up"].exists {
                app.buttons["Skip the ramp-up"].tap()
            } else if app.buttons["Skip rest"].exists {
                app.buttons["Skip rest"].tap()
            } else if app.buttons["Log set"].exists {
                app.buttons["Log set"].tap()
            }
        }
        XCTFail("The exercise never reached its break")
    }

    /// The number in a value row's accessibility value: "22.5 kg" → 22.5.
    private func number(_ element: XCUIElement) -> Double {
        let text = (element.value as? String) ?? ""
        return Double(text.split(separator: " ").first ?? "") ?? .nan
    }
}
