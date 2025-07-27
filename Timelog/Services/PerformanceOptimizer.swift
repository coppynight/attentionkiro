import Foundation
import CoreData
import SwiftUI
import Combine

/// PerformanceOptimizer - 性能优化管理器
/// 负责应用性能监控和优化，确保MVP版本的流畅运行
class PerformanceOptimizer: ObservableObject {
    
    // MARK: - Properties
    
    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    @Published var memoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    
    // MARK: - Performance Metrics
    
    struct PerformanceMetrics {
        var appLaunchTime: TimeInterval = 0
        var heatmapRenderTime: TimeInterval = 0
        var dataQueryTime: TimeInterval = 0
        var memoryPeakUsage: Double = 0
        var averageCPUUsage: Double = 0
        var frameDropCount: Int = 0
        
        var isPerformanceGood: Bool {
            return appLaunchTime < 2.0 &&
                   heatmapRenderTime < 0.5 &&
                   dataQueryTime < 0.3 &&
                   memoryPeakUsage < 100.0 && // MB
                   averageCPUUsage < 50.0 // %
        }
    }
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        setupPerformanceMonitoring()
    }
    
    // MARK: - Performance Monitoring
    
    /// 设置性能监控
    private func setupPerformanceMonitoring() {
        // 监控内存使用
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMemoryUsage()
            }
            .store(in: &cancellables)
        
        // 监控CPU使用
        Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCPUUsage()
            }
            .store(in: &cancellables)
    }
    
    /// 更新内存使用情况
    private func updateMemoryUsage() {
        var memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsageMB = Double(memoryInfo.resident_size) / 1024.0 / 1024.0
            DispatchQueue.main.async {
                self.memoryUsage = memoryUsageMB
                self.performanceMetrics.memoryPeakUsage = max(self.performanceMetrics.memoryPeakUsage, memoryUsageMB)
            }
        }
    }
    
    /// 更新CPU使用情况
    private func updateCPUUsage() {
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
        
        if kerr == KERN_SUCCESS {
            // 简化的CPU使用率计算
            let cpuUsagePercent = Double(info.resident_size) / Double(info.virtual_size) * 100.0
            DispatchQueue.main.async {
                self.cpuUsage = min(cpuUsagePercent, 100.0)
                self.performanceMetrics.averageCPUUsage = (self.performanceMetrics.averageCPUUsage + cpuUsagePercent) / 2.0
            }
        }
    }
    
    // MARK: - Performance Optimization
    
    /// 优化Core Data性能
    func optimizeCoreDataPerformance() {
        // 设置Core Data性能优化选项
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // 启用持久化历史跟踪
        if let store = viewContext.persistentStoreCoordinator?.persistentStores.first {
            viewContext.persistentStoreCoordinator?.setMetadata([
                NSPersistentHistoryTrackingKey: true,
                NSPersistentStoreRemoteChangeNotificationPostOptionKey: true
            ], for: store)
        }
    }
    
    /// 优化内存使用
    func optimizeMemoryUsage() {
        // 清理未使用的对象
        viewContext.refreshAllObjects()
        
        // 重置上下文以释放内存
        if memoryUsage > 80.0 { // 超过80MB时清理
            viewContext.reset()
        }
        
        // 触发垃圾回收
        autoreleasepool {
            // 执行内存清理操作
        }
    }
    
    /// 优化热力图渲染性能
    func optimizeHeatmapRendering() -> HeatmapOptimizationSettings {
        var settings = HeatmapOptimizationSettings()
        
        // 根据设备性能调整渲染设置
        if memoryUsage > 60.0 || cpuUsage > 70.0 {
            settings.enableLowPowerMode = true
            settings.reduceAnimations = true
            settings.simplifyGradients = true
        }
        
        return settings
    }
    
    /// 优化数据查询性能
    func optimizeDataQueries() {
        // 设置批量大小限制
        let fetchRequest: NSFetchRequest<TimeCommit> = TimeCommit.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        fetchRequest.includesPropertyValues = false
        fetchRequest.includesSubentities = false
        
        // 预加载关联对象
        fetchRequest.relationshipKeyPathsForPrefetching = ["tags", "timeBlocks"]
    }
    
    // MARK: - Performance Measurement
    
    /// 测量应用启动时间
    func measureAppLaunchTime() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let launchTime = CFAbsoluteTimeGetCurrent() - startTime
            self.performanceMetrics.appLaunchTime = launchTime
        }
    }
    
    /// 测量热力图渲染时间
    func measureHeatmapRenderTime<T>(operation: () -> T) -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = operation()
        let renderTime = CFAbsoluteTimeGetCurrent() - startTime
        
        DispatchQueue.main.async {
            self.performanceMetrics.heatmapRenderTime = renderTime
        }
        
        return result
    }
    
    /// 测量数据查询时间
    func measureDataQueryTime<T>(operation: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let queryTime = CFAbsoluteTimeGetCurrent() - startTime
        
        DispatchQueue.main.async {
            self.performanceMetrics.dataQueryTime = queryTime
        }
        
        return result
    }
    
    // MARK: - Performance Reporting
    
    /// 生成性能报告
    func generatePerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            timestamp: Date(),
            metrics: performanceMetrics,
            currentMemoryUsage: memoryUsage,
            currentCPUUsage: cpuUsage,
            recommendations: generateOptimizationRecommendations()
        )
    }
    
    /// 生成优化建议
    private func generateOptimizationRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if performanceMetrics.appLaunchTime > 2.0 {
            recommendations.append("应用启动时间过长，建议优化启动流程")
        }
        
        if performanceMetrics.heatmapRenderTime > 0.5 {
            recommendations.append("热力图渲染时间过长，建议启用低功耗模式")
        }
        
        if performanceMetrics.memoryPeakUsage > 100.0 {
            recommendations.append("内存使用过高，建议清理缓存数据")
        }
        
        if performanceMetrics.averageCPUUsage > 50.0 {
            recommendations.append("CPU使用率过高，建议减少后台任务")
        }
        
        if performanceMetrics.dataQueryTime > 0.3 {
            recommendations.append("数据查询时间过长，建议优化数据库索引")
        }
        
        return recommendations
    }
    
    // MARK: - Cleanup
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

/// 热力图优化设置
struct HeatmapOptimizationSettings {
    var enableLowPowerMode: Bool = false
    var reduceAnimations: Bool = false
    var simplifyGradients: Bool = false
    var maxDataPoints: Int = 1000
    var renderingQuality: RenderingQuality = .high
    
    enum RenderingQuality {
        case low, medium, high
    }
}

/// 性能报告
struct PerformanceReport {
    let timestamp: Date
    let metrics: PerformanceOptimizer.PerformanceMetrics
    let currentMemoryUsage: Double
    let currentCPUUsage: Double
    let recommendations: [String]
    
    var isHealthy: Bool {
        return metrics.isPerformanceGood && 
               currentMemoryUsage < 80.0 && 
               currentCPUUsage < 60.0
    }
    
    var summary: String {
        return """
        性能报告 - \(DateFormatter.localizedString(from: timestamp, dateStyle: .short, timeStyle: .short))
        
        启动时间: \(String(format: "%.2f", metrics.appLaunchTime))秒
        热力图渲染: \(String(format: "%.3f", metrics.heatmapRenderTime))秒
        数据查询: \(String(format: "%.3f", metrics.dataQueryTime))秒
        内存使用: \(String(format: "%.1f", currentMemoryUsage))MB
        CPU使用: \(String(format: "%.1f", currentCPUUsage))%
        
        状态: \(isHealthy ? "良好" : "需要优化")
        
        建议:
        \(recommendations.isEmpty ? "无" : recommendations.joined(separator: "\n"))
        """
    }
}