import Foundation
import CoreData
@testable import Timelog

/// HeatmapEngineTests - 热力图引擎测试类
/// 用于验证热力图引擎的各项功能和性能
@MainActor
class HeatmapEngineTests {
    
    // MARK: - Properties
    
    private var testContext: NSManagedObjectContext!
    private var heatmapEngine: HeatmapEngine!
    private var performanceOptimizer: HeatmapPerformanceOptimizer!
    
    // MARK: - Setup
    
    func setUp() {
        // 创建内存中的Core Data栈用于测试
        testContext = createInMemoryContext()
        heatmapEngine = HeatmapEngine(viewContext: testContext)
        performanceOptimizer = HeatmapPerformanceOptimizer()
        
        // 创建测试数据
        createTestData()
    }
    
    func tearDown() {
        testContext = nil
        heatmapEngine = nil
        performanceOptimizer = nil
    }
    
    // MARK: - Test Methods
    
    /// 测试基本热力图数据生成
    func testBasicHeatmapGeneration() async {
        let testDate = Date()
        let heatmapData = await heatmapEngine.generateHeatmapData(for: testDate)
        
        // 验证基本结构
        assert(heatmapData.gridBlocks.count == 96, "应该有96个15分钟网格块")
        assert(heatmapData.date.timeIntervalSince(testDate) < 60, "日期应该匹配")
        
        // 验证网格块结构
        for (index, gridBlock) in heatmapData.gridBlocks.enumerated() {
            assert(gridBlock.index == index, "网格块索引应该正确")
            assert(gridBlock.hour >= 0 && gridBlock.hour < 24, "小时应该在0-23范围内")
            assert(gridBlock.quarterHour >= 0 && gridBlock.quarterHour < 4, "15分钟块应该在0-3范围内")
        }
        
        print("✅ 基本热力图生成测试通过")
    }
    
    /// 测试GitHub风格的5级强度计算
    func testIntensityLevelCalculation() async {
        let testDate = Date()
        
        // 创建不同强度的测试时间块
        createTimeBlockWithIntensity(0.0, at: testDate)      // none
        createTimeBlockWithIntensity(0.1, at: testDate.addingTimeInterval(900))   // low
        createTimeBlockWithIntensity(0.3, at: testDate.addingTimeInterval(1800))  // medium
        createTimeBlockWithIntensity(0.6, at: testDate.addingTimeInterval(2700))  // high
        createTimeBlockWithIntensity(0.9, at: testDate.addingTimeInterval(3600))  // veryHigh
        
        let heatmapData = await heatmapEngine.generateHeatmapData(for: testDate)
        
        // 验证强度等级
        let intensityLevels = heatmapData.gridBlocks.map { $0.intensityLevel }
        let uniqueLevels = Set(intensityLevels)
        
        assert(uniqueLevels.contains(.none), "应该包含无活动等级")
        assert(uniqueLevels.contains(.low), "应该包含低强度等级")
        assert(uniqueLevels.contains(.medium), "应该包含中等强度等级")
        assert(uniqueLevels.contains(.high), "应该包含高强度等级")
        assert(uniqueLevels.contains(.veryHigh), "应该包含极高强度等级")
        
        print("✅ 强度等级计算测试通过")
    }
    
    /// 测试美好时刻特殊显示
    func testBeautifulMomentDisplay() async {
        let testDate = Date()
        
        // 创建美好时刻时间块
        let beautifulMomentBlock = createTimeBlockWithBeautifulMoment(at: testDate)
        let normalBlock = createNormalTimeBlock(at: testDate.addingTimeInterval(900))
        
        let heatmapData = await heatmapEngine.generateHeatmapData(for: testDate)
        
        // 验证美好时刻标记
        let beautifulMomentGridBlocks = heatmapData.gridBlocks.filter { $0.hasBeautifulMoment }
        assert(!beautifulMomentGridBlocks.isEmpty, "应该有美好时刻网格块")
        
        // 验证美好时刻颜色
        for gridBlock in beautifulMomentGridBlocks {
            assert(gridBlock.displayColor == "#FFD700", "美好时刻应该显示金色")
        }
        
        // 验证统计信息
        assert(heatmapData.stats.beautifulMomentBlocks > 0, "统计信息应该包含美好时刻数量")
        
        print("✅ 美好时刻显示测试通过")
    }
    
    /// 测试缓存机制
    func testCachingMechanism() async {
        let testDate = Date()
        
        // 第一次生成（应该缓存未命中）
        let startTime1 = Date()
        let heatmapData1 = await heatmapEngine.generateHeatmapData(for: testDate)
        let duration1 = Date().timeIntervalSince(startTime1)
        
        // 第二次生成（应该缓存命中）
        let startTime2 = Date()
        let heatmapData2 = await heatmapEngine.generateHeatmapData(for: testDate)
        let duration2 = Date().timeIntervalSince(startTime2)
        
        // 验证缓存效果
        assert(duration2 < duration1, "缓存命中应该更快")
        assert(heatmapData1.gridBlocks.count == heatmapData2.gridBlocks.count, "缓存数据应该一致")
        assert(heatmapEngine.cacheHitRate > 0, "缓存命中率应该大于0")
        
        print("✅ 缓存机制测试通过，命中率: \(heatmapEngine.cacheHitRate)")
    }
    
    /// 测试大数据量性能
    func testLargeDataPerformance() async {
        let testDate = Date()
        let calendar = Calendar.current
        
        // 创建大量测试数据（1000个时间块）
        for i in 0..<1000 {
            let blockDate = calendar.date(byAdding: .minute, value: i, to: testDate) ?? testDate
            createTimeBlockWithIntensity(Double.random(in: 0...1), at: blockDate)
        }
        
        // 测试性能
        let startTime = Date()
        let heatmapData = await heatmapEngine.generateHeatmapData(for: testDate)
        let duration = Date().timeIntervalSince(startTime)
        
        // 验证性能（应该在合理时间内完成）
        assert(duration < 5.0, "大数据量处理应该在5秒内完成")
        assert(heatmapData.gridBlocks.count == 96, "应该正确生成所有网格块")
        
        print("✅ 大数据量性能测试通过，耗时: \(String(format: "%.2f", duration))秒")
    }
    
    /// 测试批量数据生成
    func testBatchDataGeneration() async {
        let calendar = Calendar.current
        let startDate = Date()
        let endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
        
        // 批量生成一周的数据
        let batchStartTime = Date()
        let weeklyData = await heatmapEngine.generateHeatmapData(from: startDate, to: endDate)
        let batchDuration = Date().timeIntervalSince(batchStartTime)
        
        // 验证批量生成结果
        assert(weeklyData.count == 8, "应该生成8天的数据")
        
        for (date, heatmapData) in weeklyData {
            assert(heatmapData.gridBlocks.count == 96, "每天应该有96个网格块")
            assert(calendar.isDate(date, inSameDayAs: heatmapData.date), "日期应该匹配")
        }
        
        print("✅ 批量数据生成测试通过，耗时: \(String(format: "%.2f", batchDuration))秒")
    }
    
    /// 测试性能优化器
    func testPerformanceOptimizer() async {
        let testDate = Date()
        
        // 创建测试数据
        var timeBlocks: [TimeBlock] = []
        for i in 0..<500 {
            let block = createTimeBlockWithIntensity(Double.random(in: 0...1), at: testDate.addingTimeInterval(Double(i * 60)))
            timeBlocks.append(block)
        }
        
        // 测试批处理
        let batchResults = await performanceOptimizer.batchProcess(timeBlocks: timeBlocks) { blocks in
            return blocks.map { $0.averageFocusIntensity }
        }
        
        assert(batchResults.count == timeBlocks.count, "批处理结果数量应该匹配")
        
        // 测试优化查询
        let optimizedBlocks = await performanceOptimizer.optimizedTimeBlockFetch(
            context: testContext,
            startDate: testDate,
            endDate: testDate.addingTimeInterval(86400)
        )
        
        assert(!optimizedBlocks.isEmpty, "优化查询应该返回结果")
        
        print("✅ 性能优化器测试通过")
    }
    
    /// 测试内存使用
    func testMemoryUsage() async {
        let initialMemory = getMemoryUsage()
        
        // 生成大量热力图数据
        let calendar = Calendar.current
        let startDate = Date()
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: startDate)!
            _ = await heatmapEngine.generateHeatmapData(for: date)
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // 验证内存使用合理
        assert(memoryIncrease < 100_000_000, "内存增长应该控制在100MB以内") // 100MB
        
        print("✅ 内存使用测试通过，内存增长: \(String(format: "%.2f", memoryIncrease / 1_000_000))MB")
    }
    
    // MARK: - Helper Methods
    
    private func createInMemoryContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "TimelogDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to create in-memory store: \(error)")
            }
        }
        
        return container.viewContext
    }
    
    private func createTestData() {
        let calendar = Calendar.current
        let today = Date()
        
        // 创建一些基础测试数据
        for i in 0..<10 {
            let date = calendar.date(byAdding: .hour, value: i, to: today)!
            createTimeBlockWithIntensity(Double.random(in: 0...1), at: date)
        }
        
        saveContext()
    }
    
    @discardableResult
    private func createTimeBlockWithIntensity(_ intensity: Double, at date: Date) -> TimeBlock {
        let timeBlock = TimeBlock.create(
            in: testContext,
            startTime: date,
            endTime: date.addingTimeInterval(900), // 15分钟
            activity: "测试活动",
            category: "测试"
        )
        
        // 创建关联的提交记录来设置强度
        let commit = TimeCommit.create(
            in: testContext,
            timeBlock: timeBlock,
            commitMessage: "测试提交",
            focusIntensity: intensity
        )
        
        return timeBlock
    }
    
    @discardableResult
    private func createTimeBlockWithBeautifulMoment(at date: Date) -> TimeBlock {
        let timeBlock = createTimeBlockWithIntensity(0.8, at: date)
        
        // 创建美好时刻提交
        let beautifulCommit = TimeCommit.create(
            in: testContext,
            timeBlock: timeBlock,
            commitMessage: "美好时刻",
            focusIntensity: 0.9,
            isBeautifulMoment: true
        )
        
        return timeBlock
    }
    
    @discardableResult
    private func createNormalTimeBlock(at date: Date) -> TimeBlock {
        return createTimeBlockWithIntensity(0.5, at: date)
    }
    
    private func saveContext() {
        do {
            try testContext.save()
        } catch {
            print("❌ 保存测试数据失败: \(error)")
        }
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Double(info.resident_size) : 0.0
    }
    
    // MARK: - Run All Tests
    
    func runAllTests() async {
        print("🧪 开始运行热力图引擎测试...")
        
        setUp()
        
        await testBasicHeatmapGeneration()
        await testIntensityLevelCalculation()
        await testBeautifulMomentDisplay()
        await testCachingMechanism()
        await testLargeDataPerformance()
        await testBatchDataGeneration()
        await testPerformanceOptimizer()
        await testMemoryUsage()
        
        tearDown()
        
        print("🎉 所有热力图引擎测试完成！")
    }
}

// MARK: - Extensions for Testing
// TimeCommit.create method is now defined in TimeCommit+CoreDataClass.swift

import mach