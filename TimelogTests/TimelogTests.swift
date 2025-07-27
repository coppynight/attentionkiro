import XCTest
import CoreData
@testable import Timelog

/// TimelogTests - 核心功能单元测试
/// 测试应用的核心业务逻辑和数据管理功能
final class TimelogTests: XCTestCase {
    
    // MARK: - Properties
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // 创建内存中的Core Data栈用于测试
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        viewContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Core Data Tests
    
    /// 测试Core Data栈的基本功能
    func testCoreDataStack() throws {
        XCTAssertNotNil(persistenceController)
        XCTAssertNotNil(viewContext)
        XCTAssertEqual(viewContext.persistentStoreCoordinator, persistenceController.container.persistentStoreCoordinator)
    }
    
    /// 测试TimeCommit实体的创建和保存
    func testTimeCommitCreation() throws {
        let timeCommit = TimeCommit(context: viewContext)
        timeCommit.id = UUID()
        timeCommit.startTime = Date()
        timeCommit.endTime = Date().addingTimeInterval(1800) // 30分钟后
        timeCommit.message = "测试提交"
        timeCommit.focusIntensity = 0.8
        timeCommit.qualityScore = 4.5
        
        try viewContext.save()
        
        // 验证数据已保存
        let request: NSFetchRequest<TimeCommit> = TimeCommit.fetchRequest()
        let commits = try viewContext.fetch(request)
        
        XCTAssertEqual(commits.count, 1)
        XCTAssertEqual(commits.first?.message, "测试提交")
        XCTAssertEqual(commits.first?.focusIntensity, 0.8, accuracy: 0.01)
        XCTAssertEqual(commits.first?.qualityScore, 4.5, accuracy: 0.01)
    }
    
    /// 测试TimeTag实体的创建和关联
    func testTimeTagCreation() throws {
        let timeTag = TimeTag(context: viewContext)
        timeTag.id = UUID()
        timeTag.name = "工作"
        timeTag.color = "blue"
        timeTag.isDefault = true
        timeTag.usageCount = 0
        
        try viewContext.save()
        
        // 验证数据已保存
        let request: NSFetchRequest<TimeTag> = TimeTag.fetchRequest()
        let tags = try viewContext.fetch(request)
        
        XCTAssertEqual(tags.count, 1)
        XCTAssertEqual(tags.first?.name, "工作")
        XCTAssertEqual(tags.first?.color, "blue")
        XCTAssertTrue(tags.first?.isDefault ?? false)
    }
    
    /// 测试TimeBlock实体的创建和关联
    func testTimeBlockCreation() throws {
        let timeBlock = TimeBlock(context: viewContext)
        timeBlock.id = UUID()
        timeBlock.startTime = Date()
        timeBlock.endTime = Date().addingTimeInterval(1200) // 20分钟后
        timeBlock.duration = 1200
        timeBlock.isTagged = false
        
        try viewContext.save()
        
        // 验证数据已保存
        let request: NSFetchRequest<TimeBlock> = TimeBlock.fetchRequest()
        let blocks = try viewContext.fetch(request)
        
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks.first?.duration, 1200, accuracy: 0.01)
        XCTAssertFalse(blocks.first?.isTagged ?? true)
    }
    
    /// 测试UserSettings实体的创建和更新
    func testUserSettingsCreation() throws {
        let settings = UserSettings(context: viewContext)
        settings.id = UUID()
        settings.timeBlockGranularity = 1200 // 20分钟
        settings.enableBeautifulMoments = true
        settings.autoTaggingEnabled = false
        settings.heatmapColorScheme = "github"
        settings.dailyGoalHours = 8.0
        
        try viewContext.save()
        
        // 验证数据已保存
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let settingsArray = try viewContext.fetch(request)
        
        XCTAssertEqual(settingsArray.count, 1)
        XCTAssertEqual(settingsArray.first?.timeBlockGranularity, 1200, accuracy: 0.01)
        XCTAssertTrue(settingsArray.first?.enableBeautifulMoments ?? false)
        XCTAssertEqual(settingsArray.first?.heatmapColorScheme, "github")
        XCTAssertEqual(settingsArray.first?.dailyGoalHours, 8.0, accuracy: 0.01)
    }
    
    // MARK: - Business Logic Tests
    
    /// 测试时间块的时长计算
    func testTimeBlockDurationCalculation() throws {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(1800) // 30分钟后
        
        let timeBlock = TimeBlock(context: viewContext)
        timeBlock.id = UUID()
        timeBlock.startTime = startTime
        timeBlock.endTime = endTime
        timeBlock.duration = endTime.timeIntervalSince(startTime)
        
        XCTAssertEqual(timeBlock.duration, 1800, accuracy: 0.01)
        XCTAssertEqual(timeBlock.formattedDuration, "30m")
    }
    
    /// 测试时间范围字符串格式化
    func testTimeRangeStringFormatting() throws {
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
        let endTime = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!
        
        let timeBlock = TimeBlock(context: viewContext)
        timeBlock.id = UUID()
        timeBlock.startTime = startTime
        timeBlock.endTime = endTime
        timeBlock.duration = endTime.timeIntervalSince(startTime)
        
        let timeRangeString = timeBlock.timeRangeString
        XCTAssertTrue(timeRangeString.contains("9:00"))
        XCTAssertTrue(timeRangeString.contains("9:30"))
    }
    
    /// 测试专注强度计算逻辑
    func testFocusIntensityCalculation() throws {
        // 测试不同专注强度的分类
        XCTAssertEqual(FocusIntensityCalculator.getFocusQuality(for: 0.9), .excellent)
        XCTAssertEqual(FocusIntensityCalculator.getFocusQuality(for: 0.7), .good)
        XCTAssertEqual(FocusIntensityCalculator.getFocusQuality(for: 0.5), .fair)
        XCTAssertEqual(FocusIntensityCalculator.getFocusQuality(for: 0.3), .poor)
        XCTAssertEqual(FocusIntensityCalculator.getFocusQuality(for: 0.1), .veryPoor)
    }
    
    /// 测试美好时刻标记功能
    func testBeautifulMomentMarking() throws {
        let timeCommit = TimeCommit(context: viewContext)
        timeCommit.id = UUID()
        timeCommit.startTime = Date()
        timeCommit.endTime = Date().addingTimeInterval(1800)
        timeCommit.message = "完成重要项目"
        timeCommit.isBeautifulMoment = true
        timeCommit.emotionType = "achievement"
        
        try viewContext.save()
        
        // 验证美好时刻标记
        let request: NSFetchRequest<TimeCommit> = TimeCommit.fetchRequest()
        request.predicate = NSPredicate(format: "isBeautifulMoment == YES")
        let beautifulMoments = try viewContext.fetch(request)
        
        XCTAssertEqual(beautifulMoments.count, 1)
        XCTAssertEqual(beautifulMoments.first?.emotionType, "achievement")
        XCTAssertTrue(beautifulMoments.first?.isBeautifulMoment ?? false)
    }
    
    // MARK: - Data Validation Tests
    
    /// 测试数据验证逻辑
    func testDataValidation() throws {
        let timeCommit = TimeCommit(context: viewContext)
        timeCommit.id = UUID()
        timeCommit.startTime = Date()
        timeCommit.endTime = Date().addingTimeInterval(-1800) // 结束时间早于开始时间
        
        // 这应该触发验证错误
        XCTAssertThrowsError(try viewContext.save()) { error in
            XCTAssertTrue(error is NSError)
        }
    }
    
    /// 测试标签名称唯一性
    func testTagNameUniqueness() throws {
        // 创建第一个标签
        let tag1 = TimeTag(context: viewContext)
        tag1.id = UUID()
        tag1.name = "工作"
        tag1.color = "blue"
        
        // 尝试创建同名标签
        let tag2 = TimeTag(context: viewContext)
        tag2.id = UUID()
        tag2.name = "工作"
        tag2.color = "red"
        
        try viewContext.save()
        
        // 验证可以保存（业务逻辑层应该处理唯一性）
        let request: NSFetchRequest<TimeTag> = TimeTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "工作")
        let tags = try viewContext.fetch(request)
        
        // 数据层允许重复，业务逻辑层应该处理
        XCTAssertEqual(tags.count, 2)
    }
    
    // MARK: - Performance Tests
    
    /// 测试大量数据的性能
    func testPerformanceWithLargeDataset() throws {
        measure {
            // 创建1000个时间提交记录
            for i in 0..<1000 {
                let timeCommit = TimeCommit(context: viewContext)
                timeCommit.id = UUID()
                timeCommit.startTime = Date().addingTimeInterval(TimeInterval(i * 1800))
                timeCommit.endTime = Date().addingTimeInterval(TimeInterval((i + 1) * 1800))
                timeCommit.message = "提交 \(i)"
                timeCommit.focusIntensity = Double.random(in: 0.0...1.0)
                timeCommit.qualityScore = Double.random(in: 1.0...5.0)
            }
            
            do {
                try viewContext.save()
            } catch {
                XCTFail("保存大量数据失败: \(error)")
            }
        }
    }
    
    /// 测试查询性能
    func testQueryPerformance() throws {
        // 先创建测试数据
        for i in 0..<100 {
            let timeCommit = TimeCommit(context: viewContext)
            timeCommit.id = UUID()
            timeCommit.startTime = Date().addingTimeInterval(TimeInterval(i * 1800))
            timeCommit.endTime = Date().addingTimeInterval(TimeInterval((i + 1) * 1800))
            timeCommit.message = "提交 \(i)"
            timeCommit.focusIntensity = Double.random(in: 0.0...1.0)
        }
        try viewContext.save()
        
        // 测试查询性能
        measure {
            let request: NSFetchRequest<TimeCommit> = TimeCommit.fetchRequest()
            request.predicate = NSPredicate(format: "focusIntensity > %f", 0.5)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeCommit.startTime, ascending: false)]
            
            do {
                let _ = try viewContext.fetch(request)
            } catch {
                XCTFail("查询失败: \(error)")
            }
        }
    }
}

// MARK: - Test Extensions

extension TimelogTests {
    
    /// 创建测试用的时间提交记录
    func createTestTimeCommit(message: String = "测试提交", focusIntensity: Double = 0.8) -> TimeCommit {
        let timeCommit = TimeCommit(context: viewContext)
        timeCommit.id = UUID()
        timeCommit.startTime = Date()
        timeCommit.endTime = Date().addingTimeInterval(1800)
        timeCommit.message = message
        timeCommit.focusIntensity = focusIntensity
        timeCommit.qualityScore = 4.0
        return timeCommit
    }
    
    /// 创建测试用的时间标签
    func createTestTimeTag(name: String = "测试标签", color: String = "blue") -> TimeTag {
        let timeTag = TimeTag(context: viewContext)
        timeTag.id = UUID()
        timeTag.name = name
        timeTag.color = color
        timeTag.isDefault = false
        timeTag.usageCount = 0
        return timeTag
    }
}