import XCTest
import CoreData
@testable import FocusTracker

class AppUsageSessionTests: XCTestCase {
    
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
    
    // MARK: - Creation Tests
    
    func testCreateSession() throws {
        // Given: Session parameters
        let appIdentifier = "com.test.app"
        let appName = "Test App"
        let categoryIdentifier = "productivity"
        let startTime = Date()
        
        // When: Creating session
        let session = AppUsageSession.createSession(
            appIdentifier: appIdentifier,
            appName: appName,
            categoryIdentifier: categoryIdentifier,
            startTime: startTime,
            in: testContext
        )
        
        // Then: Session should be created with correct properties
        XCTAssertEqual(session.appIdentifier, appIdentifier, "App identifier should match")
        XCTAssertEqual(session.appName, appName, "App name should match")
        XCTAssertEqual(session.categoryIdentifier, categoryIdentifier, "Category should match")
        XCTAssertEqual(session.startTime, startTime, "Start time should match")
        XCTAssertEqual(session.duration, 0, "Duration should be 0 initially")
        XCTAssertEqual(session.interruptionCount, 0, "Interruption count should be 0 initially")
        XCTAssertFalse(session.isProductiveTime, "Should not be productive initially")
        XCTAssertNil(session.endTime, "End time should be nil initially")
    }
    
    func testCreateSessionWithDefaults() throws {
        // Given: Minimal parameters
        let appIdentifier = "com.test.app"
        let appName = "Test App"
        
        // When: Creating session with defaults
        let session = AppUsageSession.createSession(
            appIdentifier: appIdentifier,
            appName: appName,
            in: testContext
        )
        
        // Then: Should use default values
        XCTAssertEqual(session.appIdentifier, appIdentifier, "App identifier should match")
        XCTAssertEqual(session.appName, appName, "App name should match")
        XCTAssertNil(session.categoryIdentifier, "Category should be nil by default")
        XCTAssertNotNil(session.startTime, "Start time should be set to current time")
        XCTAssertEqual(session.duration, 0, "Duration should be 0")
        XCTAssertEqual(session.interruptionCount, 0, "Interruption count should be 0")
        XCTAssertFalse(session.isProductiveTime, "Should not be productive by default")
    }
    
    // MARK: - Computed Properties Tests
    
    func testFormattedDuration() throws {
        // Given: Session with different durations
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        
        // Test hours and minutes
        session.duration = 3665 // 1 hour, 1 minute, 5 seconds
        XCTAssertEqual(session.formattedDuration, "1h 1m", "Should format hours and minutes")
        
        // Test minutes and seconds
        session.duration = 125 // 2 minutes, 5 seconds
        XCTAssertEqual(session.formattedDuration, "2m 5s", "Should format minutes and seconds")
        
        // Test seconds only
        session.duration = 45 // 45 seconds
        XCTAssertEqual(session.formattedDuration, "45s", "Should format seconds only")
        
        // Test zero duration
        session.duration = 0
        XCTAssertEqual(session.formattedDuration, "0s", "Should format zero duration")
    }
    
    func testIsActive() throws {
        // Given: Session
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        
        // When: Session has no end time
        session.endTime = nil
        
        // Then: Should be active
        XCTAssertTrue(session.isActive, "Session without end time should be active")
        
        // When: Session has end time
        session.endTime = Date()
        
        // Then: Should not be active
        XCTAssertFalse(session.isActive, "Session with end time should not be active")
    }
    
    func testCurrentDuration() throws {
        // Given: Session started 30 minutes ago
        let startTime = Date().addingTimeInterval(-30 * 60)
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            startTime: startTime,
            in: testContext
        )
        
        // When: Session is active (no end time)
        session.endTime = nil
        
        // Then: Current duration should be approximately 30 minutes
        XCTAssertEqual(session.currentDuration, 30 * 60, accuracy: 5.0, "Active session duration should be ~30 minutes")
        
        // When: Session is completed
        let endTime = startTime.addingTimeInterval(45 * 60)
        session.endTime = endTime
        
        // Then: Current duration should be the completed duration
        XCTAssertEqual(session.currentDuration, 45 * 60, "Completed session duration should be 45 minutes")
    }
    
    func testCategoryDisplayName() throws {
        // Given: Session
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        
        // Test known categories
        let categoryMappings = [
            "productivity": "效率工具",
            "social": "社交网络",
            "entertainment": "娱乐",
            "games": "游戏",
            "education": "教育",
            "health": "健康健身",
            "finance": "财务",
            "shopping": "购物",
            "travel": "旅行",
            "news": "新闻",
            "utilities": "工具",
            "reference": "参考",
            "lifestyle": "生活",
            "business": "商务",
            "developer": "开发者工具"
        ]
        
        for (categoryId, expectedDisplayName) in categoryMappings {
            session.categoryIdentifier = categoryId
            XCTAssertEqual(session.categoryDisplayName, expectedDisplayName, "Category \(categoryId) should display as \(expectedDisplayName)")
        }
        
        // Test unknown category
        session.categoryIdentifier = "unknown_category"
        XCTAssertEqual(session.categoryDisplayName, "其他", "Unknown category should display as '其他'")
        
        // Test nil category
        session.categoryIdentifier = nil
        XCTAssertEqual(session.categoryDisplayName, "未分类", "Nil category should display as '未分类'")
    }
    
    // MARK: - Session Management Tests
    
    func testEndSession() throws {
        // Given: Active session started 30 minutes ago
        let startTime = Date().addingTimeInterval(-30 * 60)
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            startTime: startTime,
            in: testContext
        )
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
    
    func testEndSessionAlreadyEnded() throws {
        // Given: Already completed session
        let startTime = Date().addingTimeInterval(-30 * 60)
        let endTime = Date()
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            startTime: startTime,
            in: testContext
        )
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
    
    func testRecordInterruption() throws {
        // Given: Session
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        
        XCTAssertEqual(session.interruptionCount, 0, "Initial interruption count should be 0")
        
        // When: Recording interruptions
        session.recordInterruption()
        XCTAssertEqual(session.interruptionCount, 1, "Interruption count should be 1")
        
        session.recordInterruption()
        XCTAssertEqual(session.interruptionCount, 2, "Interruption count should be 2")
        
        session.recordInterruption()
        XCTAssertEqual(session.interruptionCount, 3, "Interruption count should be 3")
    }
    
    // MARK: - Productivity Evaluation Tests
    
    func testEvaluateProductivity() throws {
        // Given: Session
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        
        // Test productive category with sufficient duration
        session.categoryIdentifier = "productivity"
        session.duration = 10 * 60 // 10 minutes
        XCTAssertTrue(session.evaluateProductivity(), "Productive category with 10 minutes should be productive")
        
        // Test productive category with insufficient duration
        session.categoryIdentifier = "productivity"
        session.duration = 2 * 60 // 2 minutes
        XCTAssertFalse(session.evaluateProductivity(), "Productive category with 2 minutes should not be productive")
        
        // Test non-productive category
        session.categoryIdentifier = "entertainment"
        session.duration = 30 * 60 // 30 minutes
        XCTAssertFalse(session.evaluateProductivity(), "Entertainment category should not be productive")
        
        // Test unknown category
        session.categoryIdentifier = "unknown"
        session.duration = 30 * 60
        XCTAssertFalse(session.evaluateProductivity(), "Unknown category should not be productive")
        
        // Test nil category
        session.categoryIdentifier = nil
        session.duration = 30 * 60
        XCTAssertFalse(session.evaluateProductivity(), "Nil category should not be productive")
        
        // Test all productive categories
        let productiveCategories = ["productivity", "education", "business", "developer", "reference"]
        for category in productiveCategories {
            session.categoryIdentifier = category
            session.duration = 10 * 60
            XCTAssertTrue(session.evaluateProductivity(), "Category \(category) should be productive")
        }
    }
    
    func testUpdateProductivityStatus() throws {
        // Given: Session
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        
        // Test updating to productive
        session.categoryIdentifier = "productivity"
        session.duration = 10 * 60
        session.isProductiveTime = false
        
        session.updateProductivityStatus()
        XCTAssertTrue(session.isProductiveTime, "Should update to productive")
        
        // Test updating to non-productive
        session.categoryIdentifier = "entertainment"
        session.duration = 30 * 60
        session.isProductiveTime = true
        
        session.updateProductivityStatus()
        XCTAssertFalse(session.isProductiveTime, "Should update to non-productive")
    }
    
    // MARK: - Core Data Persistence Tests
    
    func testPersistence() throws {
        // Given: Session
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            categoryIdentifier: "productivity",
            in: testContext
        )
        session.duration = 30 * 60
        session.endTime = Date()
        session.isProductiveTime = true
        session.interruptionCount = 2
        session.sceneTag = "工作"
        
        // When: Saving to Core Data
        try testContext.save()
        
        // Then: Session should be persisted
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        let sessions = try testContext.fetch(request)
        
        XCTAssertEqual(sessions.count, 1, "Should have one persisted session")
        
        let persistedSession = sessions.first!
        XCTAssertEqual(persistedSession.appIdentifier, "com.test.app", "App identifier should be persisted")
        XCTAssertEqual(persistedSession.appName, "Test App", "App name should be persisted")
        XCTAssertEqual(persistedSession.categoryIdentifier, "productivity", "Category should be persisted")
        XCTAssertEqual(persistedSession.duration, 30 * 60, "Duration should be persisted")
        XCTAssertNotNil(persistedSession.endTime, "End time should be persisted")
        XCTAssertTrue(persistedSession.isProductiveTime, "Productivity flag should be persisted")
        XCTAssertEqual(persistedSession.interruptionCount, 2, "Interruption count should be persisted")
        XCTAssertEqual(persistedSession.sceneTag, "工作", "Scene tag should be persisted")
    }
    
    func testFetchByAppIdentifier() throws {
        // Given: Multiple sessions for different apps
        let app1Session1 = AppUsageSession.createSession(
            appIdentifier: "com.test.app1",
            appName: "Test App 1",
            in: testContext
        )
        app1Session1.duration = 30 * 60
        
        let app1Session2 = AppUsageSession.createSession(
            appIdentifier: "com.test.app1",
            appName: "Test App 1",
            in: testContext
        )
        app1Session2.duration = 45 * 60
        
        let app2Session = AppUsageSession.createSession(
            appIdentifier: "com.test.app2",
            appName: "Test App 2",
            in: testContext
        )
        app2Session.duration = 20 * 60
        
        try testContext.save()
        
        // When: Fetching sessions for specific app
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "appIdentifier == %@", "com.test.app1")
        let app1Sessions = try testContext.fetch(request)
        
        // Then: Should return only sessions for that app
        XCTAssertEqual(app1Sessions.count, 2, "Should have 2 sessions for app1")
        for session in app1Sessions {
            XCTAssertEqual(session.appIdentifier, "com.test.app1", "All sessions should be for app1")
        }
    }
    
    func testFetchByDateRange() throws {
        // Given: Sessions on different dates
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todaySession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            startTime: today,
            in: testContext
        )
        
        let yesterdaySession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            startTime: yesterday,
            in: testContext
        )
        
        let tomorrowSession = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            startTime: tomorrow,
            in: testContext
        )
        
        try testContext.save()
        
        // When: Fetching sessions for today
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", 
                                      startOfDay as NSDate, endOfDay as NSDate)
        let todaySessions = try testContext.fetch(request)
        
        // Then: Should return only today's sessions
        XCTAssertEqual(todaySessions.count, 1, "Should have 1 session for today")
        XCTAssertTrue(calendar.isDate(todaySessions.first!.startTime, inSameDayAs: today), "Session should be from today")
    }
    
    func testFetchBySceneTag() throws {
        // Given: Sessions with different scene tags
        let workSession = AppUsageSession.createSession(
            appIdentifier: "com.test.work",
            appName: "Work App",
            in: testContext
        )
        workSession.sceneTag = "工作"
        
        let entertainmentSession = AppUsageSession.createSession(
            appIdentifier: "com.test.entertainment",
            appName: "Entertainment App",
            in: testContext
        )
        entertainmentSession.sceneTag = "娱乐"
        
        let untaggedSession = AppUsageSession.createSession(
            appIdentifier: "com.test.untagged",
            appName: "Untagged App",
            in: testContext
        )
        untaggedSession.sceneTag = nil
        
        try testContext.save()
        
        // When: Fetching sessions with work tag
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "sceneTag == %@", "工作")
        let workSessions = try testContext.fetch(request)
        
        // Then: Should return only work sessions
        XCTAssertEqual(workSessions.count, 1, "Should have 1 work session")
        XCTAssertEqual(workSessions.first?.sceneTag, "工作", "Session should have work tag")
        
        // When: Fetching sessions with any tag
        let taggedRequest: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        taggedRequest.predicate = NSPredicate(format: "sceneTag != nil")
        let taggedSessions = try testContext.fetch(taggedRequest)
        
        // Then: Should return tagged sessions only
        XCTAssertEqual(taggedSessions.count, 2, "Should have 2 tagged sessions")
    }
    
    // MARK: - Performance Tests
    
    func testCreateSessionPerformance() throws {
        measure {
            for i in 0..<1000 {
                let session = AppUsageSession.createSession(
                    appIdentifier: "com.test.app\(i)",
                    appName: "Test App \(i)",
                    categoryIdentifier: "productivity",
                    in: testContext
                )
                session.duration = TimeInterval(i * 60)
                session.updateProductivityStatus()
            }
        }
    }
    
    func testFormattedDurationPerformance() throws {
        // Given: Many sessions
        var sessions: [AppUsageSession] = []
        for i in 0..<1000 {
            let session = AppUsageSession.createSession(
                appIdentifier: "com.test.app\(i)",
                appName: "Test App \(i)",
                in: testContext
            )
            session.duration = TimeInterval(i * 60)
            sessions.append(session)
        }
        
        // When: Getting formatted duration for all sessions
        measure {
            for session in sessions {
                _ = session.formattedDuration
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testNegativeDuration() throws {
        // Given: Session with negative duration
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        session.duration = -100
        
        // When: Getting formatted duration
        let formatted = session.formattedDuration
        
        // Then: Should handle gracefully
        XCTAssertTrue(formatted.contains("-") || formatted == "0s", "Should handle negative duration gracefully")
    }
    
    func testVeryLargeDuration() throws {
        // Given: Session with very large duration
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        session.duration = 24 * 3600 + 3600 + 60 + 30 // 25 hours, 1 minute, 30 seconds
        
        // When: Getting formatted duration
        let formatted = session.formattedDuration
        
        // Then: Should format correctly
        XCTAssertEqual(formatted, "25h 1m", "Should format large duration correctly")
    }
    
    func testEmptyAppIdentifier() throws {
        // Given: Session with empty app identifier
        let session = AppUsageSession.createSession(
            appIdentifier: "",
            appName: "Test App",
            in: testContext
        )
        
        // When: Session is created
        // Then: Should not crash and should store empty identifier
        XCTAssertEqual(session.appIdentifier, "", "Should store empty identifier")
        XCTAssertEqual(session.appName, "Test App", "App name should still be set")
    }
    
    func testEmptyAppName() throws {
        // Given: Session with empty app name
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "",
            in: testContext
        )
        
        // When: Session is created
        // Then: Should not crash and should store empty name
        XCTAssertEqual(session.appIdentifier, "com.test.app", "App identifier should be set")
        XCTAssertEqual(session.appName, "", "Should store empty name")
    }
}