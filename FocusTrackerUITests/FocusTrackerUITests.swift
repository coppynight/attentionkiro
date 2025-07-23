import XCTest

class FocusTrackerUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testAppLaunches() throws {
        // 测试应用是否能正常启动
        XCTAssertTrue(app.tabBars.buttons["首页"].exists)
        XCTAssertTrue(app.tabBars.buttons["统计"].exists)
        XCTAssertTrue(app.tabBars.buttons["设置"].exists)
    }
}