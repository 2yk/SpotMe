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
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 5), "Skip didn't reach \(next)")
        XCTAssertTrue(app.staticTexts[next].waitForExistence(timeout: 5), "Expected \(next) on screen")
    }

    // MARK: Pause

    func testPauseHoldsTheRestAndResumeCarriesOn() {
        let app = launch(screen: "rest")
        let time = app.staticTexts["countdown"]
        XCTAssertTrue(time.waitForExistence(timeout: 10))

        app.swipeRight()
        app.buttons["Pause"].tap()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5))
        app.swipeLeft()
        XCTAssertTrue(pausedLabel(app).waitForExistence(timeout: 5))
        let paused = time.label
        sleep(3)
        XCTAssertEqual(time.label, paused, "The rest kept counting while paused")

        app.swipeRight()
        app.buttons["Resume"].tap()
        XCTAssertTrue(app.buttons["Skip rest"].waitForExistence(timeout: 5), "Resume didn't go back to the rest")
        sleep(3)
        XCTAssertNotEqual(time.label, paused, "The rest didn't carry on after Resume")
        XCTAssertFalse(pausedLabel(app).exists)
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
        // The rating comes first; skipping it goes on to the numbers.
        XCTAssertTrue(app.descendants(matching: .any)["effort-bars"].waitForExistence(timeout: 10), "No rating after Finish")
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.staticTexts["Session finished"].waitForExistence(timeout: 10), "No summary after End")
        app.buttons["Done"].tap()
        XCTAssertFalse(app.buttons["Log set"].exists, "Still on the workout after End")
    }

    /// After Finish the bars ask how hard it was: tap one, Done, and the summary shows the rating.
    func testRatingTheSessionAfterFinish() {
        let app = launch(screen: "set")
        XCTAssertTrue(app.buttons["Log set"].waitForExistence(timeout: 10))
        app.swipeRight()
        app.buttons["End"].tap()
        app.buttons["Finish"].tap()
        let bars = app.descendants(matching: .any)["effort-bars"]
        XCTAssertTrue(bars.waitForExistence(timeout: 10), "No rating after Finish")
        XCTAssertFalse(app.buttons["Done"].isEnabled, "Done should wait for a rating")

        bars.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()
        XCTAssertTrue((bars.value as? String ?? "").hasPrefix("10 · All Out"), "The last bar isn't All Out")
        bars.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.5)).tap()
        let picked = bars.value as? String ?? ""
        XCTAssertTrue(picked.hasPrefix("6 · Moderate"), "The middle bar isn't 6, Moderate: \(picked)")

        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["6 · Moderate"].waitForExistence(timeout: 10), "The summary doesn't show the rating")
        app.buttons["Done"].tap()
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

    private func launch(day: String = "wednesday", screen: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "YES", "-day", day, "-screen", screen]
        app.launch()
        return app
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
            if app.buttons["Skip rest"].exists {
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
