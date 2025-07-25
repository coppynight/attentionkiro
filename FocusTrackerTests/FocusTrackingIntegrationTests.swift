import XCTest
import CoreData
@testable import FocusTracker

class FocusTrackingIntegrationTests: XCTestCase {
    
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
        
        // Create managers in the same order as the app would
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
    
    // MARK: - Core Focus Tracking Functionality Tests
    
    func testCoreFocusTrackingUnaffected() throws {
        // Given: Core focus tracking functionality should work as before
        let today = Date()
        
        // When: Creating focus sessions using existing functionality
        let focusSession1 = FocusSession(context: testContext)
        focusSession1.startTime = today.addingTimeInterval(-3600)
        focusSession1.endTime = today.addingTimeInterval(-1800)
        focusSession1.duration = 1800 // 30 minutes
        focusSession1.isValid = true
        focusSession1.sessionType = "focus"
        
        let focusSession2 = FocusSession(context: testContext)
        focusSession2.startTime = today.addingTimeInterval(-1800)
        focusSession2.endTime = today
        focusSession2.duration = 1800 // 30 minutes
        focusSession2.isValid = true
        focusSession2.sessionType = "focus"
        
        try testContext.save()
        
        // Then: Focus manager should work exactly as before
        let focusStats = focusManager.getFocusStatistics(for: today)
        XCTAssertEqual(focusStats.totalFocusTime, 3600, "Total focus time should be 1 hour")
        XCTAssertEqual(focusStats.sessionCount, 2, "Should have 2 focus sessions")
        XCTAssertEqual(focusStats.averageSession, 1800, "Average session should be 30 minutes")
        XCTAssertEqual(focusStats.sessionCount, 2, "Should have 2 valid sessions")
        
        let weeklyTrend = focusManager.getWeeklyTrend()
        XCTAssertEqual(weeklyTrend.count, 7, "Weekly trend should have 7 days")
        
        let todayData = weeklyTrend.last!
        XCTAssertEqual(todayData.totalFocusTime, 3600, "Today's focus time should be 1 hour")
        XCTAssertEqual(todayData.sessionCount, 2, "Today should have 2 sessions")
    }
    
    func testFocusSessionValidationUnchanged() throws {
        // Given: Focus sessions with different durations
        let validSession = FocusSession(context: testContext)
        validSession.startTime = Date().addingTimeInterval(-2700)
        validSession.endTime = Date()
        validSession.duration = 2700 // 45 minutes
        validSession.sessionType = "focus"
        
        let invalidSession = FocusSession(context: testContext)
        invalidSession.startTime = Date().addingTimeInterval(-1200)
        invalidSession.endTime = Date()
        invalidSession.duration = 1200 // 20 minutes
        invalidSession.sessionType = "focus"
        
        // When: Validating sessions
        let validResult = validSession.validateSession()
        let invalidResult = invalidSession.validateSession()
        
        // Then: Validation should work as before
        XCTAssertTrue(validResult, "45-minute session should be valid")
        XCTAssertFalse(invalidResult, "20-minute session should be invalid")
        
        // Update validation status
        validSession.isValid = validResult
        invalidSession.isValid = invalidResult
        
        try testContext.save()
        
        // Verify focus statistics only count valid sessions
        let stats = focusManager.getFocusStatistics(for: Date())
        XCTAssertEqual(stats.totalFocusTime, 2700, "Only valid session time should be counted")
        XCTAssertEqual(stats.sessionCount, 1, "Should have 1 valid session")
        XCTAssertEqual(stats.sessionCount, 2, "Should have 2 total sessions")
    }
    
    func testUserSettingsIntegration() throws {
        // Given: User settings for focus tracking
        let settings = UserSettings.createDefaultSettings(in: testContext)
        settings.dailyFocusGoal = 7200 // 2 hours
        settings.notificationsEnabled = true
        settings.lunchBreakEnabled = true
        
        let calendar = Calendar.current
        settings.lunchBreakStart = calendar.date(from: DateComponents(hour: 12, minute: 0))
        settings.lunchBreakEnd = calendar.date(from: DateComponents(hour: 13, minute: 0))
        
        try testContext.save()
        
        // When: Creating focus sessions
        let focusSession = FocusSession(context: testContext)
        focusSession.startTime = Date().addingTimeInterval(-3600)
        focusSession.endTime = Date()
        focusSession.duration = 3600 // 1 hour
        focusSession.isValid = true
        focusSession.sessionType = "focus"
        
        try testContext.save()
        
        // Then: Settings should work with focus tracking
        let stats = focusManager.getFocusStatistics(for: Date())
        XCTAssertEqual(stats.totalFocusTime, 3600, "Focus time should be tracked")
        
        // Goal progress should be calculated
        let progress = stats.totalFocusTime / settings.dailyFocusGoal
        XCTAssertEqual(progress, 0.5, "Should be 50% of daily goal")
        
        // Settings should be accessible
        XCTAssertEqual(settings.dailyFocusGoal, 7200, "Daily goal should be preserved")
        XCTAssertTrue(settings.notificationsEnabled, "Notifications should be enabled")
        XCTAssertTrue(settings.lunchBreakEnabled, "Lunch break should be enabled")
    }
    
    // MARK: - New Features Integration Tests
    
    func testNewFeaturesDoNotBreakFocusTracking() throws {
        // Given: Existing focus session
        let focusSession = FocusSession(context: testContext)
        focusSession.startTime = Date().addingTimeInterval(-3600)
        focusSession.endTime = Date()
        focusSession.duration = 3600
        focusSession.isValid = true
        focusSession.sessionType = "focus"
        
        try testContext.save()
        
        // When: Using new features (tags and time analysis)
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        
        let appSession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        appSession.duration = 1800
        appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
        
        tagManager.updateTagForSession(appSession, tag: workTag)
        
        try testContext.save()
        
        // Then: Focus tracking should still work perfectly
        let focusStats = focusManager.getFocusStatistics(for: Date())
        XCTAssertEqual(focusStats.totalFocusTime, 3600, "Focus time should be unaffected")
        XCTAssertEqual(focusStats.sessionCount, 1, "Focus session count should be correct")
        
        // And: New features should work alongside
        let usageStats = timeAnalysisManager.getUsageStatistics(for: Date())
        XCTAssertEqual(usageStats.totalUsageTime, 1800, "Usage time should be tracked")
        
        let tagDistribution = timeAnalysisManager.getSceneTagDistribution(for: Date())
        XCTAssertEqual(tagDistribution.count, 1, "Should have 1 tag distribution")
        XCTAssertEqual(tagDistribution.first?.tagName, "工作", "Should be work tag")
        
        // Combined statistics should work
        let combined = timeAnalysisManager.getCombinedStatistics(for: Date())
        XCTAssertEqual(combined.focus.totalFocusTime, 3600, "Combined focus time should match")
        XCTAssertEqual(combined.usage.totalUsageTime, 1800, "Combined usage time should match")
    }
    
    func testFocusTrackingWithTaggedSessions() throws {
        // Given: Focus sessions and tagged app usage sessions
        let today = Date()
        
        // Focus session
        let focusSession = FocusSession(context: testContext)
        focusSession.startTime = today.addingTimeInterval(-3600)
        focusSession.endTime = today.addingTimeInterval(-1800)
        focusSession.duration = 1800
        focusSession.isValid = true
        focusSession.sessionType = "focus"
        
        // Tagged app usage sessions
        let workSession = AppUsageSession.createSession(
            appIdentifier: "com.microsoft.Office.Word",
            appName: "Microsoft Word",
            startTime: today.addingTimeInterval(-1800),
            in: testContext
        )
        workSession.duration = 1200
        workSession.endTime = workSession.startTime.addingTimeInterval(workSession.duration)
        workSession.isProductiveTime = true
        
        let entertainmentSession = AppUsageSession.createSession(
            appIdentifier: "com.netflix.Netflix",
            appName: "Netflix",
            startTime: today.addingTimeInterval(-600),
            in: testContext
        )
        entertainmentSession.duration = 600
        entertainmentSession.endTime = entertainmentSession.startTime.addingTimeInterval(entertainmentSession.duration)
        entertainmentSession.isProductiveTime = false
        
        // Tag the sessions
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        let entertainmentTag = tagManager.getDefaultTags().first { $0.name == "娱乐" }!
        
        tagManager.updateTagForSession(workSession, tag: workTag)
        tagManager.updateTagForSession(entertainmentSession, tag: entertainmentTag)
        
        try testContext.save()
        
        // When: Getting comprehensive statistics
        let focusStats = focusManager.getFocusStatistics(for: today)
        let usageStats = timeAnalysisManager.getUsageStatistics(for: today)
        let tagDistribution = timeAnalysisManager.getSceneTagDistribution(for: today)
        let combined = timeAnalysisManager.getCombinedStatistics(for: today)
        
        // Then: All systems should work together correctly
        
        // Focus tracking should be independent
        XCTAssertEqual(focusStats.totalFocusTime, 1800, "Focus time should be 30 minutes")
        XCTAssertEqual(focusStats.sessionCount, 1, "Should have 1 focus session")
        
        // Usage tracking should work
        XCTAssertEqual(usageStats.totalUsageTime, 1800, "Total usage should be 30 minutes")
        XCTAssertEqual(usageStats.productiveTime, 1200, "Productive time should be 20 minutes")
        XCTAssertEqual(usageStats.productivityRatio, 2.0/3.0, accuracy: 0.01, "Productivity ratio should be ~66.67%")
        
        // Tag distribution should work
        XCTAssertEqual(tagDistribution.count, 2, "Should have 2 tag distributions")
        let workDist = tagDistribution.first { $0.tagName == "工作" }
        let entertainmentDist = tagDistribution.first { $0.tagName == "娱乐" }
        
        XCTAssertNotNil(workDist, "Should have work distribution")
        XCTAssertNotNil(entertainmentDist, "Should have entertainment distribution")
        XCTAssertEqual(workDist?.totalTime, 1200, "Work time should be 20 minutes")
        XCTAssertEqual(entertainmentDist?.totalTime, 600, "Entertainment time should be 10 minutes")
        
        // Combined statistics should integrate both
        XCTAssertEqual(combined.focus.totalFocusTime, 1800, "Combined focus should match")
        XCTAssertEqual(combined.usage.totalUsageTime, 1800, "Combined usage should match")
    }
    
    // MARK: - Performance Integration Tests
    
    func testPerformanceWithAllFeatures() throws {
        // Given: Large dataset with all types of data
        let calendar = Calendar.current
        let today = Date()
        
        // Create focus sessions
        for i in 0..<50 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let focusSession = FocusSession(context: testContext)
            focusSession.startTime = date
            focusSession.endTime = date.addingTimeInterval(TimeInterval((i + 1) * 30 * 60))
            focusSession.duration = TimeInterval((i + 1) * 30 * 60)
            focusSession.isValid = focusSession.duration >= 1800
            focusSession.sessionType = "focus"
        }
        
        // Create app usage sessions with tags
        let tags = tagManager.getDefaultTags()
        for i in 0..<100 {
            let date = calendar.date(byAdding: .day, value: -(i % 30), to: today)!
            let appSession = AppUsageSession.createSession(
                appIdentifier: "com.test.app\(i % 10)",
                appName: "Test App \(i % 10)",
                startTime: date,
                in: testContext
            )
            appSession.duration = TimeInterval((i % 20 + 1) * 60)
            appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
            appSession.isProductiveTime = i % 3 == 0
            
            if i % 5 == 0 {
                let tag = tags[i % tags.count]
                tagManager.updateTagForSession(appSession, tag: tag)
            }
        }
        
        try testContext.save()
        
        // When: Performing comprehensive operations
        measure {
            // Focus tracking operations
            _ = focusManager.getFocusStatistics(for: today)
            _ = focusManager.getWeeklyTrend()
            
            // Time analysis operations
            _ = timeAnalysisManager.getUsageStatistics(for: today)
            _ = timeAnalysisManager.getWeeklyTrend()
            _ = timeAnalysisManager.getSceneTagDistribution(for: today)
            _ = timeAnalysisManager.getAppUsageBreakdown(for: today)
            
            // Combined operations
            _ = timeAnalysisManager.getCombinedStatistics(for: today)
            _ = timeAnalysisManager.getCombinedWeeklyTrend()
            
            // Tag operations
            _ = tagManager.getTagDistribution(for: today)
            _ = tagManager.getAllTags()
        }
    }
    
    // MARK: - Real-world Usage Scenario Tests
    
    func testTypicalUserWorkflow() throws {
        // Simulate a typical user's day with focus tracking and new features
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        // Morning focus session (9 AM - 10:30 AM)
        let morningFocus = FocusSession(context: testContext)
        morningFocus.startTime = startOfDay.addingTimeInterval(9 * 3600) // 9 AM
        morningFocus.endTime = startOfDay.addingTimeInterval(9.5 * 3600) // 9:30 AM
        morningFocus.duration = 1800 // 30 minutes
        morningFocus.isValid = false // Too short
        morningFocus.sessionType = "focus"
        
        // Extended morning focus session (10:30 AM - 12 PM)
        let extendedMorningFocus = FocusSession(context: testContext)
        extendedMorningFocus.startTime = startOfDay.addingTimeInterval(10.5 * 3600) // 10:30 AM
        extendedMorningFocus.endTime = startOfDay.addingTimeInterval(12 * 3600) // 12 PM
        extendedMorningFocus.duration = 5400 // 90 minutes
        extendedMorningFocus.isValid = true
        extendedMorningFocus.sessionType = "focus"
        
        // App usage during the day
        let workApps = [
            ("com.microsoft.Office.Word", "Microsoft Word", "productivity"),
            ("com.apple.mail", "Mail", "productivity"),
            ("com.slack.Slack", "Slack", "productivity")
        ]
        
        let entertainmentApps = [
            ("com.netflix.Netflix", "Netflix", "entertainment"),
            ("com.tencent.QQMusic", "QQ Music", "entertainment")
        ]
        
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        let entertainmentTag = tagManager.getDefaultTags().first { $0.name == "娱乐" }!
        
        // Work app usage (morning)
        for (i, (appId, appName, category)) in workApps.enumerated() {
            let session = AppUsageSession.createSession(
                appIdentifier: appId,
                appName: appName,
                categoryIdentifier: category,
                startTime: startOfDay.addingTimeInterval(Double(9 + i) * 3600),
                in: testContext
            )
            session.duration = TimeInterval((i + 1) * 20 * 60) // 20, 40, 60 minutes
            session.endTime = session.startTime.addingTimeInterval(session.duration)
            session.updateProductivityStatus()
            tagManager.updateTagForSession(session, tag: workTag)
        }
        
        // Entertainment app usage (evening)
        for (i, (appId, appName, category)) in entertainmentApps.enumerated() {
            let session = AppUsageSession.createSession(
                appIdentifier: appId,
                appName: appName,
                categoryIdentifier: category,
                startTime: startOfDay.addingTimeInterval(Double(19 + i) * 3600), // 7 PM, 8 PM
                in: testContext
            )
            session.duration = TimeInterval((i + 1) * 30 * 60) // 30, 60 minutes
            session.endTime = session.startTime.addingTimeInterval(session.duration)
            session.updateProductivityStatus()
            tagManager.updateTagForSession(session, tag: entertainmentTag)
        }
        
        // Afternoon focus session (2 PM - 3:30 PM)
        let afternoonFocus = FocusSession(context: testContext)
        afternoonFocus.startTime = startOfDay.addingTimeInterval(14 * 3600) // 2 PM
        afternoonFocus.endTime = startOfDay.addingTimeInterval(15.5 * 3600) // 3:30 PM
        afternoonFocus.duration = 5400 // 90 minutes
        afternoonFocus.isValid = true
        afternoonFocus.sessionType = "focus"
        
        try testContext.save()
        
        // When: Analyzing the day's data
        let focusStats = focusManager.getFocusStatistics(for: today)
        let usageStats = timeAnalysisManager.getUsageStatistics(for: today)
        let tagDistribution = timeAnalysisManager.getSceneTagDistribution(for: today)
        let appBreakdown = timeAnalysisManager.getAppUsageBreakdown(for: today)
        let hourlyDistribution = timeAnalysisManager.getHourlyDistribution(for: today)
        let combined = timeAnalysisManager.getCombinedStatistics(for: today)
        
        // Then: All systems should provide accurate insights
        
        // Focus tracking results
        XCTAssertEqual(focusStats.totalFocusTime, 10800, "Total focus time should be 3 hours")
        XCTAssertEqual(focusStats.sessionCount, 2, "Should have 2 valid focus sessions")
        XCTAssertEqual(focusStats.averageSession, 4200, "Average should be 70 minutes")
        
        // Usage tracking results
        XCTAssertEqual(usageStats.totalUsageTime, 300 * 60, "Total usage should be 5 hours")
        XCTAssertEqual(usageStats.appCount, 5, "Should have used 5 different apps")
        XCTAssertEqual(usageStats.productiveTime, 120 * 60, "Productive time should be 2 hours")
        XCTAssertEqual(usageStats.productivityRatio, 0.4, "Productivity ratio should be 40%")
        
        // Tag distribution results
        XCTAssertEqual(tagDistribution.count, 2, "Should have 2 tag categories")
        let workDist = tagDistribution.first { $0.tagName == "工作" }!
        let entertainmentDist = tagDistribution.first { $0.tagName == "娱乐" }!
        
        XCTAssertEqual(workDist.totalTime, 120 * 60, "Work time should be 2 hours")
        XCTAssertEqual(entertainmentDist.totalTime, 90 * 60, "Entertainment time should be 1.5 hours")
        
        // App breakdown results
        XCTAssertEqual(appBreakdown.count, 5, "Should have breakdown for 5 apps")
        let topApp = appBreakdown.first!
        XCTAssertEqual(topApp.appName, "Slack", "Slack should be most used (60 minutes)")
        XCTAssertEqual(topApp.totalTime, 60 * 60, "Top app should have 1 hour")
        
        // Hourly distribution should show activity patterns
        let morningHour = hourlyDistribution[9] // 9 AM
        let afternoonHour = hourlyDistribution[14] // 2 PM
        let eveningHour = hourlyDistribution[19] // 7 PM
        
        XCTAssertGreaterThan(morningHour.totalTime, 0, "Should have morning activity")
        XCTAssertGreaterThan(afternoonHour.totalTime, 0, "Should have afternoon activity")
        XCTAssertGreaterThan(eveningHour.totalTime, 0, "Should have evening activity")
        
        // Combined statistics should integrate everything
        XCTAssertEqual(combined.focus.totalFocusTime, 10800, "Combined focus should match")
        XCTAssertEqual(combined.usage.totalUsageTime, 300 * 60, "Combined usage should match")
    }
    
    // MARK: - Edge Case Integration Tests
    
    func testEdgeCasesWithAllFeatures() throws {
        // Test various edge cases that could occur in real usage
        
        // Edge case 1: Very short focus session with overlapping app usage
        let shortFocus = FocusSession(context: testContext)
        shortFocus.startTime = Date().addingTimeInterval(-600)
        shortFocus.endTime = Date().addingTimeInterval(-300)
        shortFocus.duration = 300 // 5 minutes
        shortFocus.isValid = false
        shortFocus.sessionType = "focus"
        
        let overlappingApp = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            startTime: Date().addingTimeInterval(-450), // Overlaps with focus session
            in: testContext
        )
        overlappingApp.duration = 600 // 10 minutes
        overlappingApp.endTime = overlappingApp.startTime.addingTimeInterval(overlappingApp.duration)
        
        // Edge case 2: App session with no tag
        let untaggedApp = AppUsageSession.createSession(
            appIdentifier: "com.unknown.app",
            appName: "Unknown App",
            in: testContext
        )
        untaggedApp.duration = 1800
        untaggedApp.endTime = untaggedApp.startTime.addingTimeInterval(untaggedApp.duration)
        untaggedApp.sceneTag = nil
        
        // Edge case 3: Very long focus session
        let longFocus = FocusSession(context: testContext)
        longFocus.startTime = Date().addingTimeInterval(-14400) // 4 hours ago
        longFocus.endTime = Date()
        longFocus.duration = 14400 // 4 hours
        longFocus.isValid = true
        longFocus.sessionType = "focus"
        
        try testContext.save()
        
        // When: Getting statistics
        let focusStats = focusManager.getFocusStatistics(for: Date())
        let usageStats = timeAnalysisManager.getUsageStatistics(for: Date())
        let tagDistribution = timeAnalysisManager.getSceneTagDistribution(for: Date())
        
        // Then: Should handle edge cases gracefully
        XCTAssertEqual(focusStats.totalFocusTime, 14400, "Should include long valid session")
        XCTAssertEqual(focusStats.sessionCount, 1, "Should have 1 valid session")
        
        XCTAssertEqual(usageStats.totalUsageTime, 2400, "Should include both app sessions")
        XCTAssertEqual(usageStats.appCount, 2, "Should count both apps")
        
        // Tag distribution should only include tagged sessions
        XCTAssertTrue(tagDistribution.isEmpty, "Should have no tag distribution (no tagged sessions)")
        
        // Combined statistics should work
        let combined = timeAnalysisManager.getCombinedStatistics(for: Date())
        XCTAssertEqual(combined.focus.totalFocusTime, 14400, "Combined focus should handle long session")
        XCTAssertEqual(combined.usage.totalUsageTime, 2400, "Combined usage should include all sessions")
    }
}