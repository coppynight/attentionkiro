import XCTest
import CoreData
@testable import FocusTracker

/// Comprehensive integration tests to ensure all MVP features work together correctly
class FullFeatureIntegrationTests: XCTestCase {
    
    var testContext: NSManagedObjectContext!
    var focusManager: FocusManager!
    var tagManager: TagManager!
    var timeAnalysisManager: TimeAnalysisManager!
    var errorService: ErrorHandlingService!
    var onboardingCoordinator: OnboardingCoordinator!
    
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
        
        // Initialize all managers in correct order
        focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        tagManager = TagManager(viewContext: testContext)
        timeAnalysisManager = TimeAnalysisManager(
            viewContext: testContext,
            focusManager: focusManager,
            tagManager: tagManager
        )
        errorService = ErrorHandlingService.shared
        onboardingCoordinator = OnboardingCoordinator.shared
    }
    
    override func tearDownWithError() throws {
        testContext = nil
        focusManager = nil
        tagManager = nil
        timeAnalysisManager = nil
        errorService = nil
        onboardingCoordinator = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Complete User Journey Tests
    
    func testCompleteUserJourney() throws {
        // Simulate a complete user journey from onboarding to daily usage
        
        // Step 1: User completes onboarding
        simulateOnboardingCompletion()
        
        // Step 2: User creates focus sessions
        let focusSessions = try createTestFocusSessions()
        
        // Step 3: User uses apps and gets tagged sessions
        let appSessions = try createTestAppUsageSessions()
        
        // Step 4: User applies tags to sessions
        try applyTagsToSessions(appSessions)
        
        // Step 5: User views statistics and analysis
        try verifyStatisticsAndAnalysis(focusSessions: focusSessions, appSessions: appSessions)
        
        // Step 6: User manages tags
        try verifyTagManagement()
        
        // Step 7: User adjusts settings
        try verifySettingsIntegration()
        
        // Step 8: Verify error handling works throughout
        try verifyErrorHandlingIntegration()
    }
    
    func testDataConsistencyAcrossFeatures() throws {
        // Test that data remains consistent across all features
        
        let today = Date()
        let calendar = Calendar.current
        
        // Create test data
        let focusSession = FocusSession(context: testContext)
        focusSession.startTime = today.addingTimeInterval(-3600)
        focusSession.endTime = today
        focusSession.duration = 3600
        focusSession.isValid = true
        focusSession.sessionType = "focus"
        
        let appSession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            startTime: today.addingTimeInterval(-1800),
            in: testContext
        )
        appSession.duration = 1800
        appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
        appSession.isProductiveTime = true
        
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        tagManager.updateTagForSession(appSession, tag: workTag)
        
        try testContext.save()
        
        // Verify data consistency across all managers
        let focusStats = focusManager.getFocusStatistics(for: today)
        let usageStats = timeAnalysisManager.getUsageStatistics(for: today)
        let tagDistribution = timeAnalysisManager.getSceneTagDistribution(for: today)
        let combined = timeAnalysisManager.getCombinedStatistics(for: today)
        
        // All managers should see the same data
        XCTAssertEqual(focusStats.totalFocusTime, 3600, "Focus manager should see correct focus time")
        XCTAssertEqual(usageStats.totalUsageTime, 1800, "Time analysis should see correct usage time")
        XCTAssertEqual(tagDistribution.count, 1, "Should have one tag distribution")
        XCTAssertEqual(tagDistribution.first?.tagName, "工作", "Should be work tag")
        XCTAssertEqual(combined.focus.totalFocusTime, 3600, "Combined stats should match focus")
        XCTAssertEqual(combined.usage.totalUsageTime, 1800, "Combined stats should match usage")
    }
    
    func testConcurrentOperationsStability() throws {
        // Test that concurrent operations across features don't cause issues
        
        let expectation1 = expectation(description: "Focus operations complete")
        let expectation2 = expectation(description: "Tag operations complete")
        let expectation3 = expectation(description: "Analysis operations complete")
        
        // Simulate concurrent operations
        DispatchQueue.global().async {
            // Focus tracking operations
            for i in 0..<10 {
                let session = FocusSession(context: self.testContext)
                session.startTime = Date().addingTimeInterval(TimeInterval(-i * 3600))
                session.endTime = Date().addingTimeInterval(TimeInterval(-i * 3600 + 1800))
                session.duration = 1800
                session.isValid = true
                session.sessionType = "focus"
            }
            
            do {
                try self.testContext.save()
                expectation1.fulfill()
            } catch {
                XCTFail("Focus operations failed: \(error)")
            }
        }
        
        DispatchQueue.global().async {
            // Tag management operations
            for i in 0..<10 {
                let session = AppUsageSession.createSession(
                    appIdentifier: "com.test.app\(i)",
                    appName: "Test App \(i)",
                    in: self.testContext
                )
                session.duration = TimeInterval(i * 300 + 600)
                session.endTime = session.startTime.addingTimeInterval(session.duration)
                
                let tag = self.tagManager.getDefaultTags().randomElement()!
                self.tagManager.updateTagForSession(session, tag: tag)
            }
            
            expectation2.fulfill()
        }
        
        DispatchQueue.global().async {
            // Analysis operations
            for _ in 0..<10 {
                _ = self.timeAnalysisManager.getUsageStatistics(for: Date())
                _ = self.timeAnalysisManager.getWeeklyTrend()
                _ = self.timeAnalysisManager.getSceneTagDistribution(for: Date())
            }
            
            expectation3.fulfill()
        }
        
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error, "Concurrent operations should complete without errors")
        }
    }
    
    func testBackwardCompatibilityWithExistingData() throws {
        // Test that new features work with existing data structures
        
        // Create "old" data (pre-extension)
        let oldFocusSession = FocusSession(context: testContext)
        oldFocusSession.startTime = Date().addingTimeInterval(-7200)
        oldFocusSession.endTime = Date().addingTimeInterval(-5400)
        oldFocusSession.duration = 1800
        oldFocusSession.isValid = true
        oldFocusSession.sessionType = "focus"
        
        let oldSettings = UserSettings.createDefaultSettings(in: testContext)
        oldSettings.dailyFocusGoal = 7200
        oldSettings.notificationsEnabled = true
        
        try testContext.save()
        
        // Initialize new features
        XCTAssertEqual(tagManager.getDefaultTags().count, 7, "Default tags should be created")
        
        // Create new data
        let newAppSession = AppUsageSession.createSession(
            appIdentifier: "com.test.newapp",
            appName: "New App",
            in: testContext
        )
        newAppSession.duration = 1200
        newAppSession.endTime = newAppSession.startTime.addingTimeInterval(newAppSession.duration)
        
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        tagManager.updateTagForSession(newAppSession, tag: workTag)
        
        try testContext.save()
        
        // Verify all features work together
        let focusStats = focusManager.getFocusStatistics(for: Date())
        let usageStats = timeAnalysisManager.getUsageStatistics(for: Date())
        let combined = timeAnalysisManager.getCombinedStatistics(for: Date())
        
        XCTAssertEqual(focusStats.totalFocusTime, 1800, "Old focus data should be accessible")
        XCTAssertEqual(usageStats.totalUsageTime, 1200, "New usage data should work")
        XCTAssertEqual(combined.focus.totalFocusTime, 1800, "Combined should include old focus data")
        XCTAssertEqual(combined.usage.totalUsageTime, 1200, "Combined should include new usage data")
    }
    
    func testPerformanceWithLargeDataset() throws {
        // Test performance with a large dataset across all features
        
        let calendar = Calendar.current
        let today = Date()
        
        // Create large dataset
        for dayOffset in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            
            // Focus sessions
            for i in 0..<5 {
                let focusSession = FocusSession(context: testContext)
                focusSession.startTime = date.addingTimeInterval(TimeInterval(i * 3600))
                focusSession.endTime = date.addingTimeInterval(TimeInterval(i * 3600 + 1800))
                focusSession.duration = 1800
                focusSession.isValid = true
                focusSession.sessionType = "focus"
            }
            
            // App usage sessions
            for i in 0..<20 {
                let appSession = AppUsageSession.createSession(
                    appIdentifier: "com.test.app\(i % 10)",
                    appName: "Test App \(i % 10)",
                    startTime: date.addingTimeInterval(TimeInterval(i * 600)),
                    in: testContext
                )
                appSession.duration = TimeInterval((i % 10 + 1) * 300)
                appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
                appSession.isProductiveTime = i % 3 == 0
                
                if i % 5 == 0 {
                    let tag = tagManager.getDefaultTags().randomElement()!
                    tagManager.updateTagForSession(appSession, tag: tag)
                }
            }
        }
        
        try testContext.save()
        
        // Measure performance of key operations
        measure {
            _ = focusManager.getFocusStatistics(for: today)
            _ = focusManager.getWeeklyTrend()
            _ = timeAnalysisManager.getUsageStatistics(for: today)
            _ = timeAnalysisManager.getWeeklyTrend()
            _ = timeAnalysisManager.getSceneTagDistribution(for: today)
            _ = timeAnalysisManager.getAppUsageBreakdown(for: today)
            _ = timeAnalysisManager.getCombinedStatistics(for: today)
            _ = tagManager.getTagDistribution(for: today)
        }
    }
    
    // MARK: - Helper Methods
    
    private func simulateOnboardingCompletion() {
        onboardingCoordinator.completeOnboarding()
        XCTAssertTrue(onboardingCoordinator.hasCompletedInitialOnboarding, "Onboarding should be completed")
        XCTAssertFalse(onboardingCoordinator.shouldShowOnboarding, "Should not show onboarding")
    }
    
    private func createTestFocusSessions() throws -> [FocusSession] {
        let calendar = Calendar.current
        let today = Date()
        var sessions: [FocusSession] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            
            let session = FocusSession(context: testContext)
            session.startTime = date
            session.endTime = date.addingTimeInterval(TimeInterval((i + 1) * 1800))
            session.duration = TimeInterval((i + 1) * 1800)
            session.isValid = session.duration >= 1800
            session.sessionType = "focus"
            
            sessions.append(session)
        }
        
        try testContext.save()
        return sessions
    }
    
    private func createTestAppUsageSessions() throws -> [AppUsageSession] {
        let calendar = Calendar.current
        let today = Date()
        var sessions: [AppUsageSession] = []
        
        let apps = [
            ("com.microsoft.Office.Word", "Microsoft Word", "productivity"),
            ("com.netflix.Netflix", "Netflix", "entertainment"),
            ("com.tencent.xin", "WeChat", "social"),
            ("com.apple.Health", "Health", "health"),
            ("com.taobao.taobao4iphone", "Taobao", "shopping")
        ]
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            
            for (j, (appId, appName, category)) in apps.enumerated() {
                let session = AppUsageSession.createSession(
                    appIdentifier: appId,
                    appName: appName,
                    categoryIdentifier: category,
                    startTime: date.addingTimeInterval(TimeInterval(j * 1800)),
                    in: testContext
                )
                session.duration = TimeInterval((j + 1) * 600)
                session.endTime = session.startTime.addingTimeInterval(session.duration)
                session.updateProductivityStatus()
                
                sessions.append(session)
            }
        }
        
        try testContext.save()
        return sessions
    }
    
    private func applyTagsToSessions(_ sessions: [AppUsageSession]) throws {
        let tagMapping = [
            "productivity": "工作",
            "entertainment": "娱乐",
            "social": "社交",
            "health": "健康",
            "shopping": "购物"
        ]
        
        for session in sessions {
            if let category = session.categoryIdentifier,
               let tagName = tagMapping[category],
               let tag = tagManager.getDefaultTags().first(where: { $0.name == tagName }) {
                tagManager.updateTagForSession(session, tag: tag)
            }
        }
        
        try testContext.save()
    }
    
    private func verifyStatisticsAndAnalysis(focusSessions: [FocusSession], appSessions: [AppUsageSession]) throws {
        let today = Date()
        
        // Focus statistics
        let focusStats = focusManager.getFocusStatistics(for: today)
        XCTAssertGreaterThan(focusStats.totalFocusTime, 0, "Should have focus time")
        
        // Usage statistics
        let usageStats = timeAnalysisManager.getUsageStatistics(for: today)
        XCTAssertGreaterThan(usageStats.totalUsageTime, 0, "Should have usage time")
        
        // Tag distribution
        let tagDistribution = timeAnalysisManager.getSceneTagDistribution(for: today)
        XCTAssertFalse(tagDistribution.isEmpty, "Should have tag distribution")
        
        // App breakdown
        let appBreakdown = timeAnalysisManager.getAppUsageBreakdown(for: today)
        XCTAssertFalse(appBreakdown.isEmpty, "Should have app breakdown")
        
        // Weekly trends
        let focusWeekly = focusManager.getWeeklyTrend()
        let usageWeekly = timeAnalysisManager.getWeeklyTrend()
        XCTAssertEqual(focusWeekly.count, 7, "Focus weekly should have 7 days")
        XCTAssertEqual(usageWeekly.count, 7, "Usage weekly should have 7 days")
        
        // Combined statistics
        let combined = timeAnalysisManager.getCombinedStatistics(for: today)
        XCTAssertNotNil(combined.focus, "Combined should have focus data")
        XCTAssertNotNil(combined.usage, "Combined should have usage data")
    }
    
    private func verifyTagManagement() throws {
        // Test tag creation
        let customTag = tagManager.createCustomTag(name: "测试标签", color: "#FF0000")
        XCTAssertNotNil(customTag, "Should create custom tag")
        
        // Test tag recommendations
        let recommendation = tagManager.suggestTagForApp("com.microsoft.Office.Word")
        XCTAssertNotNil(recommendation, "Should provide recommendation")
        XCTAssertEqual(recommendation?.tag.name, "工作", "Should recommend work tag")
        
        // Test tag deletion
        let success = tagManager.deleteTag(customTag!)
        XCTAssertTrue(success, "Should delete custom tag")
        
        // Test default tags cannot be deleted
        let defaultTag = tagManager.getDefaultTags().first!
        let failedDeletion = tagManager.deleteTag(defaultTag)
        XCTAssertFalse(failedDeletion, "Should not delete default tag")
    }
    
    private func verifySettingsIntegration() throws {
        // Test settings creation and modification
        let settings = UserSettings.createDefaultSettings(in: testContext)
        settings.dailyFocusGoal = 3600 // 1 hour
        settings.notificationsEnabled = true
        settings.lunchBreakEnabled = true
        
        try testContext.save()
        
        // Verify settings are accessible by other components
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let savedSettings = try testContext.fetch(request)
        
        XCTAssertEqual(savedSettings.count, 1, "Should have one settings object")
        XCTAssertEqual(savedSettings.first?.dailyFocusGoal, 3600, "Settings should be saved correctly")
    }
    
    private func verifyErrorHandlingIntegration() throws {
        // Test that error handling works across features
        
        // Simulate Core Data error
        let invalidSession = AppUsageSession.createSession(
            appIdentifier: "",
            appName: "",
            in: testContext
        )
        invalidSession.duration = -100 // Invalid duration
        
        // This should not crash the app
        let stats = timeAnalysisManager.getUsageStatistics(for: Date())
        XCTAssertNotNil(stats, "Should handle invalid data gracefully")
        
        // Test error reporting
        let testError = AppError.focusSessionCreationFailed()
        errorService.reportError(testError)
        
        XCTAssertNotNil(errorService.currentError, "Error should be reported")
        XCTAssertTrue(errorService.isShowingError, "Should show error")
        
        // Test error dismissal
        errorService.dismissError()
        XCTAssertNil(errorService.currentError, "Error should be dismissed")
        XCTAssertFalse(errorService.isShowingError, "Should not show error")
    }
    
    // MARK: - Edge Case Tests
    
    func testEdgeCasesAndBoundaryConditions() throws {
        // Test various edge cases that could occur in real usage
        
        // Empty data scenarios
        let emptyFocusStats = focusManager.getFocusStatistics(for: Date())
        let emptyUsageStats = timeAnalysisManager.getUsageStatistics(for: Date())
        
        XCTAssertEqual(emptyFocusStats.totalFocusTime, 0, "Empty focus stats should be zero")
        XCTAssertEqual(emptyUsageStats.totalUsageTime, 0, "Empty usage stats should be zero")
        
        // Very large time intervals
        let largeSession = AppUsageSession.createSession(
            appIdentifier: "com.test.large",
            appName: "Large Session",
            in: testContext
        )
        largeSession.duration = 24 * 3600 // 24 hours
        largeSession.endTime = largeSession.startTime.addingTimeInterval(largeSession.duration)
        
        try testContext.save()
        
        let statsWithLarge = timeAnalysisManager.getUsageStatistics(for: Date())
        XCTAssertEqual(statsWithLarge.totalUsageTime, 24 * 3600, "Should handle large durations")
        
        // Negative durations (corrupted data)
        let corruptedSession = AppUsageSession.createSession(
            appIdentifier: "com.test.corrupted",
            appName: "Corrupted Session",
            in: testContext
        )
        corruptedSession.duration = -3600 // Negative duration
        
        try testContext.save()
        
        // Should not crash
        let statsWithCorrupted = timeAnalysisManager.getUsageStatistics(for: Date())
        XCTAssertNotNil(statsWithCorrupted, "Should handle corrupted data")
        
        // Future dates
        let futureDate = Date().addingTimeInterval(86400) // Tomorrow
        let futureStats = timeAnalysisManager.getUsageStatistics(for: futureDate)
        XCTAssertEqual(futureStats.totalUsageTime, 0, "Future dates should have no data")
        
        // Very old dates
        let oldDate = Date().addingTimeInterval(-365 * 86400) // One year ago
        let oldStats = timeAnalysisManager.getUsageStatistics(for: oldDate)
        XCTAssertEqual(oldStats.totalUsageTime, 0, "Old dates should have no data")
    }
    
    func testMemoryAndResourceManagement() throws {
        // Test that the app manages memory and resources properly
        
        // Create many objects
        var sessions: [AppUsageSession] = []
        for i in 0..<1000 {
            let session = AppUsageSession.createSession(
                appIdentifier: "com.test.memory\(i)",
                appName: "Memory Test \(i)",
                in: testContext
            )
            session.duration = TimeInterval(i * 60)
            sessions.append(session)
        }
        
        try testContext.save()
        
        // Perform operations that should not cause memory issues
        for _ in 0..<10 {
            _ = timeAnalysisManager.getUsageStatistics(for: Date())
            _ = timeAnalysisManager.getAppUsageBreakdown(for: Date())
            _ = timeAnalysisManager.getWeeklyTrend()
        }
        
        // Clean up
        for session in sessions {
            testContext.delete(session)
        }
        
        try testContext.save()
        
        // Verify cleanup
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        let remainingSessions = try testContext.fetch(request)
        XCTAssertTrue(remainingSessions.count < 100, "Should clean up test sessions")
    }
}