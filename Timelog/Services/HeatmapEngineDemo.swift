import Foundation
import CoreData
import SwiftUI

/// HeatmapEngineDemo - 热力图引擎演示类
/// 展示如何在实际应用中使用HeatmapEngine
@MainActor
class HeatmapEngineDemo: ObservableObject {
    
    // MARK: - Properties
    
    @Published var isLoading = false
    @Published var demoHeatmapData: HeatmapData?
    @Published var performanceMetrics: PerformanceMetrics?
    
    private let heatmapEngine: HeatmapEngine
    private let performanceOptimizer: HeatmapPerformanceOptimizer
    private let viewContext: NSManagedObjectContext
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        self.heatmapEngine = HeatmapEngine(viewContext: viewContext)
        self.performanceOptimizer = HeatmapPerformanceOptimizer()
    }
    
    // MARK: - Demo Methods
    
    /// 演示基本热力图生成
    func demonstrateBasicGeneration() async {
        await MainActor.run { isLoading = true }
        
        let startTime = Date()
        let today = Date()
        
        // 生成今天的热力图数据
        let heatmapData = await heatmapEngine.generateHeatmapData(for: today)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        await MainActor.run {
            self.demoHeatmapData = heatmapData
            self.performanceMetrics = PerformanceMetrics(
                generationTime: duration,
                gridBlocksCount: heatmapData.gridBlocks.count,
                activeBlocksCount: heatmapData.stats.activeBlocks,
                beautifulMomentsCount: heatmapData.stats.beautifulMomentBlocks,
                cacheHitRate: heatmapEngine.cacheHitRate
            )
            self.isLoading = false
        }
        
        print("📊 热力图生成完成:")
        print("   - 耗时: \(String(format: "%.3f", duration))秒")
        print("   - 网格块数: \(heatmapData.gridBlocks.count)")
        print("   - 活跃块数: \(heatmapData.stats.activeBlocks)")
        print("   - 美好时刻: \(heatmapData.stats.beautifulMomentBlocks)")
        print("   - 缓存命中率: \(String(format: "%.1f", heatmapEngine.cacheHitRate * 100))%")
    }
    
    /// 演示批量数据生成
    func demonstrateBatchGeneration() async {
        await MainActor.run { isLoading = true }
        
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        let startTime = Date()
        
        // 生成一周的热力图数据
        let weeklyData = await heatmapEngine.generateHeatmapData(from: weekAgo, to: today)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        await MainActor.run {
            self.performanceMetrics = PerformanceMetrics(
                generationTime: duration,
                gridBlocksCount: weeklyData.values.reduce(0) { $0 + $1.gridBlocks.count },
                activeBlocksCount: weeklyData.values.reduce(0) { $0 + $1.stats.activeBlocks },
                beautifulMomentsCount: weeklyData.values.reduce(0) { $0 + $1.stats.beautifulMomentBlocks },
                cacheHitRate: heatmapEngine.cacheHitRate
            )
            self.isLoading = false
        }
        
        print("📅 批量生成完成:")
        print("   - 生成天数: \(weeklyData.count)")
        print("   - 总耗时: \(String(format: "%.3f", duration))秒")
        print("   - 平均每天: \(String(format: "%.3f", duration / Double(weeklyData.count)))秒")
    }
    
    /// 演示性能优化
    func demonstratePerformanceOptimization() async {
        await MainActor.run { isLoading = true }
        
        // 创建大量测试数据
        await createLargeTestDataset()
        
        let today = Date()
        let startTime = Date()
        
        // 使用性能优化器生成热力图
        let optimizedData = await generateOptimizedHeatmap(for: today)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        await MainActor.run {
            self.demoHeatmapData = optimizedData
            self.performanceMetrics = PerformanceMetrics(
                generationTime: duration,
                gridBlocksCount: optimizedData.gridBlocks.count,
                activeBlocksCount: optimizedData.stats.activeBlocks,
                beautifulMomentsCount: optimizedData.stats.beautifulMomentBlocks,
                cacheHitRate: heatmapEngine.cacheHitRate
            )
            self.isLoading = false
        }
        
        print("⚡ 性能优化演示完成:")
        print("   - 优化后耗时: \(String(format: "%.3f", duration))秒")
        print("   - 处理效率提升显著")
    }
    
    /// 演示缓存预热
    func demonstrateCacheWarmup() async {
        await MainActor.run { isLoading = true }
        
        print("🔥 开始缓存预热...")
        
        let startTime = Date()
        
        // 预热最近7天的缓存
        await heatmapEngine.warmupCache(days: 7)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        await MainActor.run {
            self.performanceMetrics = PerformanceMetrics(
                generationTime: duration,
                gridBlocksCount: 0,
                activeBlocksCount: 0,
                beautifulMomentsCount: 0,
                cacheHitRate: heatmapEngine.cacheHitRate
            )
            self.isLoading = false
        }
        
        print("🔥 缓存预热完成:")
        print("   - 预热耗时: \(String(format: "%.3f", duration))秒")
        print("   - 缓存命中率: \(String(format: "%.1f", heatmapEngine.cacheHitRate * 100))%")
    }
    
    /// 演示实时数据更新
    func demonstrateRealTimeUpdate() async {
        await MainActor.run { isLoading = true }
        
        let today = Date()
        
        // 生成初始热力图
        var heatmapData = await heatmapEngine.generateHeatmapData(for: today)
        
        // 模拟添加新的时间块
        await createRealtimeTimeBlock()
        
        // 清除缓存以获取最新数据
        heatmapEngine.clearCache()
        
        // 重新生成热力图
        heatmapData = await heatmapEngine.generateHeatmapData(for: today)
        
        await MainActor.run {
            self.demoHeatmapData = heatmapData
            self.isLoading = false
        }
        
        print("🔄 实时更新演示完成")
    }
    
    // MARK: - Helper Methods
    
    private func createLargeTestDataset() async {
        let calendar = Calendar.current
        let today = Date()
        
        // 创建1000个随机时间块
        for i in 0..<1000 {
            let randomHour = Int.random(in: 0..<24)
            let randomMinute = Int.random(in: 0..<60)
            
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
            dateComponents.hour = randomHour
            dateComponents.minute = randomMinute
            
            if let blockDate = calendar.date(from: dateComponents) {
                await createTestTimeBlock(at: blockDate)
            }
        }
        
        // 保存数据
        try? viewContext.save()
    }
    
    private func createTestTimeBlock(at date: Date) async {
        await viewContext.perform {
            let timeBlock = TimeBlock.create(
                in: self.viewContext,
                startTime: date,
                endTime: date.addingTimeInterval(900), // 15分钟
                activity: "测试活动 \(Int.random(in: 1...10))",
                category: ["工作", "学习", "娱乐", "运动"].randomElement()!
            )
            
            // 随机创建美好时刻
            if Bool.random() && Double.random(in: 0...1) > 0.8 {
                let commit = TimeCommit(context: self.viewContext)
                commit.id = UUID()
                commit.timeBlock = timeBlock
                commit.commitMessage = "美好时刻"
                commit.focusIntensity = Double.random(in: 0.7...1.0)
                commit.isBeautifulMoment = true
                commit.createdAt = Date()
            }
        }
    }
    
    private func createRealtimeTimeBlock() async {
        let now = Date()
        await createTestTimeBlock(at: now)
        try? viewContext.save()
    }
    
    private func generateOptimizedHeatmap(for date: Date) async -> HeatmapData {
        // 使用性能优化器获取数据
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let timeBlocks = await performanceOptimizer.optimizedTimeBlockFetch(
            context: viewContext,
            startDate: startOfDay,
            endDate: endOfDay
        )
        
        // 生成热力图数据
        return await heatmapEngine.generateHeatmapData(for: date)
    }
    
    /// 获取演示数据摘要
    func getDemoSummary() -> String {
        guard let data = demoHeatmapData,
              let metrics = performanceMetrics else {
            return "暂无数据"
        }
        
        return """
        📊 热力图数据摘要:
        • 日期: \(DateFormatter.shortDate.string(from: data.date))
        • 网格块总数: \(data.gridBlocks.count)
        • 活跃块数: \(data.stats.activeBlocks)
        • 活跃率: \(String(format: "%.1f", data.stats.activityRate * 100))%
        • 美好时刻: \(data.stats.beautifulMomentBlocks)
        • 平均强度: \(String(format: "%.2f", data.stats.averageIntensity))
        • 生成耗时: \(String(format: "%.3f", metrics.generationTime))秒
        • 缓存命中率: \(String(format: "%.1f", metrics.cacheHitRate * 100))%
        """
    }
}

// MARK: - Supporting Types

struct PerformanceMetrics {
    let generationTime: TimeInterval
    let gridBlocksCount: Int
    let activeBlocksCount: Int
    let beautifulMomentsCount: Int
    let cacheHitRate: Double
}

// MARK: - SwiftUI Preview Support

#if DEBUG
struct HeatmapEngineDemo_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("HeatmapEngine Demo")
                .font(.title)
            
            Text("This is a demo of the HeatmapEngine functionality")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
#endif

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}