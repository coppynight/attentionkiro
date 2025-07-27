import XCTest
import CoreData
@testable import Timelog

/// HeatmapEngineTests - 热力图引擎测试
/// 测试GitHub风格热力图的数据生成和计算逻辑
final class HeatmapEngineTests: XCTestCase {
    
    // MARK: - Properties
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var heatmapEngine: HeatmapEngine!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        heatmapEngine = HeatmapEngine(viewContext: viewContext)
    }
    
    override func tearDownWithError() throws {
        heatmapEngine = nil
        persistenceController = nil
        viewContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Data Generation Tests
    
    /// 测试热力图数据生成
    func testHeatmapDataGeneration() throws {
        let date = Date()
        let heatmapData = heatmapEngine.generateHeatmapData(for: date)
        
        XCTAssertNotNil(heatmapData)
        XCTAssertEqual(heatmapData.date, Calendar.current.startOfDay(for: date))
        XCTAssertEqual(heatmapData.timeBlocks.count, 96) // 24小时 * 4个15分钟块
    }
    
    /// 测试空数据的热力图生成
    func testEmptyDataHeatmapGeneration() throws {
        let date = Date()
        let heatmapData = heatmapEngine.generateHeatmapData(for: date)
        
        // 没有实际数据时，应该生成模拟数据
        XCTAssertFalse(heatmapData.timeBlocks.isEmpty)
        
        // 检查时间块的基本属性
        let firstBlock = heatmapData.timeBlocks.first!
        XCTAssertNotNil(firstBlock.startTime)
        XCTAssertNotNil(firstBlock.endTime)
        XCTAssertGreaterThanOrEqual(firstBlock.focusIntensity, 0.0)
        XCTAssertLessThanOrEqual(firstBlock.focusIntensity, 1.0)
    }
    
    /// 测试实际数据的热力图生成
    func testRealDataHeatmapGeneration() throws {
        let date = Date()
        
        // 创建测试数据
        createTestTimeCommits(for: date, count: 10)
        
        let heatmapData = heatmapEngine.generateHeatmapData(for: date)
        
        XCTAssertNotNil(heatmapData)
        XCTAssertEqual(heatmapData.timeBlocks.count, 96)
        
        // 验证至少有一些时间块有数据
        let activeBlocks = heatmapData.timeBlocks.filter { $0.focusIntensity > 0 }
        XCTAssertGreaterThan(activeBlocks.count, 0)
    }
    
    // MARK: - Intensity Calculation Tests
    
    /// 测试专注强度等级计算
    func testFocusIntensityLevels() throws {
        XCTAssertEqual(heatmapEngine.getIntensityLevel(for: 0.0), 0)
        XCTAssertEqual(heatmapEngine.getIntensityLevel(for: 0.1), 1)
        XCTAssertEqual(heatmapEngine.getIntensityLevel(for: 0.3), 2)
        XCTAssertEqual(heatmapEngine.getIntensityLevel(for: 0.6), 3)
        XCTAssertEqual(heatmapEngine.getIntensityLevel(for: 0.8), 4)
        XCTAssertEqual(heatmapEngine.getIntensityLevel(for: 1.0), 4)
    }
    
    /// 测试GitHub风格颜色计算
    func testGitHubStyleColors() throws {
        let colors = heatmapEngine.getGitHubStyleColors()
        
        XCTAssertEqual(colors.count, 5) // 0-4级强度
        XCTAssertEqual(colors[0], "#ebedf0") // 无活动
        XCTAssertEqual(colors[4], "#196127") // 最高强度
    }
    
    /// 测试强度分布计算
    func testIntensityDistribution() throws {
        let date = Date()
        createTestTimeCommits(for: date, count: 20)
        
        let heatmapData = heatmapEngine.generateHeatmapData(for: date)
        let distribution = heatmapEngine.calculateIntensityDistribution(heatmapData.timeBlocks)
        
        XCTAssertEqual(distribution.keys.count, 5) // 0-4级
        
        let totalBlocks = distribution.values.reduce(0, +)
        XCTAssertEqual(totalBlocks, 96) // 总时间块数
    }
    
    // MARK: - Time Block Processing Tests
    
    /// 测试时间块网格划分
    func testTimeBlockGridDivision() throws {
        let date = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let timeBlocks = heatmapEngine.generateTimeBlockGrid(for: date)
        
        XCTAssertEqual(timeBlocks.count, 96) // 24小时 * 4个15分钟块
        
        // 验证第一个时间块
        let firstBlock = timeBlocks.first!
        XCTAssertEqual(firstBlock.startTime, startOfDay)
        XCTAssertEqual(firstBlock.endTime, startOfDay.addingTimeInterval(15 * 60))
        
        // 验证最后一个时间块
        let lastBlock = timeBlocks.last!
        let expectedLastStart = startOfDay.addingTimeInterval(23 * 60 * 60 + 45 * 60)
        XCTAssertEqual(lastBlock.startTime, expectedLastStart)
    }
    
    /// 测试时间块数据映射
    func testTimeBlockDataMapping() throws {
        let date = Date()
        let commits = createTestTimeCommits(for: date, count: 5)
        
        let timeBlocks = heatmapEngine.generateTimeBlockGrid(for: date)
        let mappedBlocks = heatmapEngine.mapCommitsToTimeBlocks(commits, timeBlocks: timeBlocks)
        
        XCTAssertEqual(mappedBlocks.count, 96)
        
        // 验证至少有一些时间块被映射了数据
        let mappedBlocksWithData = mappedBlocks.filter { !$0.activities.isEmpty }
        XCTAssertGreaterThan(mappedBlocksWithData.count, 0)
    }
    
    // MARK: - Beautiful Moments Tests
    
    /// 测试美好时刻在热力图中的显示
    func testBeautifulMomentsInHeatmap() throws {
        let date = Date()
        
        // 创建包含美好时刻的测试数据
        let commit = createTestTimeCommit(for: date, isBeautifulMoment: true)
        try viewContext.save()
        
        let heatmapData = heatmapEngine.generateHeatmapData(for: date)
        
        // 查找包含美好时刻的时间块
        let beautifulBlocks = heatmapData.timeBlocks.filter { $0.hasBeautifulMoment }
        XCTAssertGreaterThan(beautifulBlocks.count, 0)
        
        let beautifulBlock = beautifulBlocks.first!
        XCTAssertTrue(beautifulBlock.hasBeautifulMoment)
        XCTAssertNotNil(beautifulBlock.beautifulMomentTitle)
    }
    
    /// 测试美好时刻特殊标记
    func testBeautifulMomentSpecialMarking() throws {
        let timeBlock = HeatmapTimeBlock(
            startTime: Date(),
            endTime: Date().addingTimeInterval(900),
            focusIntensity: 0.8,
            interruptionCount: 0,
            totalFocusTime: 900,
            category: "工作",
            activities: ["完成重要任务"],
            hasBeautifulMoment: true,
            beautifulMomentTitle: "重大突破"
        )
        
        XCTAssertTrue(timeBlock.hasBeautifulMoment)
        XCTAssertEqual(timeBlock.beautifulMomentTitle, "重大突破")
        XCTAssertTrue(timeBlock.isSpecialMoment)
    }
    
    // MARK: - Weekly Heatmap Tests
    
    /// 测试周热力图生成
    func testWeeklyHeatmapGeneration() throws {
        let startDate = Date()
        let weeklyData = heatmapEngine.generateWeeklyHeatmap(startDate: startDate)
        
        XCTAssertEqual(weeklyData.count, 7) // 一周7天
        
        for (date, dayData) in weeklyData {
            XCTAssertNotNil(dayData)
            XCTAssertEqual(dayData.timeBlocks.count, 96)
        }
    }
    
    /// 测试月热力图生成
    func testMonthlyHeatmapGeneration() throws {
        let date = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)!.start
        
        let monthlyData = heatmapEngine.generateMonthlyHeatmap(for: startOfMonth)
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)!.count
        XCTAssertEqual(monthlyData.count, daysInMonth)
    }
    
    // MARK: - Performance Tests
    
    /// 测试热力图生成性能
    func testHeatmapGenerationPerformance() throws {
        let date = Date()
        createTestTimeCommits(for: date, count: 100)
        
        measure {
            let _ = heatmapEngine.generateHeatmapData(for: date)
        }
    }
    
    /// 测试大数据量处理性能
    func testLargeDatasetPerformance() throws {
        let date = Date()
        createTestTimeCommits(for: date, count: 1000)
        
        measure {
            let heatmapData = heatmapEngine.generateHeatmapData(for: date)
            let _ = heatmapEngine.calculateIntensityDistribution(heatmapData.timeBlocks)
        }
    }
    
    /// 测试周数据生成性能
    func testWeeklyDataGenerationPerformance() throws {
        let startDate = Date()
        
        // 为一周的每一天创建测试数据
        for dayOffset in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate) {
                createTestTimeCommits(for: date, count: 50)
            }
        }
        
        measure {
            let _ = heatmapEngine.generateWeeklyHeatmap(startDate: startDate)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 创建测试用的时间提交记录
    @discardableResult
    private func createTestTimeCommits(for date: Date, count: Int) -> [TimeCommit] {
        var commits: [TimeCommit] = []
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        for i in 0..<count {
            let commit = TimeCommit(context: viewContext)
            commit.id = UUID()
            commit.startTime = startOfDay.addingTimeInterval(TimeInterval(i * 1800)) // 每30分钟一个
            commit.endTime = commit.startTime.addingTimeInterval(1800)
            commit.message = "测试提交 \(i)"
            commit.focusIntensity = Double.random(in: 0.0...1.0)
            commit.qualityScore = Double.random(in: 1.0...5.0)
            commit.isBeautifulMoment = i % 10 == 0 // 每10个中有1个美好时刻
            
            if commit.isBeautifulMoment {
                commit.beautifulMomentTitle = "美好时刻 \(i)"
                commit.emotionType = ["achievement", "joy", "peace", "creativity"].randomElement()!
            }
            
            commits.append(commit)
        }
        
        do {
            try viewContext.save()
        } catch {
            XCTFail("保存测试数据失败: \(error)")
        }
        
        return commits
    }
    
    /// 创建单个测试时间提交记录
    private func createTestTimeCommit(for date: Date, isBeautifulMoment: Bool = false) -> TimeCommit {
        let commit = TimeCommit(context: viewContext)
        commit.id = UUID()
        commit.startTime = date
        commit.endTime = date.addingTimeInterval(1800)
        commit.message = "测试提交"
        commit.focusIntensity = 0.8
        commit.qualityScore = 4.5
        commit.isBeautifulMoment = isBeautifulMoment
        
        if isBeautifulMoment {
            commit.beautifulMomentTitle = "测试美好时刻"
            commit.emotionType = "achievement"
        }
        
        return commit
    }
}