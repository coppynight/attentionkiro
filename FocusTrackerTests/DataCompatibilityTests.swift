import XCTest
import CoreData
@testable import FocusTracker

class DataCompatibilityTests: XCTestCase {
    
    var testContext: NSManagedObjectContext!
    var focusManager: FocusManager!
    var tagManager: TagManager!
    var timeAnalysisManager: TimeAnalysisManager!
    
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
        
        // Create managers
        focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        tagManager = TagManager(viewContext: testContext)
        timeAnalysisManager = TimeAnalysisManager(
            viewContext: testContext,
            focusManager: focusManager,
            tagManager: tagManager
        )
    }
    
    override func tearDownWithError() throws {
        testContext = nil
        focusManager = nil
        tagManager = nil
        timeAnalysisManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Core Data Model Compatibility Tests
    
    func testExistingFocusSessionsUnaffected() throws {
        // Given: Existing focus sessions (simulating pre-extension data)
        let focusSession1 = FocusSession(context: testContext)
        focusSession1.startTime = Date().addingTimeInterval(-3600)
        focusSession1.endTime = Date().addingTimeInterval(-1800)
        focusSession1.duration = 1800 // 30 minutes
        focusSession1.isValid = true
        focusSession1.sessionType = "focus"
        
        let focusSession2 = FocusSession(context: testContext)
        focusSession2.startTime = Date().addingTimeInterval(-7200)
        focusSession2.endTime = Date().addingTimeInterval(-5400)
        focusSession2.duration = 1800 // 30 minutes
        focusSession2.isValid = true
        focusSession2.sessionType = "focus"
        
        try testContext.save()
        
        // When: Adding new app usage sessions
        let appSession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        appSession.duration = 1200 // 20 minutes
        appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
        
        try testContext.save()
        
        // Then: Existing focus sessions should remain unchanged
        let focusRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        let focusSessions = try testContext.fetch(focusRequest)
        
        XCTAssertEqual(focusSessions.count, 2, "Should have 2 focus sessions")
        
        for session in focusSessions {
            XCTAssertEqual(session.duration, 1800, "Focus session duration should be unchanged")
            XCTAssertTrue(session.isValid, "Focus session validity should be unchanged")
            XCTAssertEqual(session.sessionType, "focus", "Focus session type should be unchanged")
        }
        
        // And: New app usage session should exist
        let appRequest: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        let appSessions = try testContext.fetch(appRequest)
        
        XCTAssertEqual(appSessions.count, 1, "Should have 1 app usage session")
        XCTAssertEqual(appSessions.first?.duration, 1200, "App session duration should be correct")
    }
    
    func testExistingUserSettingsUnaffected() throws {
        // Given: Existing user settings (simulating pre-extension data)
        let settings = UserSettings.createDefaultSettings(in: testContext)
        settings.dailyFocusGoal = 7200 // 2 hours
        settings.notificationsEnabled = true
        settings.lunchBreakEnabled = false
        
        try testContext.save()
        
        // When: Adding new scene tags
        _ = SceneTag.createTag(name: "工作", color: "#007AFF", in: testContext)
        _ = SceneTag.createTag(name: "娱乐", color: "#FF9500", in: testContext)
        
        try testContext.save()
        
        // Then: Existing user settings should remain unchanged
        let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let allSettings = try testContext.fetch(settingsRequest)
        
        XCTAssertEqual(allSettings.count, 1, "Should have 1 user settings object")
        
        let retrievedSettings = allSettings.first!
        XCTAssertEqual(retrievedSettings.dailyFocusGoal, 7200, "Daily goal should be unchanged")
        XCTAssertTrue(retrievedSettings.notificationsEnabled, "Notifications setting should be unchanged")
        XCTAssertFalse(retrievedSettings.lunchBreakEnabled, "Lunch break setting should be unchanged")
        
        // And: New scene tags should exist
        let tagRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        let tags = try testContext.fetch(tagRequest)
        
        XCTAssertEqual(tags.count, 2, "Should have 2 scene tags")
    }
    
    // MARK: - Manager Integration Tests
    
    func testFocusManagerWithNewFeatures() throws {
        // Given: Focus manager with existing functionality
        let today = Date()
        
        // Create focus session using existing functionality
        let focusSession = FocusSession(context: testContext)
        focusSession.startTime = today.addingTimeInterval(-3600)
        focusSession.endTime = today
        focusSession.duration = 3600 // 1 hour
        focusSession.isValid = true
        focusSession.sessionType = "focus"
        
        // Create app usage session using new functionality
        let appSession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            startTime: today.addingTimeInterval(-1800),
            in: testContext
        )
        appSession.duration = 1800 // 30 minutes
        appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
        appSession.isProductiveTime = true
        
        try testContext.save()
        
        // When: Using focus manager functionality
        let focusStats = focusManager.getFocusStatistics(for: today)
        let weeklyTrend = focusManager.getWeeklyTrend()
        
        // Then: Focus manager should work correctly with both old and new data
        XCTAssertEqual(focusStats.totalFocusTime, 3600, "Focus time should be calculated correctly")
        XCTAssertEqual(focusStats.sessionCount, 1, "Focus session count should be correct")
        XCTAssertEqual(weeklyTrend.count, 7, "Weekly trend should have 7 days")
        
        // And: Time analysis manager should work with both data types
        let usageStats = timeAnalysisManager.getUsageStatistics(for: today)
        XCTAssertEqual(usageStats.totalUsageTime, 1800, "Usage time should be calculated correctly")
        XCTAssertEqual(usageStats.productiveTime, 1800, "Productive time should be calculated correctly")
    }
    
    func testTagManagerWithExistingData() throws {
        // Given: Existing focus sessions
        let focusSession = FocusSession(context: testContext)
        focusSession.startTime = Date().addingTimeInterval(-3600)
        focusSession.endTime = Date()
        focusSession.duration = 3600
        focusSession.isValid = true
        focusSession.sessionType = "focus"
        
        try testContext.save()
        
        // When: Using tag manager functionality
        let defaultTags = tagManager.getDefaultTags()
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        
        // Create app usage session and tag it
        let appSession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        appSession.duration = 1800
        appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
        
        tagManager.updateTagForSession(appSession, tag: workTag)
        
        try testContext.save()
        
        // Then: Tag manager should work correctly
        XCTAssertEqual(defaultTags.count, 7, "Should have 7 default tags")
        XCTAssertEqual(appSession.sceneTag, "工作", "App session should be tagged")
        XCTAssertTrue(workTag.isAppAssociated("com.test.app"), "Tag should be associated with app")
        
        // And: Existing focus session should be unaffected
        let focusRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        let focusSessions = try testContext.fetch(focusRequest)
        
        XCTAssertEqual(focusSessions.count, 1, "Should still have 1 focus session")
        XCTAssertEqual(focusSessions.first?.duration, 3600, "Focus session should be unchanged")
    }
    
    // MARK: - Data Migration Simulation Tests
    
    func testDataMigrationScenario() throws {
        // Simulate a scenario where user has existing data and upgrades to new version
        
        // Step 1: Create "old" data (focus sessions and user settings)
        let oldFocusSession1 = FocusSession(context: testContext)
        oldFocusSession1.startTime = Date().addingTimeInterval(-86400) // Yesterday
        oldFocusSession1.endTime = Date().addingTimeInterval(-84600)
        oldFocusSession1.duration = 1800
        oldFocusSession1.isValid = true
        oldFocusSession1.sessionType = "focus"
        
        let oldFocusSession2 = FocusSession(context: testContext)
        oldFocusSession2.startTime = Date().addingTimeInterval(-82800)
        oldFocusSession2.endTime = Date().addingTimeInterval(-81000)
        oldFocusSession2.duration = 1800
        oldFocusSession2.isValid = true
        oldFocusSession2.sessionType = "focus"
        
        let oldSettings = UserSettings.createDefaultSettings(in: testContext)
        oldSettings.dailyFocusGoal = 7200
        oldSettings.notificationsEnabled = true
        
        try testContext.save()
        
        // Step 2: Simulate app upgrade - initialize new features
        // This would happen when TagManager is first initialized
        XCTAssertEqual(tagManager.getDefaultTags().count, 7, "Default tags should be created")
        
        // Step 3: User starts using new features
        let newAppSession = AppUsageSession.createSession(
            appIdentifier: "com.microsoft.Office.Word",
            appName: "Microsoft Word",
            categoryIdentifier: "productivity",
            in: testContext
        )
        newAppSession.duration = 2700 // 45 minutes
        newAppSession.endTime = newAppSession.startTime.addingTimeInterval(newAppSession.duration)
        newAppSession.updateProductivityStatus()
        
        // Tag the session
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        tagManager.updateTagForSession(newAppSession, tag: workTag)
        
        try testContext.save()
        
        // Step 4: Verify all data coexists correctly
        
        // Old focus sessions should still work
        let focusStats = focusManager.getFocusStatistics(for: Date().addingTimeInterval(-86400))
        XCTAssertEqual(focusStats.totalFocusTime, 3600, "Old focus data should be accessible")
        XCTAssertEqual(focusStats.sessionCount, 2, "Should have 2 old focus sessions")
        
        // Old settings should still work
        let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let settings = try testContext.fetch(settingsRequest)
        XCTAssertEqual(settings.first?.dailyFocusGoal, 7200, "Old settings should be preserved")
        
        // New features should work
        let todayUsage = timeAnalysisManager.getUsageStatistics(for: Date())
        XCTAssertEqual(todayUsage.totalUsageTime, 2700, "New usage tracking should work")
        XCTAssertEqual(todayUsage.productiveTime, 2700, "Productivity tracking should work")
        
        let tagDistribution = timeAnalysisManager.getSceneTagDistribution(for: Date())
        XCTAssertEqual(tagDistribution.count, 1, "Tag distribution should work")
        XCTAssertEqual(tagDistribution.first?.tagName, "工作", "Should show work tag")
        
        // Combined functionality should work
        let combined = timeAnalysisManager.getCombinedStatistics(for: Date())
        XCTAssertEqual(combined.focus.totalFocusTime, 0, "Today should have no focus time")
        XCTAssertEqual(combined.usage.totalUsageTime, 2700, "Today should have usage time")
    }
    
    // MARK: - Performance with Mixed Data Tests
    
    func testPerformanceWithMixedData() throws {
        // Given: Large amount of mixed old and new data
        let calendar = Calendar.current
        let today = Date()
        
        // Create old focus sessions
        for i in 0..<100 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let focusSession = FocusSession(context: testContext)
            focusSession.startTime = date
            focusSession.endTime = date.addingTimeInterval(TimeInterval(i * 60 + 1800))
            focusSession.duration = TimeInterval(i * 60 + 1800)
            focusSession.isValid = focusSession.duration >= 1800
            focusSession.sessionType = "focus"
        }
        
        // Create new app usage sessions
        for i in 0..<100 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let appSession = AppUsageSession.createSession(
                appIdentifier: "com.test.app\(i % 10)",
                appName: "Test App \(i % 10)",
                startTime: date,
                in: testContext
            )
            appSession.duration = TimeInterval(i * 30 + 600)
            appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
            appSession.isProductiveTime = i % 2 == 0
            
            if i % 5 == 0 {
                let tag = tagManager.getDefaultTags().randomElement()!
                tagManager.updateTagForSession(appSession, tag: tag)
            }
        }
        
        try testContext.save()
        
        // When: Performing operations on mixed data
        measure {
            // Test focus manager performance
            _ = focusManager.getFocusStatistics(for: today)
            _ = focusManager.getWeeklyTrend()
            
            // Test time analysis manager performance
            _ = timeAnalysisManager.getUsageStatistics(for: today)
            _ = timeAnalysisManager.getWeeklyTrend()
            _ = timeAnalysisManager.getSceneTagDistribution(for: today)
            
            // Test combined operations
            _ = timeAnalysisManager.getCombinedStatistics(for: today)
        }
    }
    
    // MARK: - Error Handling with Mixed Data Tests
    
    func testErrorHandlingWithCorruptedData() throws {
        // Given: Mix of valid and potentially corrupted data
        
        // Valid focus session
        let validFocusSession = FocusSession(context: testContext)
        validFocusSession.startTime = Date().addingTimeInterval(-3600)
        validFocusSession.endTime = Date()
        validFocusSession.duration = 3600
        validFocusSession.isValid = true
        validFocusSession.sessionType = "focus"
        
        // "Corrupted" focus session (negative duration)
        let corruptedFocusSession = FocusSession(context: testContext)
        corruptedFocusSession.startTime = Date().addingTimeInterval(-1800)
        corruptedFocusSession.endTime = Date().addingTimeInterval(-3600) // End before start
        corruptedFocusSession.duration = -1800 // Negative duration
        corruptedFocusSession.isValid = false
        corruptedFocusSession.sessionType = "focus"
        
        // Valid app usage session
        let validAppSession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        validAppSession.duration = 1800
        validAppSession.endTime = validAppSession.startTime.addingTimeInterval(validAppSession.duration)
        
        // "Corrupted" app usage session (empty identifiers)
        let corruptedAppSession = AppUsageSession.createSession(
            appIdentifier: "",
            appName: "",
            in: testContext
        )
        corruptedAppSession.duration = -600 // Negative duration
        
        try testContext.save()
        
        // When: Managers process mixed valid/corrupted data
        // Then: Should handle gracefully without crashing
        
        let focusStats = focusManager.getFocusStatistics(for: Date())
        XCTAssertGreaterThanOrEqual(focusStats.totalFocusTime, 0, "Focus stats should handle corrupted data")
        
        let usageStats = timeAnalysisManager.getUsageStatistics(for: Date())
        // Note: This might include negative duration, but shouldn't crash
        XCTAssertNotNil(usageStats, "Usage stats should be calculated even with corrupted data")
        
        let weeklyTrend = timeAnalysisManager.getWeeklyTrend()
        XCTAssertEqual(weeklyTrend.count, 7, "Weekly trend should still return 7 days")
        
        let combined = timeAnalysisManager.getCombinedStatistics(for: Date())
        XCTAssertNotNil(combined.focus, "Combined stats should include focus data")
        XCTAssertNotNil(combined.usage, "Combined stats should include usage data")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentAccessToMixedData() throws {
        // Given: Mixed data
        let focusSession = FocusSession(context: testContext)
        focusSession.startTime = Date().addingTimeInterval(-3600)
        focusSession.endTime = Date()
        focusSession.duration = 3600
        focusSession.isValid = true
        focusSession.sessionType = "focus"
        
        let appSession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        appSession.duration = 1800
        appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
        
        try testContext.save()
        
        // When: Multiple managers access data concurrently
        let expectation1 = expectation(description: "Focus manager completes")
        let expectation2 = expectation(description: "Time analysis manager completes")
        let expectation3 = expectation(description: "Tag manager completes")
        
        DispatchQueue.global().async {
            _ = self.focusManager.getFocusStatistics(for: Date())
            _ = self.focusManager.getWeeklyTrend()
            expectation1.fulfill()
        }
        
        DispatchQueue.global().async {
            _ = self.timeAnalysisManager.getUsageStatistics(for: Date())
            _ = self.timeAnalysisManager.getWeeklyTrend()
            expectation2.fulfill()
        }
        
        DispatchQueue.global().async {
            _ = self.tagManager.getDefaultTags()
            _ = self.tagManager.getAllTags()
            expectation3.fulfill()
        }
        
        // Then: All operations should complete without issues
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error, "Concurrent access should not cause errors")
        }
    }
}