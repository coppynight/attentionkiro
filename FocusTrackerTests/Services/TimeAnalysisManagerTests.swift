import XCTest
import CoreData
@testable import FocusTracker

class TimeAnalysisManagerTests: XCTestCase {
    
    var testContext: NSManagedObjectContext!
    var timeAnalysisManager: TimeAnalysisManager!
    var focusManager: FocusManager!
    var tagManager: TagManager!
    var testPersistenceController: TestPersistenceController!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create test persistence controller
        testPersistenceController = TestPersistenceController()
        testContext = testPersistenceController.container.viewContext
        
        // Create dependencies
        focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        tagManager = TagManager(viewContext: testContext)
        
        // Create TimeAnalysisManager
        timeAnalysisManager = TimeAnalysisManager(
            viewContext: testContext,
            focusManager: focusManager,
            tagManager: tagManager
        )
    }
    
    override func tearDownWithError() throws {
        testContext = nil
        timeAnalysisManager = nil
        focusManager = nil
        tagManager = nil
        testPersistenceController = nil
        try super.tearDownWithError()
    }
    
    func testStartStopMonitoring() throws {
        // Initially not monitoring
        XCTAssertFalse(timeAnalysisManager.isMonitoring, "Should not be monitoring initially")
        
        // Start monitoring
        timeAnalysisManager.startMonitoring()
        XCTAssertTrue(timeAnalysisManager.isMonitoring, "Should be monitoring after start")
        
        // Stop monitoring
        timeAnalysisManager.stopMonitoring()
        XCTAssertFalse(timeAnalysisManager.isMonitoring, "Should not be monitoring after stop")
    }
    
    func testGetUsageStatisticsEmptyData() throws {
        let today = Date()
        let stats = timeAnalysisManager.getUsageStatistics(for: today)
        
        XCTAssertEqual(stats.totalUsageTime, 0, "Total usage time should be 0")
        XCTAssertEqual(stats.appCount, 0, "App count should be 0")
        XCTAssertEqual(stats.longestSession, 0, "Longest session should be 0")
        XCTAssertEqual(stats.averageSession, 0, "Average session should be 0")
        XCTAssertNil(stats.mostUsedApp, "Most used app should be nil")
        XCTAssertEqual(stats.productiveTime, 0, "Productive time should be 0")
        XCTAssertEqual(stats.productivityRatio, 0, "Productivity ratio should be 0")
    }
    
    func testGetWeeklyTrendEmptyData() throws {
        let weeklyTrend = timeAnalysisManager.getWeeklyTrend()
        
        XCTAssertEqual(weeklyTrend.count, 7, "Should have 7 days of data")
        
        for dayData in weeklyTrend {
            XCTAssertEqual(dayData.totalUsageTime, 0, "Each day should have 0 usage time")
            XCTAssertEqual(dayData.appCount, 0, "Each day should have 0 apps")
            XCTAssertEqual(dayData.sessionCount, 0, "Each day should have 0 sessions")
            XCTAssertEqual(dayData.productiveTime, 0, "Each day should have 0 productive time")
            XCTAssertTrue(dayData.topApps.isEmpty, "Each day should have no top apps")
        }
    }
    
    func testGetAppUsageBreakdownEmptyData() throws {
        let today = Date()
        let breakdown = timeAnalysisManager.getAppUsageBreakdown(for: today)
        
        XCTAssertTrue(breakdown.isEmpty, "Breakdown should be empty")
    }
    
    func testGetSceneTagDistributionEmptyData() throws {
        let today = Date()
        let distribution = timeAnalysisManager.getSceneTagDistribution(for: today)
        
        XCTAssertTrue(distribution.isEmpty, "Distribution should be empty")
    }
    
    func testCombinedStatistics() throws {
        let today = Date()
        
        // Create focus session
        let focusSession = FocusSession(context: testContext)
        focusSession.startTime = today
        focusSession.endTime = today.addingTimeInterval(30 * 60)
        focusSession.duration = 30 * 60
        focusSession.isValid = true
        
        // Create app usage session
        let appSession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            startTime: today,
            in: testContext
        )
        appSession.duration = 45 * 60
        appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
        appSession.isProductiveTime = true
        
        try testContext.save()
        
        let combined = timeAnalysisManager.getCombinedStatistics(for: today)
        
        XCTAssertEqual(combined.focus.totalFocusTime, 30 * 60, "Focus time should be 30 minutes")
        XCTAssertEqual(combined.usage.totalUsageTime, 45 * 60, "Usage time should be 45 minutes")
        XCTAssertEqual(combined.usage.productiveTime, 45 * 60, "Productive time should be 45 minutes")
    }
}
