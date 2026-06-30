//
//  SwipeBeatsUITests.swift
//  SwipeBeatsUITests
//
//  Created by Vu Minh Khoi Ha on 20.01.26.
//

import XCTest

final class SwipeBeatsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsMainNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Swipe"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Explore"].exists)
        XCTAssertTrue(app.tabBars.buttons["Favoriten"].exists)
        XCTAssertTrue(app.tabBars.buttons["Playlists"].exists)
    }

    @MainActor
    func testCanOpenPortfolioCoreTabs() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Explore"].tap()
        XCTAssertTrue(app.navigationBars["Explore"].waitForExistence(timeout: 3))

        app.tabBars.buttons["Favoriten"].tap()
        XCTAssertTrue(app.navigationBars["Favoriten"].waitForExistence(timeout: 3))

        app.tabBars.buttons["Playlists"].tap()
        XCTAssertTrue(app.navigationBars["Playlists"].waitForExistence(timeout: 3))
    }
}
