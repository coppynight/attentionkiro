import XCTest
import CoreData
@testable import FocusTracker

/// Tests to ensure data migration and backward compatibility work correctly
class DataMigrationTests: XCTestCase {
    
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
    
    // MARK: - Core Data Model Compatibility Tests
    
    func testExistingFocusSessionsRemainValid() throws {
        // Simulate existing focus sessions from v1.0
        let existingSession1 = FocusSession(context: testContext)
        existingSession1.startTime = Date().addingTimeInterval(-7200) // 2 hours ago
        existingSession1.endTime = Date().addingTimeInterval(-5400) // 1.5 hours ago
        existingSession1.duration = 1800 // 30 minutes
        existingSession1.isValid = true
        existingSession1.sessionType = "focus"
        
        let existingSession2 = FocusSession(context: testContext)
        existingSession2.startTime = Date().addingTimeInterval(-3600) // 1 hour ago
        existingSession2.endTime = Date() // Now
        existingSession2.duration = 3600 // 60 minutes
        existingSession2.isValid = true
        existingSession2.sessionType = "focus"
        
        try testContext.save()
        
        // Verify existing sessions are still accessible and valid
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        let sessions = try testContext.fetch(request)
        
        XCTAssertEqual(sessions.count, 2, "Should have 2 existing focus sessions")
        
        for session in sessions {
            XCTAssertNotNil(session.startTime, "Start time should be preserved")
            XCTAssertNotNil(session.endTime, "End time should be preserved")
            XCTAssertGreaterThan(session.duration, 0, "Duration should be preserved")
            XCTAssertTrue(session.isValid, "Validity should be preserved")
            XCTAssertEqual(session.sessionType, "focus", "Session type should be preserved")
            
            // Test computed properties still work
            XCTAssertFalse(session.isActive, "Completed sessions should not be active")
            XCTAssertNotNil(session.formattedDuration, "Formatted duration should work")
            XCTAssertTrue(session.validateSession(), "Validation should still work")
        }
    }
    
    func testExistingUserSettingsRemainValid() throws {
        // Simulate existing user settings from v1.0
        let existingSettings = UserSettings(context: testContext)
        existingSettings.dailyFocusGoal = 7200 // 2 hours
        existingSettings.notificationsEnabled = true
        existingSettings.lunchBreakEnabled = false
        
        // Set sleep times
        let calendar = Calendar.current
        existingSettings.sleepStartTime = calendar.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
        existingSettings.sleepEndTime = calendar.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        
        try testContext.save()
        
        // Verify existing settings are still accessible and valid
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let settings = try testContext.fetch(request)
        
        XCTAssertEqual(settings.count, 1, "Should have 1 existing settings object")
        
        let userSettings = settings.first!
        XCTAssertEqual(userSettings.dailyFocusGoal, 7200, "Daily goal should be preserved")
        XCTAssertTrue(userSettings.notificationsEnabled, "Notifications setting should be preserved")
        XCTAssertFalse(userSettings.lunchBreakEnabled, "Lunch break setting should be preserved")
        XCTAssertNotNil(userSettings.sleepStartTime, "Sleep start time should be preserved")
        XCTAssertNotNil(userSettings.sleepEndTime, "Sleep end time should be preserved")
        
        // Test computed properties still work
        XCTAssertEqual(userSettings.formattedDailyGoal, "2h 0m", "Formatted goal should work")
        XCTAssertEqual(userSettings.sleepDurationHours, 8.0, "Sleep duration calculation should work")
        
        // Test methods still work
        let testTime = calendar.date(from: DateComponents(hour: 1, minute: 0))!
        XCTAssertTrue(userSettings.isWithinSleepTime(testTime), "Sleep time check should work")
    }
    
    func testNewEntitiesCanBeCreatedAlongsideExisting() throws {
        // Create existing data
        let existingFocusSession = FocusSession(context: testContext)
        existingFocusSession.startTime = Date().addingTimeInterval(-3600)
        existingFocusSession.endTime = Date()
        existingFocusSession.duration = 3600
        existingFocusSession.isValid = true
        existingFocusSession.sessionType = "focus"
        
        let existingSettings = UserSettings.createDefaultSettings(in: testContext)
        existingSettings.dailyFocusGoal = 7200
        
        try testContext.save()
        
        // Create new entities
        let newAppSession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            categoryIdentifier: "productivity",
            in: testContext
        )
        newAppSession.duration = 1800
        newAppSession.endTime = newAppSession.startTime.addingTimeInterval(newAppSession.duration)
        newAppSession.updateProductivityStatus()
        
        let newTag = SceneTag.createTag(
            name: "工作",
            color: "#007AFF",
            isDefault: true,
            in: testContext
        )
        
        try testContext.save()
        
        // Verify all entities coexist
        let focusRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        let focusSessions = try testContext.fetch(focusRequest)
        XCTAssertEqual(focusSessions.count, 1, "Should have existing focus session")
        
        let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let settings = try testContext.fetch(settingsRequest)
        XCTAssertEqual(settings.count, 1, "Should have existing settings")
        
        let appRequest: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        let appSessions = try testContext.fetch(appRequest)
        XCTAssertEqual(appSessions.count, 1, "Should have new app session")
        
        let tagRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        let tags = try testContext.fetch(tagRequest)
        XCTAssertEqual(tags.count, 1, "Should have new tag")
        
        // Verify relationships work
        newAppSession.sceneTag = newTag.name
        try testContext.save()
        
        XCTAssertEqual(newAppSession.sceneTag, "工作", "Tag relationship should work")
    }
    
    // MARK: - Manager Compatibility Tests
    
    func testFocusManagerWorksWithExistingData() throws {
        // Create existing focus sessions
        let session1 = FocusSession(context: testContext)
        session1.startTime = Date().addingTimeInterval(-7200)
        session1.endTime = Date().addingTimeInterval(-5400)
        session1.duration = 1800
        session1.isValid = true
        session1.sessionType = "focus"
        
        let session2 = FocusSession(context: testContext)
        session2.startTime = Date().addingTimeInterval(-3600)
        session2.endTime = Date()
        session2.duration = 3600
        session2.isValid = true
        session2.sessionType = "focus"
        
        try testContext.save()
        
        // Initialize FocusManager with existing data
        let focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        
        // Verify it works with existing data
        let stats = focusManager.getFocusStatistics(for: Date())
        XCTAssertEqual(stats.totalFocusTime, 5400, "Should calculate total from existing sessions")
        XCTAssertEqual(stats.sessionCount, 2, "Should count existing sessions")
        XCTAssertEqual(stats.sessionCount, 2, "Should count valid existing sessions")
        
        let weeklyTrend = focusManager.getWeeklyTrend()
        XCTAssertEqual(weeklyTrend.count, 7, "Weekly trend should work with existing data")
        
        let todayData = weeklyTrend.last!
        XCTAssertEqual(todayData.totalFocusTime, 5400, "Today's data should include existing sessions")
    }
    
    func testTagManagerInitializesWithoutBreakingExistingData() throws {
        // Create existing data
        let existingFocusSession = FocusSession(context: testContext)
        existingFocusSession.startTime = Date().addingTimeInterval(-3600)
        existingFocusSession.endTime = Date()
        existingFocusSession.duration = 3600
        existingFocusSession.isValid = true
        existingFocusSession.sessionType = "focus"
        
        let existingSettings = UserSettings.createDefaultSettings(in: testContext)
        existingSettings.dailyFocusGoal = 7200
        
        try testContext.save()
        
        // Initialize TagManager
        let tagManager = TagManager(viewContext: testContext)
        
        // Verify it initializes correctly
        XCTAssertTrue(tagManager.isInitialized, "TagManager should initialize")
        XCTAssertEqual(tagManager.getDefaultTags().count, 7, "Should create default tags")
        XCTAssertEqual(tagManager.customTags.count, 0, "Should have no custom tags initially")
        
        // Verify existing data is unaffected
        let focusRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        let focusSessions = try testContext.fetch(focusRequest)
        XCTAssertEqual(focusSessions.count, 1, "Existing focus session should remain")
        XCTAssertEqual(focusSessions.first?.duration, 3600, "Existing session data should be unchanged")
        
        let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let settings = try testContext.fetch(settingsRequest)
        XCTAssertEqual(settings.count, 1, "Existing settings should remain")
        XCTAssertEqual(settings.first?.dailyFocusGoal, 7200, "Existing settings data should be unchanged")
    }
    
    func testTimeAnalysisManagerWorksWithMixedData() throws {
        // Create existing focus data
        let focusSession = FocusSession(context: testContext)
        focusSession.startTime = Date().addingTimeInterval(-3600)
        focusSession.endTime = Date()
        focusSession.duration = 3600
        focusSession.isValid = true
        focusSession.sessionType = "focus"
        
        try testContext.save()
        
        // Initialize managers
        let focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        let tagManager = TagManager(viewContext: testContext)
        let timeAnalysisManager = TimeAnalysisManager(
            viewContext: testContext,
            focusManager: focusManager,
            tagManager: tagManager
        )
        
        // Add new app usage data
        let appSession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        appSession.duration = 1800
        appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
        appSession.isProductiveTime = true
        
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        tagManager.updateTagForSession(appSession, tag: workTag)
        
        try testContext.save()
        
        // Verify TimeAnalysisManager works with mixed data
        let usageStats = timeAnalysisManager.getUsageStatistics(for: Date())
        XCTAssertEqual(usageStats.totalUsageTime, 1800, "Should calculate usage from new data")
        XCTAssertEqual(usageStats.productiveTime, 1800, "Should calculate productivity correctly")
        
        let combined = timeAnalysisManager.getCombinedStatistics(for: Date())
        XCTAssertEqual(combined.focus.totalFocusTime, 3600, "Should include existing focus data")
        XCTAssertEqual(combined.usage.totalUsageTime, 1800, "Should include new usage data")
        
        let tagDistribution = timeAnalysisManager.getSceneTagDistribution(for: Date())
        XCTAssertEqual(tagDistribution.count, 1, "Should have tag distribution from new data")
        XCTAssertEqual(tagDistribution.first?.tagName, "工作", "Should show correct tag")
    }
    
    // MARK: - Data Integrity Tests
    
    func testDataIntegrityAfterMigration() throws {
        // Create a comprehensive dataset simulating v1.0 data
        let calendar = Calendar.current
        let today = Date()
        
        // Create focus sessions for the past week
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            
            let session = FocusSession(context: testContext)
            session.startTime = date
            session.endTime = date.addingTimeInterval(TimeInterval((i + 1) * 1800))
            session.duration = TimeInterval((i + 1) * 1800)
            session.isValid = session.duration >= 1800
            session.sessionType = "focus"
        }
        
        // Create user settings
        let settings = UserSettings.createDefaultSettings(in: testContext)
        settings.dailyFocusGoal = 7200
        settings.notificationsEnabled = true
        settings.lunchBreakEnabled = false
        
        try testContext.save()
        
        // Initialize new features (simulating app upgrade)
        let focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        let tagManager = TagManager(viewContext: testContext)
        let timeAnalysisManager = TimeAnalysisManager(
            viewContext: testContext,
            focusManager: focusManager,
            tagManager: tagManager
        )
        
        // Add new data
        let appSession = AppUsageSession.createSession(
            appIdentifier: "com.microsoft.Office.Word",
            appName: "Microsoft Word",
            categoryIdentifier: "productivity",
            in: testContext
        )
        appSession.duration = 2700
        appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
        appSession.updateProductivityStatus()
        
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        tagManager.updateTagForSession(appSession, tag: workTag)
        
        try testContext.save()
        
        // Verify data integrity
        
        // Check focus data integrity
        let focusRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        let focusSessions = try testContext.fetch(focusRequest)
        XCTAssertEqual(focusSessions.count, 7, "Should have all original focus sessions")
        
        let totalFocusTime = focusSessions.reduce(0) { $0 + $1.duration }
        let focusStats = focusManager.getFocusStatistics(for: today)
        XCTAssertEqual(focusStats.totalFocusTime, totalFocusTime, "Focus stats should match raw data")
        
        // Check settings integrity
        let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let allSettings = try testContext.fetch(settingsRequest)
        XCTAssertEqual(allSettings.count, 1, "Should have one settings object")
        XCTAssertEqual(allSettings.first?.dailyFocusGoal, 7200, "Settings should be preserved")
        
        // Check new data integrity
        let appRequest: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        let appSessions = try testContext.fetch(appRequest)
        XCTAssertEqual(appSessions.count, 1, "Should have new app session")
        XCTAssertEqual(appSessions.first?.sceneTag, "工作", "Tag should be applied correctly")
        
        let tagRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        let tags = try testContext.fetch(tagRequest)
        XCTAssertEqual(tags.count, 7, "Should have default tags")
        
        // Check combined functionality
        let combined = timeAnalysisManager.getCombinedStatistics(for: today)
        XCTAssertGreaterThan(combined.focus.totalFocusTime, 0, "Should have focus data")
        XCTAssertGreaterThan(combined.usage.totalUsageTime, 0, "Should have usage data")
    }
    
    func testNoDataLossAfterMigration() throws {
        // Create comprehensive v1.0 dataset
        _ = createOriginalDataset()
        try testContext.save()
        
        // Count original data
        let originalFocusCount = try testContext.count(for: FocusSession.fetchRequest())
        let originalSettingsCount = try testContext.count(for: UserSettings.fetchRequest())
        
        // Initialize new features
        let focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        let tagManager = TagManager(viewContext: testContext)
        let timeAnalysisManager = TimeAnalysisManager(
            viewContext: testContext,
            focusManager: focusManager,
            tagManager: tagManager
        )
        
        // Add some new data
        let newAppSession = AppUsageSession.createSession(
            appIdentifier: "com.test.newapp",
            appName: "New App",
            in: testContext
        )
        newAppSession.duration = 1200
        
        let newTag = SceneTag.createTag(name: "新标签", color: "#FF0000", in: testContext)
        
        try testContext.save()
        
        // Verify no data loss
        let finalFocusCount = try testContext.count(for: FocusSession.fetchRequest())
        let finalSettingsCount = try testContext.count(for: UserSettings.fetchRequest())
        let finalAppCount = try testContext.count(for: AppUsageSession.fetchRequest())
        let finalTagCount = try testContext.count(for: SceneTag.fetchRequest())
        
        XCTAssertEqual(finalFocusCount, originalFocusCount, "No focus sessions should be lost")
        XCTAssertEqual(finalSettingsCount, originalSettingsCount, "No settings should be lost")
        XCTAssertEqual(finalAppCount, 1, "New app session should be added")
        XCTAssertEqual(finalTagCount, 8, "Should have 7 default + 1 custom tag")
        
        // Verify original data is still accessible and functional
        let focusStats = focusManager.getFocusStatistics(for: Date())
        XCTAssertGreaterThan(focusStats.totalFocusTime, 0, "Original focus data should be accessible")
        
        let usageStats = timeAnalysisManager.getUsageStatistics(for: Date())
        XCTAssertGreaterThan(usageStats.totalUsageTime, 0, "New usage data should be accessible")
    }
    
    // MARK: - Helper Methods
    
    private func createOriginalDataset() -> (focusSessions: [FocusSession], settings: UserSettings) {
        let calendar = Calendar.current
        let today = Date()
        var focusSessions: [FocusSession] = []
        
        // Create focus sessions for the past month
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            
            let session = FocusSession(context: testContext)
            session.startTime = date
            session.endTime = date.addingTimeInterval(TimeInterval((i % 5 + 1) * 1800))
            session.duration = TimeInterval((i % 5 + 1) * 1800)
            session.isValid = session.duration >= 1800
            session.sessionType = "focus"
            
            focusSessions.append(session)
        }
        
        // Create user settings
        let settings = UserSettings.createDefaultSettings(in: testContext)
        settings.dailyFocusGoal = 7200
        settings.notificationsEnabled = true
        settings.lunchBreakEnabled = false
        
        // Set sleep times
        settings.sleepStartTime = calendar.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
        settings.sleepEndTime = calendar.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        
        // Set lunch break times
        settings.lunchBreakStart = calendar.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
        settings.lunchBreakEnd = calendar.date(from: DateComponents(hour: 13, minute: 0)) ?? Date()
        
        return (focusSessions: focusSessions, settings: settings)
    }
    
    // MARK: - Performance Tests
    
    func testMigrationPerformance() throws {
        // Create large dataset to test migration performance
        let calendar = Calendar.current
        let today = Date()
        
        // Create 1000 focus sessions
        for i in 0..<1000 {
            let date = calendar.date(byAdding: .minute, value: -i * 60, to: today)!
            
            let session = FocusSession(context: testContext)
            session.startTime = date
            session.endTime = date.addingTimeInterval(TimeInterval((i % 10 + 1) * 300))
            session.duration = TimeInterval((i % 10 + 1) * 300)
            session.isValid = session.duration >= 1800
            session.sessionType = "focus"
        }
        
        try testContext.save()
        
        // Measure initialization time with large dataset
        measure {
            let focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
            let tagManager = TagManager(viewContext: testContext)
            let timeAnalysisManager = TimeAnalysisManager(
                viewContext: testContext,
                focusManager: focusManager,
                tagManager: tagManager
            )
            
            // Perform some operations to ensure everything is working
            _ = focusManager.getFocusStatistics(for: today)
            _ = tagManager.getDefaultTags()
            _ = timeAnalysisManager.getUsageStatistics(for: today)
        }
    }
}