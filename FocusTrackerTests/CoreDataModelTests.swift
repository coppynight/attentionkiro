import XCTest
import CoreData
@testable import FocusTracker

class CoreDataModelTests: XCTestCase {
    
    var testContext: NSManagedObjectContext!
    
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
    }
    
    override func tearDownWithError() throws {
        testContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - FocusSession Tests
    
    func testFocusSession_Creation() throws {
        // Given: A new focus session
        let session = FocusSession(context: testContext)
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(45 * 60) // 45 minutes
        
        // When: Setting properties
        session.startTime = startTime
        session.endTime = endTime
        session.duration = endTime.timeIntervalSince(startTime)
        session.isValid = true
        session.sessionType = "focus"
        
        // Then: Properties should be set correctly
        XCTAssertEqual(session.startTime, startTime, "Start time should be set")
        XCTAssertEqual(session.endTime, endTime, "End time should be set")
        XCTAssertEqual(session.duration, 45 * 60, "Duration should be 45 minutes")
        XCTAssertTrue(session.isValid, "Session should be valid")
        XCTAssertEqual(session.sessionType, "focus", "Session type should be focus")
    }
    
    func testFocusSession_FormattedDuration() throws {
        // Given: Focus sessions with different durations
        let session1 = FocusSession(context: testContext)
        session1.duration = 45 * 60 // 45 minutes
        
        let session2 = FocusSession(context: testContext)
        session2.duration = 90 * 60 // 1 hour 30 minutes
        
        let session3 = FocusSession(context: testContext)
        session3.duration = 30 * 60 // 30 minutes
        
        // Then: Formatted duration should be correct
        XCTAssertEqual(session1.formattedDuration, "45m", "45 minutes should format as '45m'")
        XCTAssertEqual(session2.formattedDuration, "1h 30m", "90 minutes should format as '1h 30m'")
        XCTAssertEqual(session3.formattedDuration, "30m", "30 minutes should format as '30m'")
    }
    
    func testFocusSession_IsActive() throws {
        // Given: An active session (no end time)
        let activeSession = FocusSession(context: testContext)
        activeSession.startTime = Date()
        activeSession.endTime = nil
        
        // Given: A completed session (with end time)
        let completedSession = FocusSession(context: testContext)
        completedSession.startTime = Date()
        completedSession.endTime = Date()
        
        // Then: Active status should be correct
        XCTAssertTrue(activeSession.isActive, "Session without end time should be active")
        XCTAssertFalse(completedSession.isActive, "Session with end time should not be active")
    }
    
    func testFocusSession_CurrentDuration() throws {
        // Given: An active session started 30 minutes ago
        let activeSession = FocusSession(context: testContext)
        activeSession.startTime = Date().addingTimeInterval(-30 * 60)
        activeSession.endTime = nil
        
        // Given: A completed session with 45 minutes duration
        let completedSession = FocusSession(context: testContext)
        let startTime = Date().addingTimeInterval(-60 * 60)
        completedSession.startTime = startTime
        completedSession.endTime = startTime.addingTimeInterval(45 * 60)
        
        // Then: Current duration should be calculated correctly
        XCTAssertEqual(activeSession.currentDuration, 30 * 60, accuracy: 5.0, "Active session duration should be ~30 minutes")
        XCTAssertEqual(completedSession.currentDuration, 45 * 60, "Completed session duration should be 45 minutes")
    }
    
    func testFocusSession_EndSession() throws {
        // Given: An active session
        let session = FocusSession(context: testContext)
        session.startTime = Date().addingTimeInterval(-30 * 60)
        session.endTime = nil
        session.duration = 0
        
        XCTAssertTrue(session.isActive, "Session should be active initially")
        
        // When: Ending the session
        session.endSession()
        
        // Then: Session should be completed with correct duration
        XCTAssertFalse(session.isActive, "Session should not be active after ending")
        XCTAssertNotNil(session.endTime, "End time should be set")
        XCTAssertEqual(session.duration, 30 * 60, accuracy: 5.0, "Duration should be ~30 minutes")
    }
    
    func testFocusSession_EndSession_AlreadyEnded() throws {
        // Given: An already completed session
        let session = FocusSession(context: testContext)
        let startTime = Date().addingTimeInterval(-30 * 60)
        let endTime = Date()
        
        session.startTime = startTime
        session.endTime = endTime
        session.duration = endTime.timeIntervalSince(startTime)
        
        let originalEndTime = session.endTime
        let originalDuration = session.duration
        
        // When: Trying to end the session again
        session.endSession()
        
        // Then: Session should remain unchanged
        XCTAssertEqual(session.endTime, originalEndTime, "End time should not change")
        XCTAssertEqual(session.duration, originalDuration, "Duration should not change")
    }
    
    func testFocusSession_ValidateSession() throws {
        // Given: Sessions with different durations
        let validSession = FocusSession(context: testContext)
        validSession.duration = 45 * 60 // 45 minutes
        
        let invalidSession = FocusSession(context: testContext)
        invalidSession.duration = 20 * 60 // 20 minutes
        
        // Then: Validation should be correct
        XCTAssertTrue(validSession.validateSession(), "45-minute session should be valid")
        XCTAssertFalse(invalidSession.validateSession(), "20-minute session should be invalid")
    }
    
    // MARK: - UserSettings Tests
    
    func testUserSettings_Creation() throws {
        // Given: New user settings
        let settings = UserSettings(context: testContext)
        
        // When: Setting properties
        settings.dailyFocusGoal = 2 * 3600 // 2 hours
        settings.notificationsEnabled = true
        settings.lunchBreakEnabled = false
        
        // Then: Properties should be set correctly
        XCTAssertEqual(settings.dailyFocusGoal, 2 * 3600, "Daily goal should be 2 hours")
        XCTAssertTrue(settings.notificationsEnabled, "Notifications should be enabled")
        XCTAssertFalse(settings.lunchBreakEnabled, "Lunch break should be disabled")
    }
    
    func testUserSettings_FormattedDailyGoal() throws {
        // Given: Settings with different daily goals
        let settings1 = UserSettings(context: testContext)
        settings1.dailyFocusGoal = 2 * 3600 // 2 hours
        
        let settings2 = UserSettings(context: testContext)
        settings2.dailyFocusGoal = 90 * 60 // 1 hour 30 minutes
        
        let settings3 = UserSettings(context: testContext)
        settings3.dailyFocusGoal = 45 * 60 // 45 minutes
        
        // Then: Formatted goal should be correct
        XCTAssertEqual(settings1.formattedDailyGoal, "2h 0m", "2 hours should format as '2h 0m'")
        XCTAssertEqual(settings2.formattedDailyGoal, "1h 30m", "90 minutes should format as '1h 30m'")
        XCTAssertEqual(settings3.formattedDailyGoal, "45m", "45 minutes should format as '45m'")
    }
    
    func testUserSettings_SleepDurationHours() throws {
        // Given: Settings with sleep time from 11 PM to 7 AM
        let settings = UserSettings(context: testContext)
        let calendar = Calendar.current
        
        settings.sleepStartTime = calendar.date(from: DateComponents(hour: 23, minute: 0))! // 11 PM
        settings.sleepEndTime = calendar.date(from: DateComponents(hour: 7, minute: 0))!   // 7 AM
        
        // Then: Sleep duration should be 8 hours
        XCTAssertEqual(settings.sleepDurationHours, 8.0, "Sleep duration should be 8 hours")
    }
    
    func testUserSettings_IsWithinSleepTime() throws {
        // Given: Settings with sleep time from 11 PM to 7 AM
        let settings = UserSettings(context: testContext)
        let calendar = Calendar.current
        
        settings.sleepStartTime = calendar.date(from: DateComponents(hour: 23, minute: 0))! // 11 PM
        settings.sleepEndTime = calendar.date(from: DateComponents(hour: 7, minute: 0))!   // 7 AM
        
        // Test times
        let midnightTime = calendar.date(from: DateComponents(hour: 0, minute: 30))!  // 12:30 AM
        let morningTime = calendar.date(from: DateComponents(hour: 6, minute: 30))!   // 6:30 AM
        let afternoonTime = calendar.date(from: DateComponents(hour: 14, minute: 0))! // 2:00 PM
        let eveningTime = calendar.date(from: DateComponents(hour: 23, minute: 30))!  // 11:30 PM
        
        // Then: Sleep time detection should be correct
        XCTAssertTrue(settings.isWithinSleepTime(midnightTime), "12:30 AM should be within sleep time")
        XCTAssertTrue(settings.isWithinSleepTime(morningTime), "6:30 AM should be within sleep time")
        XCTAssertFalse(settings.isWithinSleepTime(afternoonTime), "2:00 PM should not be within sleep time")
        XCTAssertTrue(settings.isWithinSleepTime(eveningTime), "11:30 PM should be within sleep time")
    }
    
    func testUserSettings_IsWithinLunchBreak() throws {
        // Given: Settings with lunch break from 12 PM to 2 PM
        let settings = UserSettings(context: testContext)
        let calendar = Calendar.current
        
        settings.lunchBreakEnabled = true
        settings.lunchBreakStart = calendar.date(from: DateComponents(hour: 12, minute: 0)) // 12 PM
        settings.lunchBreakEnd = calendar.date(from: DateComponents(hour: 14, minute: 0))   // 2 PM
        
        // Test times
        let beforeLunch = calendar.date(from: DateComponents(hour: 11, minute: 30))! // 11:30 AM
        let duringLunch = calendar.date(from: DateComponents(hour: 13, minute: 0))!  // 1:00 PM
        let afterLunch = calendar.date(from: DateComponents(hour: 15, minute: 0))!   // 3:00 PM
        
        // Then: Lunch break detection should be correct
        XCTAssertFalse(settings.isWithinLunchBreak(beforeLunch), "11:30 AM should not be within lunch break")
        XCTAssertTrue(settings.isWithinLunchBreak(duringLunch), "1:00 PM should be within lunch break")
        XCTAssertFalse(settings.isWithinLunchBreak(afterLunch), "3:00 PM should not be within lunch break")
    }
    
    func testUserSettings_IsWithinLunchBreak_Disabled() throws {
        // Given: Settings with lunch break disabled
        let settings = UserSettings(context: testContext)
        let calendar = Calendar.current
        
        settings.lunchBreakEnabled = false
        settings.lunchBreakStart = calendar.date(from: DateComponents(hour: 12, minute: 0))
        settings.lunchBreakEnd = calendar.date(from: DateComponents(hour: 14, minute: 0))
        
        let duringLunch = calendar.date(from: DateComponents(hour: 13, minute: 0))! // 1:00 PM
        
        // Then: Should not be within lunch break when disabled
        XCTAssertFalse(settings.isWithinLunchBreak(duringLunch), "Should not be within lunch break when disabled")
    }
    
    func testUserSettings_CreateDefaultSettings() throws {
        // When: Creating default settings
        let defaultSettings = UserSettings.createDefaultSettings(in: testContext)
        
        // Then: Default values should be set correctly
        XCTAssertEqual(defaultSettings.dailyFocusGoal, 2 * 3600, "Default daily goal should be 2 hours")
        XCTAssertTrue(defaultSettings.notificationsEnabled, "Notifications should be enabled by default")
        XCTAssertFalse(defaultSettings.lunchBreakEnabled, "Lunch break should be disabled by default")
        XCTAssertNotNil(defaultSettings.sleepStartTime, "Sleep start time should be set")
        XCTAssertNotNil(defaultSettings.sleepEndTime, "Sleep end time should be set")
    }
    
    // MARK: - Core Data Persistence Tests
    
    func testFocusSession_Persistence() throws {
        // Given: A focus session
        let session = FocusSession(context: testContext)
        session.startTime = Date()
        session.endTime = Date().addingTimeInterval(45 * 60)
        session.duration = 45 * 60
        session.isValid = true
        session.sessionType = "focus"
        
        // When: Saving to Core Data
        try testContext.save()
        
        // Then: Session should be persisted
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        let sessions = try testContext.fetch(request)
        
        XCTAssertEqual(sessions.count, 1, "Should have one persisted session")
        XCTAssertEqual(sessions.first?.duration, 45 * 60, "Duration should be persisted correctly")
        XCTAssertTrue(sessions.first?.isValid ?? false, "Valid flag should be persisted correctly")
    }
    
    func testUserSettings_Persistence() throws {
        // Given: User settings
        let settings = UserSettings.createDefaultSettings(in: testContext)
        settings.dailyFocusGoal = 3 * 3600 // 3 hours
        
        // When: Saving to Core Data
        try testContext.save()
        
        // Then: Settings should be persisted
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let allSettings = try testContext.fetch(request)
        
        XCTAssertEqual(allSettings.count, 1, "Should have one persisted settings object")
        XCTAssertEqual(allSettings.first?.dailyFocusGoal, 3 * 3600, "Daily goal should be persisted correctly")
    }
}