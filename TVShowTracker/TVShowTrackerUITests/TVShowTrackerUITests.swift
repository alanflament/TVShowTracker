//
//  TVShowTrackerUITests.swift
//  TVShowTrackerUITests
//
//  Created by Alan Flament on 29/07/2026.
//

import XCTest

final class TVShowTrackerUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testUpNextWatchedFeedbackAndCardTransitions() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-data"]
        app.launch()

        let markWatchedButtons = app.buttons.matching(identifier: "Mark as watched")
        let breakingBadTitle = app.buttons["Breaking Bad"]
        XCTAssertTrue(markWatchedButtons.firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(breakingBadTitle.exists)
        captureScreenshot(named: "Up Next - Before", app: app)

        markWatchedButtons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Watched"].waitForExistence(timeout: 0.3))
        captureScreenshot(named: "Up Next - Remove feedback", app: app)
        XCTAssertTrue(breakingBadTitle.waitForNonExistence(timeout: 2))
        captureScreenshot(named: "Up Next - After completed show", app: app)

        markWatchedButtons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Watched"].waitForExistence(timeout: 0.3))
        captureScreenshot(named: "Up Next - Replace feedback", app: app)
        XCTAssertTrue(app.buttons["Goodbye, Mrs. Selvig"].waitForExistence(timeout: 2))
        captureScreenshot(named: "Up Next - Next episode", app: app)
    }

    @MainActor
    func testEpisodeDurationAppearsInUpNextAndDetails() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-data"]
        app.launch()

        let breakingBadCard = app.buttons["Breaking Bad"]
        XCTAssertTrue(breakingBadCard.waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["S01E16"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["55 min"].exists)

        breakingBadCard.tap()

        XCTAssertTrue(app.navigationBars["Felina"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["55 min"].waitForExistence(timeout: 2))
        captureScreenshot(named: "Episode Details - Duration", app: app)
    }

    @MainActor
    func testEpisodeListPlacesMarkAllActionAfterSeasons() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-data"]
        app.launch()

        app.buttons["My Shows"].tap()

        let breakingBadCard = app.buttons["Breaking Bad, Watching"]
        XCTAssertTrue(breakingBadCard.waitForExistence(timeout: 3))
        breakingBadCard.tap()

        let episodesButton = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Episodes,"))
            .firstMatch
        XCTAssertTrue(episodesButton.waitForExistence(timeout: 3))
        episodesButton.tap()

        let seasonHeader = app.buttons["Season 1"]
        let markAllButton = app.buttons["Mark all available episodes as watched"]
        XCTAssertTrue(seasonHeader.waitForExistence(timeout: 3))
        XCTAssertTrue(markAllButton.waitForExistence(timeout: 3))
        XCTAssertGreaterThan(markAllButton.frame.minY, seasonHeader.frame.maxY)

        app.scrollViews.firstMatch.swipeUp()
        captureScreenshot(named: "Episodes - Mark all after seasons", app: app)
    }

    @MainActor
    func testShowPosterOpensFullScreenAndDismisses() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-data"]
        app.launch()

        app.buttons["My Shows"].tap()

        let breakingBadCard = app.buttons["Breaking Bad, Watching"]
        XCTAssertTrue(breakingBadCard.waitForExistence(timeout: 3))
        breakingBadCard.tap()

        let posterButton = app.buttons["View Breaking Bad poster full screen"]
        XCTAssertTrue(posterButton.waitForExistence(timeout: 3))
        posterButton.tap()

        let closeButton = app.buttons["Close poster"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 2))
        captureScreenshot(named: "Show Details - Full-screen poster", app: app)

        let fullScreenPoster = app.otherElements["Full-screen poster"]
        XCTAssertTrue(fullScreenPoster.waitForExistence(timeout: 2))
        fullScreenPoster.pinch(withScale: 2, velocity: 1)
        XCTAssertEqual(fullScreenPoster.value as? String, "Zoomed")
        captureScreenshot(named: "Show Details - Zoomed poster", app: app)

        fullScreenPoster.doubleTap()
        let fittedPoster = NSPredicate(format: "value == %@", "Fit to screen")
        expectation(for: fittedPoster, evaluatedWith: fullScreenPoster)
        waitForExpectations(timeout: 2)
        closeButton.tap()

        XCTAssertTrue(posterButton.waitForExistence(timeout: 2))
        XCTAssertTrue(app.navigationBars["Breaking Bad"].exists)
    }

    @MainActor
    func testAppAppearanceCanChangeImmediately() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo-data"]
        app.launch()

        app.buttons["Settings"].tap()

        let appearancePicker = app.buttons["App appearance"]
        XCTAssertTrue(appearancePicker.waitForExistence(timeout: 3))

        appearancePicker.tap()
        app.buttons["Automatic"].tap()
        XCTAssertTrue(waitForValue("Automatic", in: appearancePicker))
        captureScreenshot(named: "Settings - Automatic appearance", app: app)

        appearancePicker.tap()
        app.buttons["Light"].tap()
        XCTAssertTrue(waitForValue("Light", in: appearancePicker))
        captureScreenshot(named: "Settings - Light appearance", app: app)

        appearancePicker.tap()
        app.buttons["Dark"].tap()
        XCTAssertTrue(waitForValue("Dark", in: appearancePicker))
        captureScreenshot(named: "Settings - Dark appearance", app: app)
    }

    private func waitForValue(_ value: String, in element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "value == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter.wait(for: [expectation], timeout: 2) == .completed
    }

    @MainActor
    private func captureScreenshot(named name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchPerformance() {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
