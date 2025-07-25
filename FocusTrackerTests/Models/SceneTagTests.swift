import XCTest
import CoreData
import SwiftUI
@testable import FocusTracker

class SceneTagTests: XCTestCase {
    
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
    
    func testCreateTag() throws {
        // Given: Tag parameters
        let name = "测试标签"
        let color = "#FF0000"
        let isDefault = false
        
        // When: Creating tag
        let tag = SceneTag.createTag(
            name: name,
            color: color,
            isDefault: isDefault,
            in: testContext
        )
        
        // Then: Tag should be created with correct properties
        XCTAssertEqual(tag.name, name, "Tag name should match")
        XCTAssertEqual(tag.color, color, "Tag color should match")
        XCTAssertEqual(tag.isDefault, isDefault, "Default flag should match")
        XCTAssertNotNil(tag.tagID, "Tag ID should be generated")
        XCTAssertNotNil(tag.createdAt, "Created date should be set")
        XCTAssertEqual(tag.usageCount, 0, "Usage count should be 0 initially")
        XCTAssertTrue(tag.associatedAppsSet.isEmpty, "Associated apps should be empty initially")
    }
    
    func testCreateTagWithDefaults() throws {
        // Given: Minimal parameters
        let name = "默认标签"
        
        // When: Creating tag with defaults
        let tag = SceneTag.createTag(name: name, in: testContext)
        
        // Then: Should use default values
        XCTAssertEqual(tag.name, name, "Tag name should match")
        XCTAssertEqual(tag.color, "#007AFF", "Should use default color")
        XCTAssertFalse(tag.isDefault, "Should not be default by default")
        XCTAssertNotNil(tag.tagID, "Tag ID should be generated")
        XCTAssertNotNil(tag.createdAt, "Created date should be set")
    }
    
    func testCreateDefaultTags() throws {
        // When: Creating default tags
        let defaultTags = SceneTag.createDefaultTags(in: testContext)
        
        // Then: Should create 7 default tags
        XCTAssertEqual(defaultTags.count, 7, "Should create 7 default tags")
        
        let expectedTags = [
            ("工作", "#007AFF"),
            ("学习", "#34C759"),
            ("娱乐", "#FF9500"),
            ("社交", "#FF2D92"),
            ("健康", "#30D158"),
            ("购物", "#AC39FF"),
            ("出行", "#64D2FF")
        ]
        
        for (index, (expectedName, expectedColor)) in expectedTags.enumerated() {
            let tag = defaultTags[index]
            XCTAssertEqual(tag.name, expectedName, "Tag \(index) name should be \(expectedName)")
            XCTAssertEqual(tag.color, expectedColor, "Tag \(index) color should be \(expectedColor)")
            XCTAssertTrue(tag.isDefault, "Tag \(index) should be marked as default")
        }
    }
    
    // MARK: - Computed Properties Tests
    
    func testSwiftUIColor() throws {
        // Given: Tag with different colors
        let tag = SceneTag.createTag(name: "测试", in: testContext)
        
        // Test valid hex color
        tag.color = "#FF0000"
        let redColor = tag.swiftUIColor
        XCTAssertNotNil(redColor, "Should create SwiftUI color from valid hex")
        
        // Test invalid hex color (should fallback to blue)
        tag.color = "invalid"
        let fallbackColor = tag.swiftUIColor
        XCTAssertNotNil(fallbackColor, "Should fallback to blue for invalid hex")
        
        // Test different hex formats
        tag.color = "#00FF00"
        let greenColor = tag.swiftUIColor
        XCTAssertNotNil(greenColor, "Should handle 6-digit hex")
        
        tag.color = "#0F0"
        let shortGreenColor = tag.swiftUIColor
        XCTAssertNotNil(shortGreenColor, "Should handle 3-digit hex")
    }
    
    func testTotalUsageTime() throws {
        // Given: Tag and usage sessions
        let tag = SceneTag.createTag(name: "工作", in: testContext)
        
        // Create usage sessions with this tag
        let session1 = AppUsageSession.createSession(
            appIdentifier: "com.test.app1",
            appName: "Test App 1",
            in: testContext
        )
        session1.duration = 30 * 60 // 30 minutes
        session1.sceneTag = tag.name
        
        let session2 = AppUsageSession.createSession(
            appIdentifier: "com.test.app2",
            appName: "Test App 2",
            in: testContext
        )
        session2.duration = 45 * 60 // 45 minutes
        session2.sceneTag = tag.name
        
        // Create session with different tag
        let session3 = AppUsageSession.createSession(
            appIdentifier: "com.test.app3",
            appName: "Test App 3",
            in: testContext
        )
        session3.duration = 20 * 60 // 20 minutes
        session3.sceneTag = "娱乐"
        
        try testContext.save()
        
        // When: Getting total usage time
        let totalTime = tag.totalUsageTime(in: testContext)
        
        // Then: Should return sum of sessions with this tag
        XCTAssertEqual(totalTime, 75 * 60, "Total usage time should be 75 minutes")
    }
    
    func testFormattedTotalUsageTime() throws {
        // Given: Tag and usage sessions
        let tag = SceneTag.createTag(name: "工作", in: testContext)
        
        // Test hours and minutes
        let session1 = AppUsageSession.createSession(
            appIdentifier: "com.test.app1",
            appName: "Test App 1",
            in: testContext
        )
        session1.duration = 90 * 60 // 1 hour 30 minutes
        session1.sceneTag = tag.name
        
        try testContext.save()
        
        let formatted1 = tag.formattedTotalUsageTime(in: testContext)
        XCTAssertEqual(formatted1, "1h 30m", "Should format 90 minutes as '1h 30m'")
        
        // Test minutes only
        let session2 = AppUsageSession.createSession(
            appIdentifier: "com.test.app2",
            appName: "Test App 2",
            in: testContext
        )
        session2.duration = 15 * 60 // 15 minutes
        session2.sceneTag = tag.name
        
        try testContext.save()
        
        let formatted2 = tag.formattedTotalUsageTime(in: testContext)
        XCTAssertEqual(formatted2, "1h 45m", "Should format 105 minutes as '1h 45m'")
    }
    
    func testSessionCount() throws {
        // Given: Tag and usage sessions
        let tag = SceneTag.createTag(name: "工作", in: testContext)
        
        // Initially no sessions
        XCTAssertEqual(tag.sessionCount(in: testContext), 0, "Initial session count should be 0")
        
        // Create sessions with this tag
        let session1 = AppUsageSession.createSession(
            appIdentifier: "com.test.app1",
            appName: "Test App 1",
            in: testContext
        )
        session1.sceneTag = tag.name
        
        let session2 = AppUsageSession.createSession(
            appIdentifier: "com.test.app2",
            appName: "Test App 2",
            in: testContext
        )
        session2.sceneTag = tag.name
        
        // Create session with different tag
        let session3 = AppUsageSession.createSession(
            appIdentifier: "com.test.app3",
            appName: "Test App 3",
            in: testContext
        )
        session3.sceneTag = "娱乐"
        
        try testContext.save()
        
        // When: Getting session count
        let count = tag.sessionCount(in: testContext)
        
        // Then: Should return count of sessions with this tag
        XCTAssertEqual(count, 2, "Session count should be 2")
    }
    
    // MARK: - Associated Apps Tests
    
    func testAssociatedAppsSet() throws {
        // Given: Tag
        let tag = SceneTag.createTag(name: "工作", in: testContext)
        
        // Initially empty
        XCTAssertTrue(tag.associatedAppsSet.isEmpty, "Associated apps should be empty initially")
        
        // When: Setting associated apps
        let apps = Set(["com.test.app1", "com.test.app2", "com.test.app3"])
        tag.associatedAppsSet = apps
        
        // Then: Should store and retrieve correctly
        XCTAssertEqual(tag.associatedAppsSet, apps, "Associated apps should match")
        
        // When: Setting empty set
        tag.associatedAppsSet = Set<String>()
        
        // Then: Should be empty
        XCTAssertTrue(tag.associatedAppsSet.isEmpty, "Associated apps should be empty")
        XCTAssertNil(tag.associatedApps, "Associated apps string should be nil")
    }
    
    func testAddAssociatedApp() throws {
        // Given: Tag
        let tag = SceneTag.createTag(name: "工作", in: testContext)
        
        // When: Adding apps
        tag.addAssociatedApp("com.test.app1")
        XCTAssertTrue(tag.associatedAppsSet.contains("com.test.app1"), "Should contain app1")
        XCTAssertEqual(tag.associatedAppsSet.count, 1, "Should have 1 app")
        
        tag.addAssociatedApp("com.test.app2")
        XCTAssertTrue(tag.associatedAppsSet.contains("com.test.app2"), "Should contain app2")
        XCTAssertEqual(tag.associatedAppsSet.count, 2, "Should have 2 apps")
        
        // Adding duplicate should not increase count
        tag.addAssociatedApp("com.test.app1")
        XCTAssertEqual(tag.associatedAppsSet.count, 2, "Should still have 2 apps")
    }
    
    func testRemoveAssociatedApp() throws {
        // Given: Tag with associated apps
        let tag = SceneTag.createTag(name: "工作", in: testContext)
        tag.addAssociatedApp("com.test.app1")
        tag.addAssociatedApp("com.test.app2")
        tag.addAssociatedApp("com.test.app3")
        
        XCTAssertEqual(tag.associatedAppsSet.count, 3, "Should have 3 apps initially")
        
        // When: Removing app
        tag.removeAssociatedApp("com.test.app2")
        
        // Then: Should be removed
        XCTAssertFalse(tag.associatedAppsSet.contains("com.test.app2"), "Should not contain app2")
        XCTAssertEqual(tag.associatedAppsSet.count, 2, "Should have 2 apps")
        XCTAssertTrue(tag.associatedAppsSet.contains("com.test.app1"), "Should still contain app1")
        XCTAssertTrue(tag.associatedAppsSet.contains("com.test.app3"), "Should still contain app3")
        
        // Removing non-existent app should not cause issues
        tag.removeAssociatedApp("com.nonexistent.app")
        XCTAssertEqual(tag.associatedAppsSet.count, 2, "Should still have 2 apps")
    }
    
    func testIsAppAssociated() throws {
        // Given: Tag with associated apps
        let tag = SceneTag.createTag(name: "工作", in: testContext)
        tag.addAssociatedApp("com.test.app1")
        tag.addAssociatedApp("com.test.app2")
        
        // When: Checking association
        // Then: Should return correct results
        XCTAssertTrue(tag.isAppAssociated("com.test.app1"), "Should be associated with app1")
        XCTAssertTrue(tag.isAppAssociated("com.test.app2"), "Should be associated with app2")
        XCTAssertFalse(tag.isAppAssociated("com.test.app3"), "Should not be associated with app3")
        XCTAssertFalse(tag.isAppAssociated(""), "Should not be associated with empty string")
    }
    
    // MARK: - Usage Count Tests
    
    func testIncrementUsageCount() throws {
        // Given: Tag
        let tag = SceneTag.createTag(name: "工作", in: testContext)
        
        XCTAssertEqual(tag.usageCount, 0, "Initial usage count should be 0")
        
        // When: Incrementing usage count
        tag.incrementUsageCount()
        XCTAssertEqual(tag.usageCount, 1, "Usage count should be 1")
        
        tag.incrementUsageCount()
        XCTAssertEqual(tag.usageCount, 2, "Usage count should be 2")
        
        tag.incrementUsageCount()
        XCTAssertEqual(tag.usageCount, 3, "Usage count should be 3")
    }
    
    // MARK: - Suggested Apps Tests
    
    func testGetSuggestedApps() throws {
        // Test work tag suggestions
        let workTag = SceneTag.createTag(name: "工作", in: testContext)
        let workSuggestions = workTag.getSuggestedApps()
        XCTAssertFalse(workSuggestions.isEmpty, "Work tag should have suggestions")
        XCTAssertTrue(workSuggestions.contains("com.microsoft.Office.Word"), "Should suggest Word")
        XCTAssertTrue(workSuggestions.contains("com.apple.mail"), "Should suggest Mail")
        
        // Test study tag suggestions
        let studyTag = SceneTag.createTag(name: "学习", in: testContext)
        let studySuggestions = studyTag.getSuggestedApps()
        XCTAssertFalse(studySuggestions.isEmpty, "Study tag should have suggestions")
        XCTAssertTrue(studySuggestions.contains("com.apple.iBooks"), "Should suggest iBooks")
        XCTAssertTrue(studySuggestions.contains("com.duolingo.DuolingoMobile"), "Should suggest Duolingo")
        
        // Test entertainment tag suggestions
        let entertainmentTag = SceneTag.createTag(name: "娱乐", in: testContext)
        let entertainmentSuggestions = entertainmentTag.getSuggestedApps()
        XCTAssertFalse(entertainmentSuggestions.isEmpty, "Entertainment tag should have suggestions")
        XCTAssertTrue(entertainmentSuggestions.contains("com.netflix.Netflix"), "Should suggest Netflix")
        XCTAssertTrue(entertainmentSuggestions.contains("com.tencent.QQMusic"), "Should suggest QQ Music")
        
        // Test social tag suggestions
        let socialTag = SceneTag.createTag(name: "社交", in: testContext)
        let socialSuggestions = socialTag.getSuggestedApps()
        XCTAssertFalse(socialSuggestions.isEmpty, "Social tag should have suggestions")
        XCTAssertTrue(socialSuggestions.contains("com.tencent.xin"), "Should suggest WeChat")
        XCTAssertTrue(socialSuggestions.contains("com.sina.weibo"), "Should suggest Weibo")
        
        // Test health tag suggestions
        let healthTag = SceneTag.createTag(name: "健康", in: testContext)
        let healthSuggestions = healthTag.getSuggestedApps()
        XCTAssertFalse(healthSuggestions.isEmpty, "Health tag should have suggestions")
        XCTAssertTrue(healthSuggestions.contains("com.apple.Health"), "Should suggest Health")
        XCTAssertTrue(healthSuggestions.contains("com.nike.nikeplus-gps"), "Should suggest Nike")
        
        // Test shopping tag suggestions
        let shoppingTag = SceneTag.createTag(name: "购物", in: testContext)
        let shoppingSuggestions = shoppingTag.getSuggestedApps()
        XCTAssertFalse(shoppingSuggestions.isEmpty, "Shopping tag should have suggestions")
        XCTAssertTrue(shoppingSuggestions.contains("com.taobao.taobao4iphone"), "Should suggest Taobao")
        XCTAssertTrue(shoppingSuggestions.contains("com.apple.AppStore"), "Should suggest App Store")
        
        // Test travel tag suggestions
        let travelTag = SceneTag.createTag(name: "出行", in: testContext)
        let travelSuggestions = travelTag.getSuggestedApps()
        XCTAssertFalse(travelSuggestions.isEmpty, "Travel tag should have suggestions")
        XCTAssertTrue(travelSuggestions.contains("com.autonavi.amap"), "Should suggest Amap")
        XCTAssertTrue(travelSuggestions.contains("com.didi.passenger"), "Should suggest Didi")
        
        // Test unknown tag (should return empty)
        let unknownTag = SceneTag.createTag(name: "未知标签", in: testContext)
        let unknownSuggestions = unknownTag.getSuggestedApps()
        XCTAssertTrue(unknownSuggestions.isEmpty, "Unknown tag should have no suggestions")
    }
    
    // MARK: - Core Data Persistence Tests
    
    func testPersistence() throws {
        // Given: Tag
        let tag = SceneTag.createTag(
            name: "测试标签",
            color: "#FF0000",
            isDefault: false,
            in: testContext
        )
        tag.usageCount = 5
        tag.addAssociatedApp("com.test.app1")
        tag.addAssociatedApp("com.test.app2")
        
        // When: Saving to Core Data
        try testContext.save()
        
        // Then: Tag should be persisted
        let request: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        let tags = try testContext.fetch(request)
        
        XCTAssertEqual(tags.count, 1, "Should have one persisted tag")
        
        let persistedTag = tags.first!
        XCTAssertEqual(persistedTag.name, "测试标签", "Name should be persisted")
        XCTAssertEqual(persistedTag.color, "#FF0000", "Color should be persisted")
        XCTAssertFalse(persistedTag.isDefault, "Default flag should be persisted")
        XCTAssertEqual(persistedTag.usageCount, 5, "Usage count should be persisted")
        XCTAssertEqual(persistedTag.associatedAppsSet.count, 2, "Associated apps should be persisted")
        XCTAssertTrue(persistedTag.associatedAppsSet.contains("com.test.app1"), "Should contain app1")
        XCTAssertTrue(persistedTag.associatedAppsSet.contains("com.test.app2"), "Should contain app2")
    }
    
    func testFetchByDefault() throws {
        // Given: Mix of default and custom tags
        let defaultTag = SceneTag.createTag(name: "默认标签", color: "#007AFF", isDefault: true, in: testContext)
        let customTag = SceneTag.createTag(name: "自定义标签", color: "#FF0000", isDefault: false, in: testContext)
        
        try testContext.save()
        
        // When: Fetching default tags
        let defaultRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        defaultRequest.predicate = NSPredicate(format: "isDefault == YES")
        let defaultTags = try testContext.fetch(defaultRequest)
        
        // Then: Should return only default tags
        XCTAssertEqual(defaultTags.count, 1, "Should have 1 default tag")
        XCTAssertEqual(defaultTags.first?.name, "默认标签", "Should be the default tag")
        
        // When: Fetching custom tags
        let customRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        customRequest.predicate = NSPredicate(format: "isDefault == NO")
        let customTags = try testContext.fetch(customRequest)
        
        // Then: Should return only custom tags
        XCTAssertEqual(customTags.count, 1, "Should have 1 custom tag")
        XCTAssertEqual(customTags.first?.name, "自定义标签", "Should be the custom tag")
    }
    
    func testFetchSortedByUsage() throws {
        // Given: Tags with different usage counts
        let tag1 = SceneTag.createTag(name: "标签1", in: testContext)
        tag1.usageCount = 10
        
        let tag2 = SceneTag.createTag(name: "标签2", in: testContext)
        tag2.usageCount = 25
        
        let tag3 = SceneTag.createTag(name: "标签3", in: testContext)
        tag3.usageCount = 5
        
        try testContext.save()
        
        // When: Fetching tags sorted by usage count
        let request: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SceneTag.usageCount, ascending: false)]
        let sortedTags = try testContext.fetch(request)
        
        // Then: Should be sorted by usage count (descending)
        XCTAssertEqual(sortedTags.count, 3, "Should have 3 tags")
        XCTAssertEqual(sortedTags[0].name, "标签2", "Most used tag should be first")
        XCTAssertEqual(sortedTags[1].name, "标签1", "Second most used tag should be second")
        XCTAssertEqual(sortedTags[2].name, "标签3", "Least used tag should be last")
    }
    
    // MARK: - Color Extension Tests
    
    func testColorExtension() throws {
        // Test 6-digit hex
        let color1 = Color(hex: "#FF0000")
        XCTAssertNotNil(color1, "Should create color from 6-digit hex")
        
        // Test 3-digit hex
        let color2 = Color(hex: "#F00")
        XCTAssertNotNil(color2, "Should create color from 3-digit hex")
        
        // Test 8-digit hex (with alpha)
        let color3 = Color(hex: "#FF0000FF")
        XCTAssertNotNil(color3, "Should create color from 8-digit hex")
        
        // Test without # prefix
        let color4 = Color(hex: "FF0000")
        XCTAssertNotNil(color4, "Should create color without # prefix")
        
        // Test invalid hex
        let color5 = Color(hex: "invalid")
        XCTAssertNil(color5, "Should return nil for invalid hex")
        
        // Test empty string
        let color6 = Color(hex: "")
        XCTAssertNil(color6, "Should return nil for empty string")
        
        // Test wrong length
        let color7 = Color(hex: "#FF00")
        XCTAssertNil(color7, "Should return nil for wrong length hex")
    }
    
    // MARK: - Performance Tests
    
    func testCreateTagPerformance() throws {
        measure {
            for i in 0..<1000 {
                let tag = SceneTag.createTag(
                    name: "标签\(i)",
                    color: "#FF0000",
                    isDefault: false,
                    in: testContext
                )
                tag.addAssociatedApp("com.test.app\(i)")
                tag.incrementUsageCount()
            }
        }
    }
    
    func testAssociatedAppsPerformance() throws {
        // Given: Tag
        let tag = SceneTag.createTag(name: "性能测试", in: testContext)
        
        // When: Adding many associated apps
        measure {
            for i in 0..<1000 {
                tag.addAssociatedApp("com.test.app\(i)")
            }
        }
        
        // Verify final count
        XCTAssertEqual(tag.associatedAppsSet.count, 1000, "Should have 1000 associated apps")
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyTagName() throws {
        // Given: Tag with empty name
        let tag = SceneTag.createTag(name: "", in: testContext)
        
        // When: Tag is created
        // Then: Should not crash and should store empty name
        XCTAssertEqual(tag.name, "", "Should store empty name")
        XCTAssertNotNil(tag.tagID, "Should still generate tag ID")
    }
    
    func testVeryLongTagName() throws {
        // Given: Tag with very long name
        let longName = String(repeating: "很长的标签名", count: 100)
        let tag = SceneTag.createTag(name: longName, in: testContext)
        
        // When: Tag is created
        // Then: Should handle long name
        XCTAssertEqual(tag.name, longName, "Should store long name")
    }
    
    func testSpecialCharactersInTagName() throws {
        // Given: Tag with special characters
        let specialName = "标签!@#$%^&*()_+-=[]{}|;':\",./<>?"
        let tag = SceneTag.createTag(name: specialName, in: testContext)
        
        // When: Tag is created
        // Then: Should handle special characters
        XCTAssertEqual(tag.name, specialName, "Should store name with special characters")
    }
    
    func testInvalidColorFormat() throws {
        // Given: Tag with invalid color
        let tag = SceneTag.createTag(name: "测试", color: "invalid_color", in: testContext)
        
        // When: Getting SwiftUI color
        let color = tag.swiftUIColor
        
        // Then: Should fallback to default color
        XCTAssertNotNil(color, "Should provide fallback color")
    }
    
    func testNegativeUsageCount() throws {
        // Given: Tag
        let tag = SceneTag.createTag(name: "测试", in: testContext)
        
        // When: Setting negative usage count
        tag.usageCount = -5
        
        // Then: Should store negative value (Core Data allows it)
        XCTAssertEqual(tag.usageCount, -5, "Should store negative usage count")
    }
    
    func testVeryLargeUsageCount() throws {
        // Given: Tag
        let tag = SceneTag.createTag(name: "测试", in: testContext)
        
        // When: Setting very large usage count
        tag.usageCount = Int32.max
        
        // Then: Should store large value
        XCTAssertEqual(tag.usageCount, Int32.max, "Should store large usage count")
    }
}