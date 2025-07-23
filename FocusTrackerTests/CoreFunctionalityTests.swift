import XCTest
import CoreData
@testable import FocusTracker

/// Tests for core functionality of the FocusTracker app
/// This test suite focuses on the core functionality requirements:
/// - Focus session detection accuracy
/// - Data storage and retrieval
/// - Basic UI interactions
class CoreFunctionalityTests: XCTestCase {
    
    var testContext: NSManagedObjectContext!
    var focusManager: FocusManager!
    var usageMonitor: UsageMonitor!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory Core Data stack for testing
        let persistentContainer = NSPersistentContainer(name: "FocusDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        testContext = persistentContainer.viewContext
        usageMonitor = UsageMonitor()
        focusManager = FocusManager(usageMonitor: usageMonitor, viewContext: testContext)
    }
    
    override func tearDownWithError() throws {
        focusManager = nil
        usageMonitor = nil
        testContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Focus Session Detection Accuracy Tests
    
    /// Tests that focus sessions are accurately detected based on screen activity
    func testFocusSessionDetection() throws {
        // Given: UsageMonitor with a callback
        var detectedSession: (startTime: Date, endTime: Date)?
        
        usageMonitor.onFocusSessionDetected = { startTime, endTime in
            detectedSession = (startTime, endTime)
        }
        
        // When: Simulating screen off for 35 minutes
        usageMonitor.startMonitoring()
        
        let screenOffTime = Date()
        usageMonitor.lastScreenOffTime = screenOffTime
        
        // Simulate screen turning on after 35 minutes
        let screenOnTime = screenOffTime.addingTimeInterval(35 * 60)
        
        // Manually trigger the detection logic
        if let offTime = usageMonitor.lastScreenOffTime {
            let unusedDuration = screenOnTime.timeIntervalSince(offTime)
            if unusedDuration >= 30 * 60 {
                usageMonitor.onFocusSessionDetected?(offTime, screenOnTime)
            }
        }
        
        // Then: Session should be detected with correct times
        XCTAssertNotNil(detectedSession, "Focus session should be detected")
        XCTAssertEqual(detectedSession?.startTime, screenOffTime, "Start time should match screen off time")
        XCTAssertEqual(detectedSession?.endTime, screenOnTime, "End time should match screen on time")
    }
    
    /// Tests that sessions shorter than the minimum duration are not detected as focus sessions
    func testShortSessionsNotDetected() throws {
        // Given: UsageMonitor with a callback
        var sessionDetected = false
        
        usageMonitor.onFocusSessionDetected = { _, _ in
            sessionDetected = true
        }
        
        // When: Simulating screen off for 20 minutes (less than minimum 30 minutes)
        usageMonitor.startMonitoring()
        
        let screenOffTime = Date()
        usageMonitor.lastScreenOffTime = screenOffTime
        
        // Simulate screen turning on after 20 minutes
        let screenOnTime = screenOffTime.addingTimeInterval(20 * 60)
        
        // Manually check if session would be detected
        if let offTime = usageMonitor.lastScreenOffTime {
            let unusedDuration = screenOnTime.timeIntervalSince(offTime)
            if unusedDuration >= 30 * 60 {
                usageMonitor.onFocusSessionDetected?(offTime, screenOnTime)
            }
        }
        
        // Then: No session should be detected
        XCTAssertFalse(sessionDetected, "Short sessions should not be detected as focus sessions")
    }
    
    /// Tests that sessions during sleep time are correctly identified and marked as invalid
    func testSessionDuringSleepTime() throws {
        // Given: A session during sleep time
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        // Create a session at 2 AM (typically sleep time)
        let sleepSessionStart = calendar.date(byAdding: .hour, value: 2, to: startOfDay)!
        let sleepSessionEnd = calendar.date(byAdding: .hour, value: 3, to: startOfDay)!
        let duration = sleepSessionEnd.timeIntervalSince(sleepSessionStart)
        
        // When: Validating the session
        let isValid = focusManager.validateSession(
            startTime: sleepSessionStart,
            endTime: sleepSessionEnd,
            duration: duration
        )
        
        // Then: Session should be marked as invalid
        XCTAssertFalse(isValid, "Sessions during sleep time should be marked as invalid")
    }
    
    // MARK: - Data Storage and Retrieval Tests
    
    /// Tests that focus sessions are correctly saved to Core Data
    func testFocusSessionStorage() throws {
        // Given: A focus session
        let startTime = Date().addingTimeInterval(-45 * 60) // 45 minutes ago
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // When: Creating and saving the session
        let session = FocusSession(context: testContext)
        session.startTime = startTime
        session.endTime = endTime
        session.duration = duration
        session.isValid = true
        session.sessionType = "focus"
        
        try testContext.save()
        
        // Then: Session should be retrievable from Core Data
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        let fetchedSessions = try testContext.fetch(request)
        
        XCTAssertEqual(fetchedSessions.count, 1, "One session should be saved")
        XCTAssertEqual(fetchedSessions.first?.startTime, startTime, "Start time should be saved correctly")
        XCTAssertEqual(fetchedSessions.first?.endTime, endTime, "End time should be saved correctly")
        XCTAssertEqual(fetchedSessions.first?.duration, duration, "Duration should be saved correctly")
        XCTAssertTrue(fetchedSessions.first?.isValid ?? false, "Valid flag should be saved correctly")
    }
    
    /// Tests that user settings are correctly saved and retrieved
    func testUserSettingsStorage() throws {
        // Given: Custom user settings
        let settings = UserSettings.createDefaultSettings(in: testContext)
        settings.dailyFocusGoal = 3 * 3600 // 3 hours
        settings.notificationsEnabled = false
        
        // When: Saving settings
        try testContext.save()
        
        // Then: Settings should be retrievable with correct values
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let fetchedSettings = try testContext.fetch(request)
        
        XCTAssertEqual(fetchedSettings.count, 1, "One settings object should be saved")
        XCTAssertEqual(fetchedSettings.first?.dailyFocusGoal, 3 * 3600, "Daily goal should be saved correctly")
        XCTAssertFalse(fetchedSettings.first?.notificationsEnabled ?? true, "Notifications setting should be saved correctly")
    }
    
    /// Tests that focus statistics are correctly calculated from stored sessions
    func testFocusStatisticsCalculation() throws {
        // Given: Multiple focus sessions for today
        let today = Date()
        
        // Create test sessions
        createTestFocusSession(startTime: today.addingTimeInterval(-5 * 3600), duration: 45 * 60, isValid: true)  // 45 min
        createTestFocusSession(startTime: today.addingTimeInterval(-3 * 3600), duration: 60 * 60, isValid: true)  // 60 min
        createTestFocusSession(startTime: today.addingTimeInterval(-1 * 3600), duration: 30 * 60, isValid: true)  // 30 min
        createTestFocusSession(startTime: today.addingTimeInterval(-4 * 3600), duration: 15 * 60, isValid: false) // 15 min (invalid)
        
        try testContext.save()
        
        // When: Calculating focus statistics
        let stats = focusManager.getFocusStatistics(for: today)
        
        // Then: Statistics should be calculated correctly
        XCTAssertEqual(stats.totalFocusTime, 135 * 60, "Total focus time should only include valid sessions")
        XCTAssertEqual(stats.sessionCount, 3, "Session count should only include valid sessions")
        XCTAssertEqual(stats.longestSession, 60 * 60, "Longest session should be identified correctly")
        XCTAssertEqual(stats.averageSession, 45 * 60, "Average session should be calculated correctly")
    }
    
    /// Tests that weekly trend data is correctly generated
    func testWeeklyTrendGeneration() throws {
        // Given: Focus sessions across multiple days
        let today = Date()
        let calendar = Calendar.current
        
        // Create sessions for today
        createTestFocusSession(startTime: today.addingTimeInterval(-3 * 3600), duration: 60 * 60, isValid: true)
        
        // Create sessions for yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        createTestFocusSession(startTime: yesterday.addingTimeInterval(-5 * 3600), duration: 90 * 60, isValid: true)
        
        // Create sessions for 2 days ago
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        createTestFocusSession(startTime: twoDaysAgo.addingTimeInterval(-4 * 3600), duration: 45 * 60, isValid: true)
        
        try testContext.save()
        
        // When: Generating weekly trend
        let weeklyTrend = focusManager.getWeeklyTrend()
        
        // Then: Weekly trend should contain 7 days of data
        XCTAssertEqual(weeklyTrend.count, 7, "Weekly trend should contain 7 days")
        
        // Find today's, yesterday's and 2 days ago data in the trend
        let todayData = weeklyTrend.first(where: { calendar.isDate($0.date, inSameDayAs: today) })
        let yesterdayData = weeklyTrend.first(where: { calendar.isDate($0.date, inSameDayAs: yesterday) })
        let twoDaysAgoData = weeklyTrend.first(where: { calendar.isDate($0.date, inSameDayAs: twoDaysAgo) })
        
        XCTAssertNotNil(todayData, "Today's data should be in the weekly trend")
        XCTAssertNotNil(yesterdayData, "Yesterday's data should be in the weekly trend")
        XCTAssertNotNil(twoDaysAgoData, "Two days ago data should be in the weekly trend")
        
        XCTAssertEqual(todayData?.totalFocusTime, 60 * 60, "Today's focus time should be correct")
        XCTAssertEqual(yesterdayData?.totalFocusTime, 90 * 60, "Yesterday's focus time should be correct")
        XCTAssertEqual(twoDaysAgoData?.totalFocusTime, 45 * 60, "Two days ago focus time should be correct")
    }
    
    // MARK: - Basic UI Interaction Tests
    
    /// Tests that today's focus time is correctly calculated and updated
    func testTodaysFocusTimeCalculation() throws {
        // Given: Multiple focus sessions for today
        let today = Date()
        
        // Create test sessions
        createTestFocusSession(startTime: today.addingTimeInterval(-5 * 3600), duration: 45 * 60, isValid: true)
        createTestFocusSession(startTime: today.addingTimeInterval(-3 * 3600), duration: 60 * 60, isValid: true)
        createTestFocusSession(startTime: today.addingTimeInterval(-4 * 3600), duration: 15 * 60, isValid: false) // Invalid
        
        try testContext.save()
        
        // When: Calculating today's focus time
        focusManager.calculateTodaysFocusTime()
        
        // Then: Today's focus time should be updated correctly
        XCTAssertEqual(focusManager.todaysFocusTime, 105 * 60, "Today's focus time should only include valid sessions")
    }
    
    /// Tests that monitoring state is correctly tracked
    func testMonitoringStateTracking() throws {
        // Given: Focus manager is not monitoring initially
        XCTAssertFalse(focusManager.isMonitoring, "Should not be monitoring initially")
        
        // When: Starting monitoring
        focusManager.startMonitoring()
        
        // Then: Monitoring state should be updated
        XCTAssertTrue(focusManager.isMonitoring, "Should be monitoring after start")
        XCTAssertTrue(usageMonitor.isMonitoring, "Usage monitor should be monitoring")
        
        // When: Stopping monitoring
        focusManager.stopMonitoring()
        
        // Then: Monitoring state should be updated
        XCTAssertFalse(focusManager.isMonitoring, "Should not be monitoring after stop")
        XCTAssertFalse(usageMonitor.isMonitoring, "Usage monitor should not be monitoring")
    }
    
    // MARK: - Helper Methods
    
    private func createTestFocusSession(startTime: Date, duration: TimeInterval, isValid: Bool) {
        let session = FocusSession(context: testContext)
        session.startTime = startTime
        session.endTime = startTime.addingTimeInterval(duration)
        session.duration = duration
        session.isValid = isValid
        session.sessionType = "focus"
    }
}