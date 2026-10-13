import XCTest

final class WaypointsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchAndTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Verify Tab Bar Exists
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0))

        // 2. Check all 5 tabs
        let globeTab = tabBar.buttons["Globe"]
        let discoveriesTab = tabBar.buttons["Discoveries"]
        let waypointsTab = tabBar.buttons["Waypoints"]
        let collectionsTab = tabBar.buttons["Collections"]
        let settingsTab = tabBar.buttons["Settings"]

        XCTAssertTrue(globeTab.exists)
        XCTAssertTrue(discoveriesTab.exists)
        XCTAssertTrue(waypointsTab.exists)
        XCTAssertTrue(collectionsTab.exists)
        XCTAssertTrue(settingsTab.exists)

        // 3. Switch to Discoveries Tab
        discoveriesTab.tap()
        XCTAssertTrue(app.navigationBars["Discoveries"].waitForExistence(timeout: 2.0))

        // 4. Switch to Waypoints Tab
        waypointsTab.tap()
        XCTAssertTrue(app.navigationBars["Waypoints"].waitForExistence(timeout: 2.0))

        // 5. Switch to Collections Tab
        collectionsTab.tap()
        XCTAssertTrue(app.navigationBars["Collections"].waitForExistence(timeout: 2.0))

        // 6. Switch to Settings Tab
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2.0))
        
        // 7. Return to Globe Tab
        globeTab.tap()
    }
}
