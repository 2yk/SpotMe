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

    // MARK: Weight and reps

    func testPlusAndMinusMoveExactlyOneStep() {
        let app = launch(screen: "set")
        let weight = app.descendants(matching: .any)["weight-value"]
        let reps = app.descendants(matching: .any)["reps-value"]
        XCTAssertTrue(weight.waitForExistence(timeout: 10))
        let startWeight = number(weight)
        let startReps = number(reps)

        app.buttons["More weight"].tap()
        XCTAssertEqual(number(weight), startWeight + 2.5)
        app.buttons["Less weight"].tap()
        app.buttons["Less weight"].tap()
        XCTAssertEqual(number(weight), startWeight - 2.5)

        app.buttons["More reps"].tap()
        app.buttons["More reps"].tap()
        XCTAssertEqual(number(reps), startReps + 2)
        app.buttons["Fewer reps"].tap()
        XCTAssertEqual(number(reps), startReps + 1)
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
