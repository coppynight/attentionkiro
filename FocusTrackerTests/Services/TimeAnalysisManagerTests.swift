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
        let usageMonitor = TestUsageMonitor()
        focusManager = FocusManager(usageMonitor: usageMonitor, viewContext: testContext)
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
    
    // MARK: - Monitoring Tests
    
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
        // Given: No usage sessions
        let today = Date()
        
        // When: Getting usage statistics
        let stats = timeAnalysisManager.getUsageStatistics(for: today)
        
        // Then: Should return empty statistics
        XCTAssertEqual(stats.totalUsageTime, 0, "Total usage time should be 0")
        XCTAssertEqual(stats.appCount, 0, "App count should be 0")
        XCTAssertEqual(stats.longestSession, 0, "Longest session should be 0")
        XCTAssertEqual(stats.averageSession, 0, "Average session should be 0")
        XCTAssertNil(stats.mostUsedApp, "Most used app should be nil")
        XCTAssertEqual(stats.productiveTime, 0, "Productive time should be 0")
        XCTAssertEqual(stats.productivityRatio, 0, "Productivity ratio should be 0")
    }
    
    func testGetUsageStatisticsWithData() throws {
        // Given: Usage sessions for today
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        
        let session1 = AppUsageSession.createSession(
            appIdentifier: "com.test.app1",
            appName: "Test App 1",
            startTime: startOfDay.addingTimeInterval(3600), // 1 hour after start of day
            in: testContext
        )
        session1.duration = 30 * 60 // 30 minutes
        session1.endTime = session1.startTime.addingTimeInterval(session1.duration)
        session1.isProductiveTime = true
        
        let session2 = AppUsageSession.createSession(
            appIdentifier: "com.test.app2",
            appName: "Test App 2",
            startTime: startOfDay.addingTimeInterval(7200), // 2 hours after start of day
            in: testContext
        )
        session2.duration = 45 * 60 // 45 minutes
        session2.endTime = session2.startTime.addingTimeInterval(session2.duration)
        session2.isProductiveTime = false
        
        try testContext.save()
        
        // When: Getting usage statistics
        let stats = timeAnalysisManager.getUsageStatistics(for: today)
        
        // Then: Should return correct statistics
        XCTAssertEqual(stats.totalUsageTime, 75 * 60, "Total usage time should be 75 minutes")
        XCTAssertEqual(stats.appCount, 2, "App count should be 2")
        XCTAssertEqual(stats.longestSession, 45 * 60, "Longest session should be 45 minutes")
        XCTAssertEqual(stats.productiveTime, 30 * 60, "Productive time should be 30 minutes")
    }
    
    func testGetWeeklyTrendEmptyData() throws {
        // Given: No usage sessions
        
        // When: Getting weekly trend
        let weeklyTrend = timeAnalysisManager.getWeeklyTrend()
        
        // Then: Should return 7 days of empty data
        XCTAssertEqual(weeklyTrend.count, 7, "Should have 7 days of data")
        
        for dayData in weeklyTrend {
            XCTAssertEqual(dayData.totalUsageTime, 0, "Each day should have 0 usage time")
            XCTAssertEqual(dayData.appCount, 0, "Each day should have 0 apps")
            XCTAssertEqual(dayData.sessionCount, 0, "Each day should have 0 sessions")
            XCTAssertEqual(dayData.productiveTime, 0, "Each day should have 0 productive time")
            XCTAssertTrue(dayData.topApps.isEmpty, "Each day should have no top apps")
        }
        
        // Should be sorted chronologically (oldest to newest)
        for i in 1..<weeklyTrend.count {
            XCTAssertTrue(weeklyTrend[i-1].date <= weeklyTrend[i].date, "Dates should be in chronological order")
        }
    }
    
    func testGetAppUsageBreakdownEmptyData() throws {
        // Given: No usage sessions
        let today = Date()
        
        // When: Getting app usage breakdown
        let breakdown = timeAnalysisManager.getAppUsageBreakdown(for: today)
        
        // Then: Should return empty array
        XCTAssertTrue(breakdown.isEmpty, "Breakdown should be empty")
    }
    
    func testGetSceneTagDistributionEmptyData() throws {
        // Given: No tagged sessions
        let today = Date()
        
        // When: Getting scene tag distribution
        let distribution = timeAnalysisManager.getSceneTagDistribution(for: today)
        
        // Then: Should return empty array
        XCTAssertTrue(distribution.isEmpty, "Distribution should be empty")
    }
    
    func testCombinedStatistics() throws {
        // Given: Both focus sessions and app usage sessions
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
        
        // When: Getting combined statistics
        let combined = timeAnalysisManager.getCombinedStatistics(for: today)
        
        // Then: Should return both focus and usage statistics
        XCTAssertEqual(combined.focus.totalFocusTime, 30 * 60, "Focus time should be 30 minutes")
        XCTAssertEqual(combined.usage.totalUsageTime, 45 * 60, "Usage time should be 45 minutes")
        XCTAssertEqual(combined.usage.productiveTime, 45 * 60, "Productive time should be 45 minutes")
    }
    
    func testUsageStatisticsPerformance() throws {
        // Given: Many usage sessions
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        
        for i in 0..<100 {
            let session = AppUsageSession.createSession(
                appIdentifier: "com.test.app\(i % 10)", // 10 different apps
                appName: "Test App \(i % 10)",
                startTime: startOfDay.addingTimeInterval(TimeInterval(i * 60)), // 1 minute apart
                in: testContext
            )
            session.duration = TimeInterval((i % 10 + 1) * 60) // 1-10 minutes
            session.endTime = session.startTime.addingTimeInterval(session.duration)
            session.isProductiveTime = i % 2 == 0
        }
        
        try testContext.save()
        
        // When: Getting usage statistics
        measure {
            _ = timeAnalysisManager.getUsageStatistics(for: today)
        }
    }
}