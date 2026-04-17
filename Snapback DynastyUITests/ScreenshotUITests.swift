import XCTest

/// Captures a screenshot of every major screen so teammates without a Mac
/// can review UI changes from CI artifacts. Each `screenshot(named:)` call
/// attaches a PNG to the test result bundle; CI extracts them with xcparse.
final class ScreenshotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureAllTabs() throws {
        let app = XCUIApplication()
        app.launch()

        // Initial render — if a team-picker comes up before the dashboard,
        // that's fine; the first shot documents the app's cold-start state.
        wait(1.5)
        screenshot(named: "01-launch", app: app)

        tapTab(app: app, label: "Home")
        screenshot(named: "02-home", app: app)

        tapTab(app: app, label: "Roster")
        screenshot(named: "03-roster", app: app)

        tapTab(app: app, label: "Season")
        screenshot(named: "04-season", app: app)

        tapTab(app: app, label: "Dynasty")
        screenshot(named: "05-dynasty", app: app)
    }

    // MARK: - Helpers

    private func tapTab(app: XCUIApplication, label: String) {
        let button = app.tabBars.buttons[label]
        guard button.waitForExistence(timeout: 4) else { return }
        button.tap()
        wait(1.2)
    }

    private func screenshot(named name: String, app: XCUIApplication) {
        let shot = app.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func wait(_ seconds: TimeInterval) {
        let exp = expectation(description: "sleep")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { exp.fulfill() }
        wait(for: [exp], timeout: seconds + 1)
    }
}
