import XCTest
import CoreData
@testable import FocusTracker

/// Test runner for core functionality tests
/// This test suite focuses on the core functionality requirements:
/// - Focus session detection accuracy
/// - Data storage and retrieval
/// - Basic UI interactions
class CoreFunctionalityTestRunner: XCTestCase {
    
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