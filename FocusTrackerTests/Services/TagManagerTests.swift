import XCTest
import CoreData
@testable import FocusTracker

class TagManagerTests: XCTestCase {
    
    var testContext: NSManagedObjectContext!
    var tagManager: TagManager!
    
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
        tagManager = TagManager(viewContext: testContext)
    }
    
    override func tearDownWithError() throws {
        testContext = nil
        tagManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Default Tags Tests
    
    func testGetDefaultTags() throws {
        // When: Getting default tags
        let defaultTags = tagManager.getDefaultTags()
        
        // Then: Should have 7 default tags
        XCTAssertEqual(defaultTags.count, 7, "Should have 7 default tags")
        
        let expectedTagNames = ["工作", "学习", "娱乐", "社交", "健康", "购物", "出行"]
        let actualTagNames = defaultTags.map { $0.name }
        
        for expectedName in expectedTagNames {
            XCTAssertTrue(actualTagNames.contains(expectedName), "Should contain tag: \(expectedName)")
        }
        
        // All default tags should be marked as default
        for tag in defaultTags {
            XCTAssertTrue(tag.isDefault, "Tag \(tag.name) should be marked as default")
        }
    }
    
    func testDefaultTagsInitialization() throws {
        // Given: Fresh TagManager
        // When: TagManager is initialized
        // Then: Default tags should be available
        XCTAssertTrue(tagManager.isInitialized, "TagManager should be initialized")
        XCTAssertEqual(tagManager.defaultTags.count, 7, "Should have 7 default tags")
        XCTAssertEqual(tagManager.availableTags.count, 7, "Should have 7 available tags initially")
        XCTAssertEqual(tagManager.customTags.count, 0, "Should have no custom tags initially")
    }
    
    // MARK: - Custom Tags Tests
    
    func testCreateCustomTag() throws {
        // Given: Tag name and color
        let tagName = "测试标签"
        let tagColor = "#FF0000"
        
        // When: Creating custom tag
        let customTag = tagManager.createCustomTag(name: tagName, color: tagColor)
        
        // Then: Tag should be created successfully
        XCTAssertNotNil(customTag, "Custom tag should be created")
        XCTAssertEqual(customTag?.name, tagName, "Tag name should match")
        XCTAssertEqual(customTag?.color, tagColor, "Tag color should match")
        XCTAssertFalse(customTag?.isDefault ?? true, "Custom tag should not be default")
        
        // Should be added to custom tags and available tags
        XCTAssertEqual(tagManager.customTags.count, 1, "Should have 1 custom tag")
        XCTAssertEqual(tagManager.availableTags.count, 8, "Should have 8 total tags")
    }
    
    func testCreateDuplicateCustomTag() throws {
        // Given: Existing tag name
        let tagName = "工作" // Same as default tag
        let tagColor = "#FF0000"
        
        // When: Trying to create duplicate tag
        let duplicateTag = tagManager.createCustomTag(name: tagName, color: tagColor)
        
        // Then: Should return nil
        XCTAssertNil(duplicateTag, "Duplicate tag should not be created")
        XCTAssertEqual(tagManager.customTags.count, 0, "Should have no custom tags")
    }
    
    func testDeleteCustomTag() throws {
        // Given: Custom tag
        let customTag = tagManager.createCustomTag(name: "测试标签", color: "#FF0000")!
        XCTAssertEqual(tagManager.customTags.count, 1, "Should have 1 custom tag")
        
        // When: Deleting custom tag
        let success = tagManager.deleteTag(customTag)
        
        // Then: Should be deleted successfully
        XCTAssertTrue(success, "Custom tag should be deleted successfully")
        XCTAssertEqual(tagManager.customTags.count, 0, "Should have no custom tags")
        XCTAssertEqual(tagManager.availableTags.count, 7, "Should have 7 available tags")
    }
    
    func testDeleteDefaultTag() throws {
        // Given: Default tag
        let defaultTag = tagManager.getDefaultTags().first!
        
        // When: Trying to delete default tag
        let success = tagManager.deleteTag(defaultTag)
        
        // Then: Should fail
        XCTAssertFalse(success, "Default tag should not be deleted")
        XCTAssertEqual(tagManager.defaultTags.count, 7, "Should still have 7 default tags")
    }
    
    // MARK: - Tag Recommendation Tests
    
    func testSuggestTagForKnownApp() throws {
        // Given: Known app identifier
        let appIdentifier = "com.microsoft.Office.Word"
        
        // When: Getting tag suggestion
        let recommendation = tagManager.suggestTagForApp(appIdentifier)
        
        // Then: Should recommend work tag
        XCTAssertNotNil(recommendation, "Should provide recommendation")
        XCTAssertEqual(recommendation?.tag.name, "工作", "Should recommend work tag")
        XCTAssertEqual(recommendation?.confidence, 0.9, "Should have high confidence")
        XCTAssertEqual(recommendation?.reason, "基于应用类型的精确匹配", "Should have correct reason")
    }
    
    func testSuggestTagForUnknownApp() throws {
        // Given: Unknown app identifier
        let appIdentifier = "com.unknown.app"
        
        // When: Getting tag suggestion
        let recommendation = tagManager.suggestTagForApp(appIdentifier)
        
        // Then: Should return nil or low confidence recommendation
        if let rec = recommendation {
            XCTAssertLessThan(rec.confidence, 0.8, "Should have lower confidence for unknown app")
        }
    }
    
    func testSuggestTagForPreviouslyTaggedApp() throws {
        // Given: App usage session with tag
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        tagManager.updateTagForSession(session, tag: workTag)
        
        // When: Getting tag suggestion for same app
        let recommendation = tagManager.suggestTagForApp("com.test.app")
        
        // Then: Should recommend the same tag with high confidence
        XCTAssertNotNil(recommendation, "Should provide recommendation")
        XCTAssertEqual(recommendation?.tag.name, "工作", "Should recommend same tag")
        XCTAssertEqual(recommendation?.confidence, 1.0, "Should have maximum confidence")
        XCTAssertEqual(recommendation?.reason, "之前已关联此标签", "Should have correct reason")
    }
    
    func testGetMultipleTagRecommendations() throws {
        // Given: App identifier
        let appIdentifier = "com.microsoft.Office.Word"
        
        // When: Getting multiple recommendations
        let recommendations = tagManager.getTagRecommendations(appIdentifier, limit: 3)
        
        // Then: Should return recommendations sorted by confidence
        XCTAssertFalse(recommendations.isEmpty, "Should have recommendations")
        XCTAssertLessThanOrEqual(recommendations.count, 3, "Should not exceed limit")
        
        // Should be sorted by confidence (descending)
        for i in 1..<recommendations.count {
            XCTAssertGreaterThanOrEqual(recommendations[i-1].confidence, recommendations[i].confidence,
                                       "Recommendations should be sorted by confidence")
        }
    }
    
    // MARK: - Tag Application Tests
    
    func testUpdateTagForSession() throws {
        // Given: App usage session and tag
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        
        // When: Updating tag for session
        tagManager.updateTagForSession(session, tag: workTag)
        
        // Then: Session should have the tag
        XCTAssertEqual(session.sceneTag, "工作", "Session should have work tag")
        
        // Tag should have the app associated
        XCTAssertTrue(workTag.isAppAssociated("com.test.app"), "Tag should have app associated")
        
        // Usage count should be incremented
        XCTAssertEqual(workTag.usageCount, 1, "Tag usage count should be incremented")
    }
    
    func testApplyTagToSession() throws {
        // Given: App usage session and tag
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        
        // When: Applying tag to session with user confirmation
        tagManager.applyTagToSession(session, tag: workTag, userConfirmed: true)
        
        // Then: Session should have the tag
        XCTAssertEqual(session.sceneTag, "工作", "Session should have work tag")
        
        // Tag should learn from user choice
        XCTAssertTrue(workTag.isAppAssociated("com.test.app"), "Tag should learn app association")
    }
    
    func testApplyTagToMultipleSessions() throws {
        // Given: Multiple app usage sessions
        let session1 = AppUsageSession.createSession(
            appIdentifier: "com.test.app1",
            appName: "Test App 1",
            in: testContext
        )
        let session2 = AppUsageSession.createSession(
            appIdentifier: "com.test.app2",
            appName: "Test App 2",
            in: testContext
        )
        let sessions = [session1, session2]
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        
        // When: Applying tag to multiple sessions
        tagManager.applyTagToSessions(sessions, tag: workTag)
        
        // Then: All sessions should have the tag
        XCTAssertEqual(session1.sceneTag, "工作", "Session 1 should have work tag")
        XCTAssertEqual(session2.sceneTag, "工作", "Session 2 should have work tag")
        
        // Tag should have both apps associated
        XCTAssertTrue(workTag.isAppAssociated("com.test.app1"), "Tag should have app1 associated")
        XCTAssertTrue(workTag.isAppAssociated("com.test.app2"), "Tag should have app2 associated")
        
        // Usage count should be incremented by number of sessions
        XCTAssertEqual(workTag.usageCount, 2, "Tag usage count should be incremented by 2")
    }
    
    func testRemoveTagFromSession() throws {
        // Given: Tagged session
        let session = AppUsageSession.createSession(
            appIdentifier: "com.test.app",
            appName: "Test App",
            in: testContext
        )
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        tagManager.updateTagForSession(session, tag: workTag)
        
        XCTAssertEqual(session.sceneTag, "工作", "Session should initially have work tag")
        
        // When: Removing tag from session
        tagManager.removeTagFromSession(session)
        
        // Then: Session should not have tag
        XCTAssertNil(session.sceneTag, "Session should not have tag")
    }
    
    // MARK: - Tag Distribution Tests
    
    func testGetTagDistribution() throws {
        // Given: Sessions with different tags
        let today = Date()
        
        let session1 = AppUsageSession.createSession(
            appIdentifier: "com.test.app1",
            appName: "Test App 1",
            startTime: today,
            in: testContext
        )
        session1.duration = 30 * 60 // 30 minutes
        session1.endTime = today.addingTimeInterval(30 * 60)
        
        let session2 = AppUsageSession.createSession(
            appIdentifier: "com.test.app2",
            appName: "Test App 2",
            startTime: today,
            in: testContext
        )
        session2.duration = 60 * 60 // 60 minutes
        session2.endTime = today.addingTimeInterval(60 * 60)
        
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        let entertainmentTag = tagManager.getDefaultTags().first { $0.name == "娱乐" }!
        
        tagManager.updateTagForSession(session1, tag: workTag)
        tagManager.updateTagForSession(session2, tag: entertainmentTag)
        
        try testContext.save()
        
        // When: Getting tag distribution for today
        let distribution = tagManager.getTagDistribution(for: today)
        
        // Then: Should have correct distribution
        XCTAssertEqual(distribution.count, 2, "Should have 2 tag distributions")
        
        let entertainmentDist = distribution.first { $0.tagName == "娱乐" }
        let workDist = distribution.first { $0.tagName == "工作" }
        
        XCTAssertNotNil(entertainmentDist, "Should have entertainment distribution")
        XCTAssertNotNil(workDist, "Should have work distribution")
        
        XCTAssertEqual(entertainmentDist?.usageTime, 60 * 60, "Entertainment should have 60 minutes")
        XCTAssertEqual(workDist?.usageTime, 30 * 60, "Work should have 30 minutes")
        
        // Entertainment should have higher percentage (60 out of 90 minutes)
        XCTAssertEqual(entertainmentDist?.percentage ?? 0, 66.67, accuracy: 0.1, "Entertainment should be ~66.67%")
        XCTAssertEqual(workDist?.percentage ?? 0, 33.33, accuracy: 0.1, "Work should be ~33.33%")
        
        // Should be sorted by usage time (descending)
        XCTAssertEqual(distribution[0].tagName, "娱乐", "Entertainment should be first (highest usage)")
        XCTAssertEqual(distribution[1].tagName, "工作", "Work should be second")
    }
    
    func testGetTagTrends() throws {
        // Given: Sessions across multiple days
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Yesterday's session
        let session1 = AppUsageSession.createSession(
            appIdentifier: "com.test.app1",
            appName: "Test App 1",
            startTime: yesterday,
            in: testContext
        )
        session1.duration = 30 * 60
        session1.endTime = yesterday.addingTimeInterval(30 * 60)
        
        // Today's session
        let session2 = AppUsageSession.createSession(
            appIdentifier: "com.test.app2",
            appName: "Test App 2",
            startTime: today,
            in: testContext
        )
        session2.duration = 45 * 60
        session2.endTime = today.addingTimeInterval(45 * 60)
        
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        tagManager.updateTagForSession(session1, tag: workTag)
        tagManager.updateTagForSession(session2, tag: workTag)
        
        try testContext.save()
        
        // When: Getting tag trends for 2-day period
        let period = DateInterval(start: yesterday, end: calendar.date(byAdding: .day, value: 1, to: today)!)
        let trends = tagManager.getTagTrends(for: period)
        
        // Then: Should have trends for both days
        XCTAssertEqual(trends.count, 2, "Should have trends for 2 days")
        
        let yesterdayTrend = trends.first { calendar.isDate($0.date, inSameDayAs: yesterday) }
        let todayTrend = trends.first { calendar.isDate($0.date, inSameDayAs: today) }
        
        XCTAssertNotNil(yesterdayTrend, "Should have yesterday's trend")
        XCTAssertNotNil(todayTrend, "Should have today's trend")
        
        XCTAssertEqual(yesterdayTrend?.tagName, "工作", "Yesterday's trend should be for work tag")
        XCTAssertEqual(todayTrend?.tagName, "工作", "Today's trend should be for work tag")
        
        XCTAssertEqual(yesterdayTrend?.usageTime, 30 * 60, "Yesterday should have 30 minutes")
        XCTAssertEqual(todayTrend?.usageTime, 45 * 60, "Today should have 45 minutes")
        
        XCTAssertEqual(yesterdayTrend?.sessionCount, 1, "Yesterday should have 1 session")
        XCTAssertEqual(todayTrend?.sessionCount, 1, "Today should have 1 session")
        
        // Should be sorted by date
        XCTAssertTrue(trends[0].date <= trends[1].date, "Trends should be sorted by date")
    }
    
    // MARK: - Tag Management Tests
    
    func testGetAllTags() throws {
        // Given: Default tags and custom tag
        _ = tagManager.createCustomTag(name: "测试标签", color: "#FF0000")!
        
        // When: Getting all tags
        let allTags = tagManager.getAllTags()
        
        // Then: Should include both default and custom tags
        XCTAssertEqual(allTags.count, 8, "Should have 8 total tags")
        
        let tagNames = allTags.map { $0.name }
        XCTAssertTrue(tagNames.contains("工作"), "Should contain work tag")
        XCTAssertTrue(tagNames.contains("测试标签"), "Should contain custom tag")
    }
    
    // MARK: - Performance Tests
    
    func testTagRecommendationPerformance() throws {
        // Given: Multiple app identifiers
        let appIdentifiers = [
            "com.microsoft.Office.Word",
            "com.netflix.Netflix",
            "com.tencent.xin",
            "com.apple.Health",
            "com.taobao.taobao4iphone"
        ]
        
        // When: Getting recommendations for multiple apps
        measure {
            for appId in appIdentifiers {
                _ = tagManager.suggestTagForApp(appId)
            }
        }
    }
    
    func testTagDistributionPerformance() throws {
        // Given: Many sessions
        let today = Date()
        let workTag = tagManager.getDefaultTags().first { $0.name == "工作" }!
        
        for i in 0..<100 {
            let session = AppUsageSession.createSession(
                appIdentifier: "com.test.app\(i)",
                appName: "Test App \(i)",
                startTime: today,
                in: testContext
            )
            session.duration = TimeInterval(i * 60) // Variable duration
            session.endTime = today.addingTimeInterval(TimeInterval(i * 60))
            tagManager.updateTagForSession(session, tag: workTag)
        }
        
        try testContext.save()
        
        // When: Getting tag distribution
        measure {
            _ = tagManager.getTagDistribution(for: today)
        }
    }
}