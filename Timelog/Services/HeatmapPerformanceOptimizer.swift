import Foundation
import CoreData

/// HeatmapPerformanceOptimizer - 热力图性能优化器
/// 专门处理大数据量的性能优化，包括批处理、内存管理和计算优化
class HeatmapPerformanceOptimizer {
    
    // MARK: - Constants
    
    private enum OptimizationConfig {
        static let batchSize = 1000              // 批处理大小
        static let maxConcurrentOperations = 4   // 最大并发操作数
        static let memoryWarningThreshold = 0.8  // 内存警告阈值
        static let cacheCleanupInterval: TimeInterval = 300  // 缓存清理间隔（5分钟）
    }
    
    // MARK: - Private Properties
    
    private let operationQueue: OperationQueue
    private var memoryPressureObserver: NSObjectProtocol?
    private var lastCacheCleanup: Date = Date()
    
    // MARK: - Initialization
    
    init() {
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = OptimizationConfig.maxConcurrentOperations
        self.operationQueue.qualityOfService = .userInitiated
        
        setupMemoryPressureObserver()
    }
    
    deinit {
        if let observer = memoryPressureObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Methods
    
    /// 批量处理时间块数据
    /// - Parameters:
    ///   - timeBlocks: 时间块数组
    ///   - processor: 处理函数
    /// - Returns: 处理结果数组
    func batchProcess<T>(
        timeBlocks: [TimeBlock],
        processor: @escaping ([TimeBlock]) -> [T]
    ) async -> [T] {
        let batches = timeBlocks.chunked(into: OptimizationConfig.batchSize)
        var results: [T] = []
        
        for batch in batches {
            let batchResults = await withCheckedContinuation { continuation in
                operationQueue.addOperation {
                    let processedBatch = processor(batch)
                    continuation.resume(returning: processedBatch)
                }
            }
            results.append(contentsOf: batchResults)
            
            // 检查内存压力
            if shouldPauseForMemoryPressure() {
                await pauseForMemoryRelief()
            }
        }
        
        return results
    }
    
    /// 优化的时间块查询
    /// - Parameters:
    ///   - context: Core Data上下文
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 优化查询的时间块
    func optimizedTimeBlockFetch(
        context: NSManagedObjectContext,
        startDate: Date,
        endDate: Date
    ) async -> [TimeBlock] {
        return await withCheckedContinuation { continuation in
            context.perform {
                let request: NSFetchRequest<TimeBlock> = TimeBlock.fetchRequest()
                
                // 优化查询条件
                request.predicate = NSPredicate(
                    format: "startTime >= %@ AND startTime < %@",
                    startDate as NSDate,
                    endDate as NSDate
                )
                
                // 优化排序
                request.sortDescriptors = [
                    NSSortDescriptor(keyPath: \TimeBlock.startTime, ascending: true)
                ]
                
                // 设置批处理大小
                request.fetchBatchSize = OptimizationConfig.batchSize
                
                // 预加载关联数据
                request.relationshipKeyPathsForPrefetching = ["commits", "tags"]
                
                // 只获取需要的属性
                request.propertiesToFetch = [
                    "id", "startTime", "endTime", "duration", 
                    "taggedActivity", "category", "isTagged"
                ]
                
                do {
                    let timeBlocks = try context.fetch(request)
                    continuation.resume(returning: timeBlocks)
                } catch {
                    print("❌ 优化查询失败: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    /// 并行计算网格块强度
    /// - Parameters:
    ///   - gridBlocks: 网格块数组
    ///   - timeBlocks: 时间块数组
    /// - Returns: 计算完成的网格块
    func parallelCalculateIntensities(
        gridBlocks: [HeatmapGridBlock],
        timeBlocks: [TimeBlock]
    ) async -> [HeatmapGridBlock] {
        let chunks = gridBlocks.chunked(into: gridBlocks.count / OptimizationConfig.maxConcurrentOperations + 1)
        
        return await withTaskGroup(of: [HeatmapGridBlock].self) { group in
            for chunk in chunks {
                group.addTask {
                    return self.calculateIntensitiesForChunk(chunk, timeBlocks: timeBlocks)
                }
            }
            
            var results: [HeatmapGridBlock] = []
            for await chunkResult in group {
                results.append(contentsOf: chunkResult)
            }
            
            return results.sorted { $0.index < $1.index }
        }
    }
    
    /// 内存优化的缓存管理
    /// - Parameter cache: 缓存字典
    func optimizeCache<T>(_ cache: inout [String: T]) {
        let now = Date()
        
        // 检查是否需要清理缓存
        if now.timeIntervalSince(lastCacheCleanup) > OptimizationConfig.cacheCleanupInterval {
            let memoryUsage = getMemoryUsage()
            
            if memoryUsage > OptimizationConfig.memoryWarningThreshold {
                // 清理一半的缓存
                let keysToRemove = Array(cache.keys.prefix(cache.count / 2))
                for key in keysToRemove {
                    cache.removeValue(forKey: key)
                }
                
                print("🧹 缓存清理完成，移除了 \(keysToRemove.count) 个条目")
            }
            
            lastCacheCleanup = now
        }
    }
    
    /// 预计算热力图数据
    /// - Parameters:
    ///   - dates: 日期数组
    ///   - heatmapEngine: 热力图引擎
    func precomputeHeatmapData(
        for dates: [Date],
        using heatmapEngine: HeatmapEngine
    ) async {
        let sortedDates = dates.sorted()
        
        await withTaskGroup(of: Void.self) { group in
            for date in sortedDates {
                group.addTask {
                    _ = await heatmapEngine.generateHeatmapData(for: date)
                }
                
                // 限制并发数量，避免内存压力
                if group.isEmpty == false && group.isEmpty {
                    await group.next()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 为数据块计算强度
    private func calculateIntensitiesForChunk(
        _ gridBlocks: [HeatmapGridBlock],
        timeBlocks: [TimeBlock]
    ) -> [HeatmapGridBlock] {
        return gridBlocks.map { gridBlock in
            // 使用空间索引优化查找重叠的时间块
            let overlappingBlocks = findOverlappingTimeBlocksOptimized(
                timeBlocks: timeBlocks,
                gridStart: gridBlock.startTime,
                gridEnd: gridBlock.endTime
            )
            
            // 计算强度（这里可以添加更复杂的计算逻辑）
            let intensity = calculateOptimizedIntensity(
                for: overlappingBlocks,
                in: gridBlock.startTime...gridBlock.endTime
            )
            
            // 返回更新后的网格块
            return HeatmapGridBlock(
                index: gridBlock.index,
                hour: gridBlock.hour,
                quarterHour: gridBlock.quarterHour,
                startTime: gridBlock.startTime,
                endTime: gridBlock.endTime,
                intensity: intensity,
                intensityLevel: intensityLevelFromIntensity(intensity),
                hasBeautifulMoment: overlappingBlocks.contains { $0.isBeautifulMoment },
                timeBlocks: overlappingBlocks,
                activities: overlappingBlocks.compactMap { $0.taggedActivity },
                categories: overlappingBlocks.compactMap { $0.category }
            )
        }
    }
    
    /// 优化的重叠时间块查找
    private func findOverlappingTimeBlocksOptimized(
        timeBlocks: [TimeBlock],
        gridStart: Date,
        gridEnd: Date
    ) -> [TimeBlock] {
        // 使用二分查找优化查找性能
        let startIndex = timeBlocks.binarySearch { timeBlock in
            guard let blockEnd = timeBlock.endTime else { return .orderedAscending }
            return blockEnd.compare(gridStart)
        }
        
        let endIndex = timeBlocks.binarySearch { timeBlock in
            guard let blockStart = timeBlock.startTime else { return .orderedDescending }
            return blockStart.compare(gridEnd)
        }
        
        let searchRange = startIndex..<min(endIndex + 1, timeBlocks.count)
        
        return Array(timeBlocks[searchRange]).filter { timeBlock in
            guard let blockStart = timeBlock.startTime,
                  let blockEnd = timeBlock.endTime else { return false }
            return blockStart < gridEnd && blockEnd > gridStart
        }
    }
    
    /// 优化的强度计算
    private func calculateOptimizedIntensity(
        for timeBlocks: [TimeBlock],
        in timeRange: ClosedRange<Date>
    ) -> Double {
        guard !timeBlocks.isEmpty else { return 0.0 }
        
        let gridDuration = timeRange.upperBound.timeIntervalSince(timeRange.lowerBound)
        var totalWeightedIntensity: Double = 0.0
        var totalOverlapDuration: TimeInterval = 0.0
        
        // 使用向量化计算优化性能
        for timeBlock in timeBlocks {
            guard let blockStart = timeBlock.startTime,
                  let blockEnd = timeBlock.endTime else { continue }
            
            let overlapStart = max(blockStart, timeRange.lowerBound)
            let overlapEnd = min(blockEnd, timeRange.upperBound)
            let overlapDuration = overlapEnd.timeIntervalSince(overlapStart)
            
            if overlapDuration > 0 {
                let blockIntensity = timeBlock.averageFocusIntensity
                totalWeightedIntensity += blockIntensity * overlapDuration
                totalOverlapDuration += overlapDuration
            }
        }
        
        let averageIntensity = totalOverlapDuration > 0 ? totalWeightedIntensity / totalOverlapDuration : 0.0
        let coverageRatio = min(1.0, totalOverlapDuration / gridDuration)
        
        return averageIntensity * coverageRatio
    }
    
    /// 从强度值计算强度等级
    private func intensityLevelFromIntensity(_ intensity: Double) -> HeatmapEngine.IntensityLevel {
        switch intensity {
        case 0.0:
            return .none
        case 0.0..<0.2:
            return .low
        case 0.2..<0.5:
            return .medium
        case 0.5..<0.8:
            return .high
        default:
            return .veryHigh
        }
    }
    
    /// 设置内存压力观察者
    private func setupMemoryPressureObserver() {
        memoryPressureObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryPressure()
        }
    }
    
    /// 处理内存压力
    private func handleMemoryPressure() {
        print("⚠️ 收到内存警告，暂停操作并清理缓存")
        operationQueue.isSuspended = true
        
        // 延迟恢复操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.operationQueue.isSuspended = false
        }
    }
    
    /// 检查是否应该因内存压力暂停
    private func shouldPauseForMemoryPressure() -> Bool {
        return getMemoryUsage() > OptimizationConfig.memoryWarningThreshold
    }
    
    /// 暂停以缓解内存压力
    private func pauseForMemoryRelief() async {
        try? await Task.sleep(nanoseconds: 100_000_000) // 暂停100ms
    }
    
    /// 获取当前内存使用率
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
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size)
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
            return usedMemory / totalMemory
        }
        
        return 0.0
    }
}

// MARK: - Extensions

extension Array {
    /// 将数组分块
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
    
    /// 二分查找
    func binarySearch(predicate: (Element) -> ComparisonResult) -> Int {
        var low = 0
        var high = count - 1
        
        while low <= high {
            let mid = (low + high) / 2
            let comparison = predicate(self[mid])
            
            switch comparison {
            case .orderedSame:
                return mid
            case .orderedAscending:
                low = mid + 1
            case .orderedDescending:
                high = mid - 1
            }
        }
        
        return low
    }
}

import UIKit
import mach