import Foundation
import CoreData
import Combine

/// HeatmapEngine - 热力图引擎
/// 负责生成GitHub风格的时间热力图数据
/// 支持24小时×15分钟网格，5级强度计算，美好时刻特殊显示
@MainActor
class HeatmapEngine: ObservableObject {
    
    // MARK: - Constants
    
    /// 时间网格配置
    private enum GridConfig {
        static let hoursPerDay = 24
        static let minutesPerHour = 60
        static let gridIntervalMinutes = 15  // 15分钟网格
        static let blocksPerHour = minutesPerHour / gridIntervalMinutes  // 4个块/小时
        static let blocksPerDay = hoursPerDay * blocksPerHour  // 96个块/天
        static let secondsPerBlock = gridIntervalMinutes * 60  // 900秒/块
    }
    
    /// GitHub风格的5级强度等级
    enum IntensityLevel: Int, CaseIterable {
        case none = 0      // 无活动
        case low = 1       // 低强度
        case medium = 2    // 中等强度
        case high = 3      // 高强度
        case veryHigh = 4  // 极高强度
        
        var color: String {
            switch self {
            case .none: return "#ebedf0"      // GitHub灰色
            case .low: return "#9be9a8"       // GitHub浅绿色
            case .medium: return "#40c463"    // GitHub中绿色
            case .high: return "#30a14e"      // GitHub深绿色
            case .veryHigh: return "#216e39"  // GitHub极深绿色
            }
        }
        
        var description: String {
            switch self {
            case .none: return "无活动"
            case .low: return "低强度"
            case .medium: return "中等强度"
            case .high: return "高强度"
            case .veryHigh: return "极高强度"
            }
        }
    }
    
    // MARK: - Published Properties
    
    @Published var isGenerating: Bool = false
    @Published var cacheHitRate: Double = 0.0
    
    // MARK: - Private Properties
    
    private let viewContext: NSManagedObjectContext
    private var heatmapCache: [String: HeatmapData] = [:]
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private let maxCacheSize = 30  // 缓存30天的数据
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    // MARK: - Public Methods
    
    /// 生成指定日期的热力图数据
    /// - Parameter date: 目标日期
    /// - Returns: 热力图数据
    func generateHeatmapData(for date: Date) async -> HeatmapData {
        let cacheKey = cacheKey(for: date)
        
        // 检查缓存
        if let cachedData = heatmapCache[cacheKey] {
            cacheHits += 1
            updateCacheHitRate()
            return cachedData
        }
        
        cacheMisses += 1
        updateCacheHitRate()
        
        isGenerating = true
        defer { isGenerating = false }
        
        // 生成新的热力图数据
        let heatmapData = await generateHeatmapDataInternal(for: date)
        
        // 缓存数据
        cacheHeatmapData(heatmapData, for: cacheKey)
        
        return heatmapData
    }
    
    /// 生成多日热力图数据（批量处理）
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 日期到热力图数据的映射
    func generateHeatmapData(from startDate: Date, to endDate: Date) async -> [Date: HeatmapData] {
        var result: [Date: HeatmapData] = [:]
        let calendar = Calendar.current
        
        var currentDate = startDate
        while currentDate <= endDate {
            let heatmapData = await generateHeatmapData(for: currentDate)
            result[currentDate] = heatmapData
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return result
    }
    
    /// 清除缓存
    func clearCache() {
        heatmapCache.removeAll()
        cacheHits = 0
        cacheMisses = 0
        updateCacheHitRate()
    }
    
    /// 预热缓存（预加载最近几天的数据）
    /// - Parameter days: 预加载天数
    func warmupCache(days: Int = 7) async {
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            _ = await generateHeatmapData(for: date)
        }
    }
    
    // MARK: - Private Methods
    
    /// 内部热力图数据生成逻辑
    private func generateHeatmapDataInternal(for date: Date) async -> HeatmapData {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // 获取当天的时间块数据
        let timeBlocks = await fetchTimeBlocks(from: startOfDay, to: endOfDay)
        
        // 生成15分钟网格
        let gridBlocks = generateGridBlocks(for: startOfDay, timeBlocks: timeBlocks)
        
        // 计算统计信息
        let stats = calculateDayStats(from: gridBlocks)
        
        return HeatmapData(
            date: date,
            gridBlocks: gridBlocks,
            stats: stats,
            generatedAt: Date()
        )
    }
    
    /// 获取指定时间范围的时间块
    private func fetchTimeBlocks(from startDate: Date, to endDate: Date) async -> [TimeBlock] {
        return await withCheckedContinuation { continuation in
            let request: NSFetchRequest<TimeBlock> = TimeBlock.fetchRequest()
            request.predicate = NSPredicate(
                format: "startTime >= %@ AND startTime < %@",
                startDate as NSDate,
                endDate as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeBlock.startTime, ascending: true)]
            
            do {
                let timeBlocks = try viewContext.fetch(request)
                continuation.resume(returning: timeBlocks)
            } catch {
                print("❌ 获取时间块失败: \(error)")
                continuation.resume(returning: [])
            }
        }
    }
    
    /// 生成15分钟网格块
    private func generateGridBlocks(for startOfDay: Date, timeBlocks: [TimeBlock]) -> [HeatmapGridBlock] {
        var gridBlocks: [HeatmapGridBlock] = []
        
        for blockIndex in 0..<GridConfig.blocksPerDay {
            let blockStartTime = startOfDay.addingTimeInterval(Double(blockIndex * GridConfig.secondsPerBlock))
            let blockEndTime = blockStartTime.addingTimeInterval(Double(GridConfig.secondsPerBlock))
            
            // 查找与该网格块重叠的时间块
            let overlappingBlocks = findOverlappingTimeBlocks(
                timeBlocks: timeBlocks,
                gridStart: blockStartTime,
                gridEnd: blockEndTime
            )
            
            // 计算该网格块的强度和属性
            let gridBlock = createGridBlock(
                index: blockIndex,
                startTime: blockStartTime,
                endTime: blockEndTime,
                overlappingBlocks: overlappingBlocks
            )
            
            gridBlocks.append(gridBlock)
        }
        
        return gridBlocks
    }
    
    /// 查找与网格块重叠的时间块
    private func findOverlappingTimeBlocks(
        timeBlocks: [TimeBlock],
        gridStart: Date,
        gridEnd: Date
    ) -> [TimeBlock] {
        return timeBlocks.filter { timeBlock in
            guard let blockStart = timeBlock.startTime,
                  let blockEnd = timeBlock.endTime else { return false }
            
            // 检查时间重叠：块开始时间 < 网格结束时间 && 块结束时间 > 网格开始时间
            return blockStart < gridEnd && blockEnd > gridStart
        }
    }
    
    /// 创建网格块
    private func createGridBlock(
        index: Int,
        startTime: Date,
        endTime: Date,
        overlappingBlocks: [TimeBlock]
    ) -> HeatmapGridBlock {
        let hour = index / GridConfig.blocksPerHour
        let quarterHour = index % GridConfig.blocksPerHour
        
        // 计算强度
        let intensity = calculateIntensity(for: overlappingBlocks, in: startTime...endTime)
        let intensityLevel = calculateIntensityLevel(from: intensity)
        
        // 检查美好时刻
        let hasBeautifulMoment = overlappingBlocks.contains { $0.isBeautifulMoment }
        
        // 获取活动信息
        let activities = overlappingBlocks.compactMap { $0.taggedActivity }.filter { !$0.isEmpty }
        let categories = overlappingBlocks.compactMap { $0.category }.filter { !$0.isEmpty }
        
        return HeatmapGridBlock(
            index: index,
            hour: hour,
            quarterHour: quarterHour,
            startTime: startTime,
            endTime: endTime,
            intensity: intensity,
            intensityLevel: intensityLevel,
            hasBeautifulMoment: hasBeautifulMoment,
            timeBlocks: overlappingBlocks,
            activities: Array(Set(activities)),  // 去重
            categories: Array(Set(categories))   // 去重
        )
    }
    
    /// 计算强度值（0.0 - 1.0）
    private func calculateIntensity(for timeBlocks: [TimeBlock], in timeRange: ClosedRange<Date>) -> Double {
        guard !timeBlocks.isEmpty else { return 0.0 }
        
        let gridDuration = timeRange.upperBound.timeIntervalSince(timeRange.lowerBound)
        var totalWeightedIntensity: Double = 0.0
        var totalOverlapDuration: TimeInterval = 0.0
        
        for timeBlock in timeBlocks {
            guard let blockStart = timeBlock.startTime,
                  let blockEnd = timeBlock.endTime else { continue }
            
            // 计算重叠时间
            let overlapStart = max(blockStart, timeRange.lowerBound)
            let overlapEnd = min(blockEnd, timeRange.upperBound)
            let overlapDuration = overlapEnd.timeIntervalSince(overlapStart)
            
            if overlapDuration > 0 {
                let blockIntensity = timeBlock.averageFocusIntensity
                totalWeightedIntensity += blockIntensity * overlapDuration
                totalOverlapDuration += overlapDuration
            }
        }
        
        // 计算加权平均强度
        let averageIntensity = totalOverlapDuration > 0 ? totalWeightedIntensity / totalOverlapDuration : 0.0
        
        // 根据覆盖率调整强度
        let coverageRatio = min(1.0, totalOverlapDuration / gridDuration)
        
        return averageIntensity * coverageRatio
    }
    
    /// 将强度值转换为GitHub风格的5级等级
    private func calculateIntensityLevel(from intensity: Double) -> IntensityLevel {
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
    
    /// 计算当天统计信息
    private func calculateDayStats(from gridBlocks: [HeatmapGridBlock]) -> HeatmapDayStats {
        let activeBlocks = gridBlocks.filter { $0.intensityLevel != .none }
        let beautifulMomentBlocks = gridBlocks.filter { $0.hasBeautifulMoment }
        
        let totalIntensity = gridBlocks.reduce(0.0) { $0 + $1.intensity }
        let averageIntensity = totalIntensity / Double(gridBlocks.count)
        
        // 计算强度分布
        var intensityDistribution: [IntensityLevel: Int] = [:]
        for level in IntensityLevel.allCases {
            intensityDistribution[level] = gridBlocks.filter { $0.intensityLevel == level }.count
        }
        
        // 计算活跃时段
        let activeHours = Set(activeBlocks.map { $0.hour })
        
        // 计算最高强度时段
        let peakBlock = gridBlocks.max { $0.intensity < $1.intensity }
        
        return HeatmapDayStats(
            totalBlocks: gridBlocks.count,
            activeBlocks: activeBlocks.count,
            beautifulMomentBlocks: beautifulMomentBlocks.count,
            averageIntensity: averageIntensity,
            peakIntensity: peakBlock?.intensity ?? 0.0,
            peakTime: peakBlock?.startTime,
            intensityDistribution: intensityDistribution,
            activeHours: activeHours.count,
            totalActiveDuration: TimeInterval(activeBlocks.count * GridConfig.secondsPerBlock)
        )
    }
    
    /// 生成缓存键
    private func cacheKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// 缓存热力图数据
    private func cacheHeatmapData(_ data: HeatmapData, for key: String) {
        // 如果缓存已满，移除最旧的数据
        if heatmapCache.count >= maxCacheSize {
            let oldestKey = heatmapCache.min { $0.value.generatedAt < $1.value.generatedAt }?.key
            if let keyToRemove = oldestKey {
                heatmapCache.removeValue(forKey: keyToRemove)
            }
        }
        
        heatmapCache[key] = data
    }
    
    /// 更新缓存命中率
    private func updateCacheHitRate() {
        let totalRequests = cacheHits + cacheMisses
        cacheHitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
    }
}

// MARK: - Supporting Types

/// 热力图数据
struct HeatmapData {
    let date: Date
    let gridBlocks: [HeatmapGridBlock]
    let stats: HeatmapDayStats
    let generatedAt: Date
    
    /// 获取指定小时的网格块
    func gridBlocks(for hour: Int) -> [HeatmapGridBlock] {
        return gridBlocks.filter { $0.hour == hour }
    }
    
    /// 获取指定时间范围的网格块
    func gridBlocks(from startHour: Int, to endHour: Int) -> [HeatmapGridBlock] {
        return gridBlocks.filter { $0.hour >= startHour && $0.hour <= endHour }
    }
}

/// 热力图网格块
struct HeatmapGridBlock: Identifiable {
    let id = UUID()
    let index: Int              // 在一天中的索引 (0-95)
    let hour: Int              // 小时 (0-23)
    let quarterHour: Int       // 15分钟块在小时内的索引 (0-3)
    let startTime: Date        // 开始时间
    let endTime: Date          // 结束时间
    let intensity: Double      // 强度值 (0.0-1.0)
    let intensityLevel: HeatmapEngine.IntensityLevel  // 强度等级
    let hasBeautifulMoment: Bool  // 是否包含美好时刻
    let timeBlocks: [TimeBlock]   // 关联的时间块
    let activities: [String]      // 活动列表
    let categories: [String]      // 分类列表
    
    /// 格式化时间范围
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    /// 是否为空块
    var isEmpty: Bool {
        return intensityLevel == .none
    }
    
    /// 获取显示颜色
    var displayColor: String {
        return hasBeautifulMoment ? "#FFD700" : intensityLevel.color  // 美好时刻用金色
    }
    
    /// 获取工具提示文本
    var tooltipText: String {
        var components: [String] = []
        
        components.append(timeRangeString)
        components.append("强度: \(intensityLevel.description)")
        
        if !activities.isEmpty {
            components.append("活动: \(activities.joined(separator: ", "))")
        }
        
        if hasBeautifulMoment {
            components.append("✨ 美好时刻")
        }
        
        return components.joined(separator: "\n")
    }
}

/// 热力图日统计
struct HeatmapDayStats {
    let totalBlocks: Int                                    // 总块数
    let activeBlocks: Int                                   // 活跃块数
    let beautifulMomentBlocks: Int                         // 美好时刻块数
    let averageIntensity: Double                           // 平均强度
    let peakIntensity: Double                              // 峰值强度
    let peakTime: Date?                                    // 峰值时间
    let intensityDistribution: [HeatmapEngine.IntensityLevel: Int]  // 强度分布
    let activeHours: Int                                   // 活跃小时数
    let totalActiveDuration: TimeInterval                  // 总活跃时长
    
    /// 活跃率
    var activityRate: Double {
        return totalBlocks > 0 ? Double(activeBlocks) / Double(totalBlocks) : 0.0
    }
    
    /// 美好时刻率
    var beautifulMomentRate: Double {
        return activeBlocks > 0 ? Double(beautifulMomentBlocks) / Double(activeBlocks) : 0.0
    }
    
    /// 格式化总活跃时长
    var formattedActiveDuration: String {
        let hours = Int(totalActiveDuration) / 3600
        let minutes = Int(totalActiveDuration.truncatingRemainder(dividingBy: 3600)) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    /// 格式化峰值时间
    var formattedPeakTime: String? {
        guard let peakTime = peakTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: peakTime)
    }
}