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
        let breakingBadTitle = app.buttons["BREAKING BAD"]
        XCTAssertTrue(markWatchedButtons.firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(breakingBadTitle.exists)
        captureScreenshot(named: "Up Next - Before", app: app)

        markWatchedButtons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Watched"].waitForExistence(timeout: 0.3))
        captureScreenshot(named: "Up Next - Remove feedback", app: app)
        XCTAssertTrue(breakingBadTitle.waitForNonExistence(timeout: 2))

        markWatchedButtons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Watched"].waitForExistence(timeout: 0.3))
        captureScreenshot(named: "Up Next - Replace feedback", app: app)
        XCTAssertTrue(app.buttons["Goodbye, Mrs. Selvig"].waitForExistence(timeout: 2))
        captureScreenshot(named: "Up Next - Next episode", app: app)
    }

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
