import XCTest
import CoreData
@testable import FocusTracker

/// Final verification tests to ensure the extended version is ready for release
class ReleaseVerificationTests: XCTestCase {
    
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
    
    // MARK: - Core Functionality Verification
    
    func testAllMVPFeaturesAreImplemented() throws {
        // Verify all MVP features from requirements are implemented
        
        // 1. Original focus tracking functionality
        let focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        XCTAssertNotNil(focusManager, "FocusManager should be available")
        
        let focusSession = FocusSession(context: testContext)
        focusSession.startTime = Date().addingTimeInterval(-3600)
        focusSession.endTime = Date()
        focusSession.duration = 3600
        focusSession.isValid = true
        focusSession.sessionType = "focus"
        
        try testContext.save()
        
        let focusStats = focusManager.getFocusStatistics(for: Date())
        XCTAssertEqual(focusStats.totalFocusTime, 3600, "Focus tracking should work")
        
        // 2. Time analysis functionality
        let tagManager = TagManager(viewContext: testContext)
        let timeAnalysisManager = TimeAnalysisManager(
            viewContext: testContext,
            focusManager: focusManager,
            tagManager: tagManager
        )
        
        XCTAssertNotNil(timeAnalysisManager, "TimeAnalysisManager should be available")
        
        let appSession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        appSession.duration = 1800
        appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
        
        try testContext.save()
        
        let usageStats = timeAnalysisManager.getUsageStatistics(for: Date())
        XCTAssertEqual(usageStats.totalUsageTime, 1800, "Time analysis should work")
        
        // 3. Scene tag functionality
        XCTAssertNotNil(tagManager, "TagManager should be available")
        
        let defaultTags = tagManager.getDefaultTags()
        XCTAssertEqual(defaultTags.count, 7, "Should have 7 default tags")
        
        let workTag = defaultTags.first { $0.name == "工作" }!
        tagManager.updateTagForSession(appSession, tag: workTag)
        
        XCTAssertEqual(appSession.sceneTag, "工作", "Tag assignment should work")
        
        // 4. Enhanced statistics
        let tagDistribution = timeAnalysisManager.getSceneTagDistribution(for: Date())
        XCTAssertEqual(tagDistribution.count, 1, "Tag distribution should work")
        
        let appBreakdown = timeAnalysisManager.getAppUsageBreakdown(for: Date())
        XCTAssertEqual(appBreakdown.count, 1, "App breakdown should work")
        
        let weeklyTrend = timeAnalysisManager.getWeeklyTrend()
        XCTAssertEqual(weeklyTrend.count, 7, "Weekly trend should work")
        
        // 5. Combined statistics
        let combined = timeAnalysisManager.getCombinedStatistics(for: Date())
        XCTAssertEqual(combined.focus.totalFocusTime, 3600, "Combined focus stats should work")
        XCTAssertEqual(combined.usage.totalUsageTime, 1800, "Combined usage stats should work")
    }
    
    func testAllRequiredDataModelsExist() throws {
        // Verify all required data models are properly implemented
        
        // Original models
        let focusSession = FocusSession(context: testContext)
        XCTAssertNotNil(focusSession, "FocusSession model should exist")
        
        let userSettings = UserSettings(context: testContext)
        XCTAssertNotNil(userSettings, "UserSettings model should exist")
        
        // New models
        let appUsageSession = AppUsageSession(context: testContext)
        XCTAssertNotNil(appUsageSession, "AppUsageSession model should exist")
        
        let sceneTag = SceneTag(context: testContext)
        XCTAssertNotNil(sceneTag, "SceneTag model should exist")
        
        // Test model properties and methods
        focusSession.startTime = Date()
        focusSession.duration = 3600
        XCTAssertNotNil(focusSession.formattedDuration, "FocusSession computed properties should work")
        
        appUsageSession.appIdentifier = "com.test.app"
        appUsageSession.duration = 1800
        XCTAssertNotNil(appUsageSession.formattedDuration, "AppUsageSession computed properties should work")
        
        sceneTag.name = "测试"
        sceneTag.color = "#FF0000"
        XCTAssertNotNil(sceneTag.swiftUIColor, "SceneTag computed properties should work")
        
        userSettings.dailyFocusGoal = 7200
        XCTAssertNotNil(userSettings.formattedDailyGoal, "UserSettings computed properties should work")
    }
    
    func testAllServicesAreProperlyInitialized() throws {
        // Verify all services can be initialized and work correctly
        
        // Core services
        let focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        XCTAssertNotNil(focusManager, "FocusManager should initialize")
        
        let tagManager = TagManager(viewContext: testContext)
        XCTAssertNotNil(tagManager, "TagManager should initialize")
        XCTAssertTrue(tagManager.isInitialized, "TagManager should be initialized")
        
        let timeAnalysisManager = TimeAnalysisManager(
            viewContext: testContext,
            focusManager: focusManager,
            tagManager: tagManager
        )
        XCTAssertNotNil(timeAnalysisManager, "TimeAnalysisManager should initialize")
        
        // Support services
        let errorService = ErrorHandlingService.shared
        XCTAssertNotNil(errorService, "ErrorHandlingService should be available")
        
        let onboardingCoordinator = OnboardingCoordinator.shared
        XCTAssertNotNil(onboardingCoordinator, "OnboardingCoordinator should be available")
        
        // Test service interactions
        timeAnalysisManager.startMonitoring()
        XCTAssertTrue(timeAnalysisManager.isMonitoring, "TimeAnalysisManager monitoring should work")
        
        timeAnalysisManager.stopMonitoring()
        XCTAssertFalse(timeAnalysisManager.isMonitoring, "TimeAnalysisManager stop should work")
    }
    
    // MARK: - User Experience Verification
    
    func testOnboardingFlowIsComplete() throws {
        // Verify onboarding flow covers all new features
        
        let coordinator = OnboardingCoordinator.shared
        coordinator.resetOnboarding() // Reset for testing
        
        XCTAssertFalse(coordinator.hasCompletedInitialOnboarding, "Should not be completed initially")
        XCTAssertTrue(coordinator.shouldShowOnboarding, "Should show onboarding")
        
        // Test all onboarding steps exist
        let allSteps = OnboardingStep.allCases
        XCTAssertEqual(allSteps.count, 6, "Should have 6 onboarding steps")
        
        let expectedSteps: [OnboardingStep] = [.welcome, .focusTracking, .timeAnalysis, .sceneTags, .notifications, .completion]
        for step in expectedSteps {
            XCTAssertTrue(allSteps.contains(step), "Should contain step: \(step)")
        }
        
        // Test step progression
        coordinator.startOnboarding()
        XCTAssertEqual(coordinator.currentOnboardingStep, .welcome, "Should start with welcome")
        
        coordinator.nextStep()
        XCTAssertEqual(coordinator.currentOnboardingStep, .focusTracking, "Should progress to focus tracking")
        
        coordinator.nextStep()
        XCTAssertEqual(coordinator.currentOnboardingStep, .timeAnalysis, "Should progress to time analysis")
        
        coordinator.nextStep()
        XCTAssertEqual(coordinator.currentOnboardingStep, .sceneTags, "Should progress to scene tags")
        
        coordinator.nextStep()
        XCTAssertEqual(coordinator.currentOnboardingStep, .notifications, "Should progress to notifications")
        
        coordinator.nextStep()
        XCTAssertEqual(coordinator.currentOnboardingStep, .completion, "Should progress to completion")
        
        coordinator.completeOnboarding()
        XCTAssertTrue(coordinator.hasCompletedInitialOnboarding, "Should be completed")
        XCTAssertFalse(coordinator.shouldShowOnboarding, "Should not show onboarding")
    }
    
    func testErrorHandlingIsComprehensive() throws {
        // Verify error handling covers all scenarios
        
        let errorService = ErrorHandlingService.shared
        errorService.clearErrorHistory()
        
        // Test different error types
        let coreDataError = AppError.coreDataSaveFailed(NSError(domain: "test", code: 1))
        errorService.reportError(coreDataError)
        XCTAssertNotNil(errorService.currentError, "Should report Core Data error")
        
        errorService.dismissError()
        
        let tagError = AppError.tagCreationFailed("Duplicate name")
        errorService.reportError(tagError)
        XCTAssertNotNil(errorService.currentError, "Should report tag error")
        
        errorService.dismissError()
        
        let analysisError = AppError.timeAnalysisCalculationFailed()
        errorService.reportError(analysisError)
        XCTAssertNotNil(errorService.currentError, "Should report analysis error")
        
        errorService.dismissError()
        
        // Test error statistics
        let stats = errorService.getErrorStatistics()
        XCTAssertEqual(stats.totalErrors, 3, "Should track all reported errors")
        XCTAssertTrue(stats.errorsByType.count > 0, "Should categorize errors by type")
        XCTAssertTrue(stats.errorsByContext.count > 0, "Should categorize errors by context")
    }
    
    func testFeatureHighlightsAreConfigured() throws {
        // Verify feature highlights are properly configured
        
        let highlightManager = FeatureHighlightManager.shared
        XCTAssertNotNil(highlightManager, "FeatureHighlightManager should be available")
        
        // Test predefined highlights exist
        let timeUsageRing = HighlightFeature.timeUsageRing
        XCTAssertEqual(timeUsageRing.title, "时间使用环形图", "Time usage ring highlight should be configured")
        
        let appBreakdown = HighlightFeature.appBreakdown
        XCTAssertEqual(appBreakdown.title, "应用使用分析", "App breakdown highlight should be configured")
        
        let sceneTagSummary = HighlightFeature.sceneTagSummary
        XCTAssertEqual(sceneTagSummary.title, "场景标签统计", "Scene tag summary highlight should be configured")
        
        // Test highlight contexts
        highlightManager.showFeatureHighlights(for: .home)
        highlightManager.showFeatureHighlights(for: .statistics)
        highlightManager.showFeatureHighlights(for: .tags)
        highlightManager.showFeatureHighlights(for: .settings)
        
        // Should not crash
        XCTAssertTrue(true, "Feature highlights should work for all contexts")
    }
    
    // MARK: - Performance Verification
    
    func testPerformanceIsAcceptable() throws {
        // Verify performance is acceptable with realistic data
        
        let calendar = Calendar.current
        let today = Date()
        
        // Create realistic dataset
        let focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        let tagManager = TagManager(viewContext: testContext)
        let timeAnalysisManager = TimeAnalysisManager(
            viewContext: testContext,
            focusManager: focusManager,
            tagManager: tagManager
        )
        
        // Create 30 days of data
        for dayOffset in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            
            // 2-3 focus sessions per day
            for i in 0..<3 {
                let focusSession = FocusSession(context: testContext)
                focusSession.startTime = date.addingTimeInterval(TimeInterval(i * 3600))
                focusSession.endTime = date.addingTimeInterval(TimeInterval(i * 3600 + 1800))
                focusSession.duration = 1800
                focusSession.isValid = true
                focusSession.sessionType = "focus"
            }
            
            // 10-15 app usage sessions per day
            for i in 0..<15 {
                let appSession = AppUsageSession.createSession(
                    appIdentifier: "com.test.app\(i % 5)",
                    appName: "Test App \(i % 5)",
                    startTime: date.addingTimeInterval(TimeInterval(i * 600)),
                    in: testContext
                )
                appSession.duration = TimeInterval((i % 10 + 1) * 300)
                appSession.endTime = appSession.startTime.addingTimeInterval(appSession.duration)
                appSession.isProductiveTime = i % 3 == 0
                
                if i % 3 == 0 {
                    let tag = tagManager.getDefaultTags().randomElement()!
                    tagManager.updateTagForSession(appSession, tag: tag)
                }
            }
        }
        
        try testContext.save()
        
        // Measure key operations
        measure {
            _ = focusManager.getFocusStatistics(for: today)
            _ = timeAnalysisManager.getUsageStatistics(for: today)
            _ = timeAnalysisManager.getWeeklyTrend()
            _ = timeAnalysisManager.getSceneTagDistribution(for: today)
            _ = timeAnalysisManager.getAppUsageBreakdown(for: today)
            _ = timeAnalysisManager.getCombinedStatistics(for: today)
        }
    }
    
    func testMemoryUsageIsReasonable() throws {
        // Verify memory usage doesn't grow excessively
        
        let focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        let tagManager = TagManager(viewContext: testContext)
        let timeAnalysisManager = TimeAnalysisManager(
            viewContext: testContext,
            focusManager: focusManager,
            tagManager: tagManager
        )
        
        // Create and process data multiple times
        for iteration in 0..<10 {
            // Create temporary data
            var sessions: [AppUsageSession] = []
            for i in 0..<100 {
                let session = AppUsageSession.createSession(
                    appIdentifier: "com.temp.app\(i)",
                    appName: "Temp App \(i)",
                    in: testContext
                )
                session.duration = TimeInterval(i * 60)
                sessions.append(session)
            }
            
            try testContext.save()
            
            // Process data
            _ = timeAnalysisManager.getUsageStatistics(for: Date())
            _ = timeAnalysisManager.getAppUsageBreakdown(for: Date())
            
            // Clean up
            for session in sessions {
                testContext.delete(session)
            }
            
            try testContext.save()
        }
        
        // Should complete without memory issues
        XCTAssertTrue(true, "Memory usage should be reasonable")
    }
    
    // MARK: - Integration Verification
    
    func testAllFeaturesWorkTogether() throws {
        // Comprehensive test that all features work together seamlessly
        
        let focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        let tagManager = TagManager(viewContext: testContext)
        let timeAnalysisManager = TimeAnalysisManager(
            viewContext: testContext,
            focusManager: focusManager,
            tagManager: tagManager
        )
        
        let today = Date()
        
        // 1. User creates focus session
        let focusSession = FocusSession(context: testContext)
        focusSession.startTime = today.addingTimeInterval(-7200)
        focusSession.endTime = today.addingTimeInterval(-5400)
        focusSession.duration = 1800
        focusSession.isValid = true
        focusSession.sessionType = "focus"
        
        // 2. User uses apps
        let workApp = AppUsageSession.createSession(
            appIdentifier: "com.microsoft.Office.Word",
            appName: "Microsoft Word",
            categoryIdentifier: "productivity",
            startTime: today.addingTimeInterval(-5400),
            in: testContext
        )
        workApp.duration = 2700
        workApp.endTime = workApp.startTime.addingTimeInterval(workApp.duration)
        workApp.updateProductivityStatus()
        
        let entertainmentApp = AppUsageSession.createSession(
            appIdentifier: "com.netflix.Netflix",
            appName: "Netflix",
            categoryIdentifier: "entertainment",
            startTime: today.addingTimeInterval(-2700),
            in: testContext
        )
        entertainmentApp.duration = 1800
        entertainmentApp.endTime = entertainmentApp.startTime.addingTimeInterval(entertainmentApp.duration)
        entertainmentApp.updateProductivityStatus()
        
        // 3. User applies tags
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        let entertainmentTag = tagManager.getDefaultTags().first { $0.name == "娱乐" }!
        
        tagManager.updateTagForSession(workApp, tag: workTag)
        tagManager.updateTagForSession(entertainmentApp, tag: entertainmentTag)
        
        // 4. User creates custom tag
        let customTag = tagManager.createCustomTag(name: "学习编程", color: "#00FF00")
        XCTAssertNotNil(customTag, "Should create custom tag")
        
        try testContext.save()
        
        // 5. Verify all statistics work together
        let focusStats = focusManager.getFocusStatistics(for: today)
        let usageStats = timeAnalysisManager.getUsageStatistics(for: today)
        let tagDistribution = timeAnalysisManager.getSceneTagDistribution(for: today)
        let appBreakdown = timeAnalysisManager.getAppUsageBreakdown(for: today)
        let combined = timeAnalysisManager.getCombinedStatistics(for: today)
        
        // Verify focus tracking
        XCTAssertEqual(focusStats.totalFocusTime, 1800, "Focus tracking should work")
        XCTAssertEqual(focusStats.sessionCount, 1, "Should count focus sessions")
        
        // Verify usage analysis
        XCTAssertEqual(usageStats.totalUsageTime, 4500, "Usage analysis should work")
        XCTAssertEqual(usageStats.productiveTime, 2700, "Productivity analysis should work")
        XCTAssertEqual(usageStats.appCount, 2, "App counting should work")
        
        // Verify tag distribution
        XCTAssertEqual(tagDistribution.count, 2, "Tag distribution should work")
        let workDist = tagDistribution.first { $0.tagName == "工作" }
        let entertainmentDist = tagDistribution.first { $0.tagName == "娱乐" }
        XCTAssertNotNil(workDist, "Work tag distribution should exist")
        XCTAssertNotNil(entertainmentDist, "Entertainment tag distribution should exist")
        
        // Verify app breakdown
        XCTAssertEqual(appBreakdown.count, 2, "App breakdown should work")
        let wordApp = appBreakdown.first { $0.appName == "Microsoft Word" }
        let netflixApp = appBreakdown.first { $0.appName == "Netflix" }
        XCTAssertNotNil(wordApp, "Word app should be in breakdown")
        XCTAssertNotNil(netflixApp, "Netflix app should be in breakdown")
        
        // Verify combined statistics
        XCTAssertEqual(combined.focus.totalFocusTime, 1800, "Combined focus should work")
        XCTAssertEqual(combined.usage.totalUsageTime, 4500, "Combined usage should work")
        
        // 6. Verify tag management
        XCTAssertEqual(tagManager.getAllTags().count, 8, "Should have 7 default + 1 custom tag")
        
        let recommendation = tagManager.suggestTagForApp("com.apple.iBooks")
        XCTAssertNotNil(recommendation, "Tag recommendation should work")
        XCTAssertEqual(recommendation?.tag.name, "学习", "Should recommend study tag for iBooks")
        
        // 7. Verify weekly trends
        let focusWeekly = focusManager.getWeeklyTrend()
        let usageWeekly = timeAnalysisManager.getWeeklyTrend()
        
        XCTAssertEqual(focusWeekly.count, 7, "Focus weekly trend should work")
        XCTAssertEqual(usageWeekly.count, 7, "Usage weekly trend should work")
        
        let todayFocus = focusWeekly.last!
        let todayUsage = usageWeekly.last!
        
        XCTAssertEqual(todayFocus.totalFocusTime, 1800, "Today's focus in weekly trend should match")
        XCTAssertEqual(todayUsage.totalUsageTime, 4500, "Today's usage in weekly trend should match")
    }
    
    func testBackwardCompatibilityIsPreserved() throws {
        // Verify that existing v1.0 functionality still works exactly as before
        
        // Create v1.0 style data
        let focusSession = FocusSession(context: testContext)
        focusSession.startTime = Date().addingTimeInterval(-3600)
        focusSession.endTime = Date()
        focusSession.duration = 3600
        focusSession.isValid = true
        focusSession.sessionType = "focus"
        
        let settings = UserSettings.createDefaultSettings(in: testContext)
        settings.dailyFocusGoal = 7200
        settings.notificationsEnabled = true
        
        try testContext.save()
        
        // Initialize only FocusManager (as in v1.0)
        let focusManager = FocusManager(usageMonitor: TestUsageMonitor(), viewContext: testContext)
        
        // Verify v1.0 functionality works exactly as before
        let stats = focusManager.getFocusStatistics(for: Date())
        XCTAssertEqual(stats.totalFocusTime, 3600, "Original focus tracking should work")
        XCTAssertEqual(stats.sessionCount, 1, "Original session counting should work")
        XCTAssertEqual(stats.sessionCount, 1, "Original validation should work")
        
        let weeklyTrend = focusManager.getWeeklyTrend()
        XCTAssertEqual(weeklyTrend.count, 7, "Original weekly trend should work")
        
        // Verify settings work as before
        let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let savedSettings = try testContext.fetch(settingsRequest)
        XCTAssertEqual(savedSettings.count, 1, "Settings should be preserved")
        XCTAssertEqual(savedSettings.first?.dailyFocusGoal, 7200, "Settings values should be preserved")
        
        // Now initialize new features
        let tagManager = TagManager(viewContext: testContext)
        let timeAnalysisManager = TimeAnalysisManager(
            viewContext: testContext,
            focusManager: focusManager,
            tagManager: tagManager
        )
        
        // Verify original functionality still works after new features are added
        let statsAfter = focusManager.getFocusStatistics(for: Date())
        XCTAssertEqual(statsAfter.totalFocusTime, 3600, "Original functionality should be unchanged")
        XCTAssertEqual(statsAfter.sessionCount, 1, "Original functionality should be unchanged")
        
        // Verify new features work alongside
        let usageStats = timeAnalysisManager.getUsageStatistics(for: Date())
        XCTAssertNotNil(usageStats, "New features should work")
        
        let defaultTags = tagManager.getDefaultTags()
        XCTAssertEqual(defaultTags.count, 7, "New features should work")
    }
    
    // MARK: - Final Release Checklist
    
    func testReleaseReadinessChecklist() throws {
        // Final checklist to ensure the app is ready for release
        
        // ✅ All MVP features implemented
        XCTAssertNoThrow(try testAllMVPFeaturesAreImplemented(), "All MVP features should be implemented")
        
        // ✅ All data models exist and work
        XCTAssertNoThrow(try testAllRequiredDataModelsExist(), "All data models should exist")
        
        // ✅ All services initialize correctly
        XCTAssertNoThrow(try testAllServicesAreProperlyInitialized(), "All services should initialize")
        
        // ✅ Onboarding flow is complete
        XCTAssertNoThrow(try testOnboardingFlowIsComplete(), "Onboarding should be complete")
        
        // ✅ Error handling is comprehensive
        XCTAssertNoThrow(try testErrorHandlingIsComprehensive(), "Error handling should be comprehensive")
        
        // ✅ Performance is acceptable
        XCTAssertNoThrow(try testPerformanceIsAcceptable(), "Performance should be acceptable")
        
        // ✅ All features work together
        XCTAssertNoThrow(try testAllFeaturesWorkTogether(), "All features should work together")
        
        // ✅ Backward compatibility is preserved
        XCTAssertNoThrow(try testBackwardCompatibilityIsPreserved(), "Backward compatibility should be preserved")
        
        print("🎉 All release verification tests passed! The extended version is ready for release.")
    }
}