import Foundation
import CoreData
import Combine

/// LifeAnalyzer - 人生分析引擎
/// 提供时间使用的深度分析和洞察，类似代码质量分析工具
/// 帮助用户理解和优化自己的时间投入模式
@MainActor
class LifeAnalyzer: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAnalyzing: Bool = false
    @Published var lastAnalysisDate: Date?
    @Published var analysisProgress: Double = 0.0
    
    // MARK: - Private Properties
    
    private let viewContext: NSManagedObjectContext
    private let timeBlockManager: TimeBlockManager
    private let tagManager: TimeTagManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    
    private struct AnalysisConfig {
        static let minDataPointsForAnalysis = 7  // 至少7天数据
        static let trendAnalysisDays = 30        // 趋势分析天数
        static let patternDetectionThreshold = 0.7  // 模式检测阈值
        static let suggestionConfidenceThreshold = 0.6  // 建议置信度阈值
    }
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        self.timeBlockManager = TimeBlockManager(viewContext: viewContext)
        self.tagManager = TimeTagManager(viewContext: viewContext)
    }
    
    // MARK: - Public Analysis Methods
    
    /// 生成每日分析报告
    /// - Parameter date: 分析日期
    /// - Returns: 每日分析报告
    func generateDailyAnalysis(for date: Date) async -> DailyAnalysisReport {
        isAnalyzing = true
        analysisProgress = 0.0
        
        defer {
            isAnalyzing = false
            lastAnalysisDate = Date()
        }
        
        // 获取当日数据
        let timeBlocks = await getTimeBlocks(for: date)
        analysisProgress = 0.2
        
        // 基础统计
        let basicStats = calculateDailyBasicStats(timeBlocks: timeBlocks)
        analysisProgress = 0.4
        
        // 专注强度分析
        let focusAnalysis = analyzeDailyFocusIntensity(timeBlocks: timeBlocks)
        analysisProgress = 0.6
        
        // 标签使用分析
        let tagAnalysis = analyzeDailyTagUsage(timeBlocks: timeBlocks)
        analysisProgress = 0.8
        
        // 生成建议
        let suggestions = generateDailySuggestions(
            basicStats: basicStats,
            focusAnalysis: focusAnalysis,
            tagAnalysis: tagAnalysis
        )
        analysisProgress = 1.0
        
        return DailyAnalysisReport(
            date: date,
            basicStats: basicStats,
            focusAnalysis: focusAnalysis,
            tagAnalysis: tagAnalysis,
            suggestions: suggestions,
            generatedAt: Date()
        )
    }
    
    /// 生成每周分析报告
    /// - Parameter weekStartDate: 周开始日期
    /// - Returns: 每周分析报告
    func generateWeeklyAnalysis(for weekStartDate: Date) async -> WeeklyAnalysisReport {
        isAnalyzing = true
        analysisProgress = 0.0
        
        defer {
            isAnalyzing = false
            lastAnalysisDate = Date()
        }
        
        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate)!
        
        // 获取一周数据
        let timeBlocks = await getTimeBlocks(from: weekStartDate, to: weekEndDate)
        analysisProgress = 0.2
        
        // 每日数据分组
        let dailyGroups = groupTimeBlocksByDay(timeBlocks: timeBlocks)
        analysisProgress = 0.4
        
        // 周统计
        let weeklyStats = calculateWeeklyStats(dailyGroups: dailyGroups)
        analysisProgress = 0.6
        
        // 趋势分析
        let trendAnalysis = analyzeWeeklyTrends(dailyGroups: dailyGroups)
        analysisProgress = 0.8
        
        // 模式识别
        let patterns = identifyWeeklyPatterns(dailyGroups: dailyGroups)
        
        // 生成建议
        let suggestions = generateWeeklySuggestions(
            weeklyStats: weeklyStats,
            trends: trendAnalysis,
            patterns: patterns
        )
        analysisProgress = 1.0
        
        return WeeklyAnalysisReport(
            weekStartDate: weekStartDate,
            weekEndDate: weekEndDate,
            weeklyStats: weeklyStats,
            trendAnalysis: trendAnalysis,
            patterns: patterns,
            suggestions: suggestions,
            generatedAt: Date()
        )
    }
    
    /// 生成使用模式分析
    /// - Parameter days: 分析天数
    /// - Returns: 使用模式分析
    func analyzeUsagePatterns(days: Int = 30) async -> UsagePatternAnalysis {
        isAnalyzing = true
        analysisProgress = 0.0
        
        defer {
            isAnalyzing = false
            lastAnalysisDate = Date()
        }
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        
        // 获取历史数据
        let timeBlocks = await getTimeBlocks(from: startDate, to: endDate)
        analysisProgress = 0.3
        
        // 时间模式分析
        let timePatterns = analyzeTimePatterns(timeBlocks: timeBlocks)
        analysisProgress = 0.5
        
        // 活动模式分析
        let activityPatterns = analyzeActivityPatterns(timeBlocks: timeBlocks)
        analysisProgress = 0.7
        
        // 专注模式分析
        let focusPatterns = analyzeFocusPatterns(timeBlocks: timeBlocks)
        analysisProgress = 0.9
        
        // 异常检测
        let anomalies = detectAnomalies(timeBlocks: timeBlocks)
        analysisProgress = 1.0
        
        return UsagePatternAnalysis(
            analysisDateRange: DateInterval(start: startDate, end: endDate),
            timePatterns: timePatterns,
            activityPatterns: activityPatterns,
            focusPatterns: focusPatterns,
            anomalies: anomalies,
            generatedAt: Date()
        )
    }
    
    /// 生成优化建议
    /// - Parameter analysisType: 分析类型
    /// - Returns: 优化建议列表
    func generateOptimizationSuggestions(
        based analysisType: AnalysisType = .comprehensive
    ) async -> [OptimizationSuggestion] {
        
        switch analysisType {
        case .daily:
            let todayAnalysis = await generateDailyAnalysis(for: Date())
            return todayAnalysis.suggestions
            
        case .weekly:
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            let weeklyAnalysis = await generateWeeklyAnalysis(for: weekStart)
            return weeklyAnalysis.suggestions
            
        case .comprehensive:
            return await generateComprehensiveSuggestions()
        }
    }
    
    // MARK: - Private Analysis Methods
    
    /// 获取指定日期的时间块
    private func getTimeBlocks(for date: Date) async -> [TimeBlock] {
        return await withCheckedContinuation { continuation in
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let request: NSFetchRequest<TimeBlock> = TimeBlock.fetchRequest()
            request.predicate = NSPredicate(
                format: "startTime >= %@ AND startTime < %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeBlock.startTime, ascending: true)]
            
            do {
                let blocks = try viewContext.fetch(request)
                continuation.resume(returning: blocks)
            } catch {
                print("❌ 获取时间块失败: \(error)")
                continuation.resume(returning: [])
            }
        }
    }
    
    /// 获取时间范围内的时间块
    private func getTimeBlocks(from startDate: Date, to endDate: Date) async -> [TimeBlock] {
        return await withCheckedContinuation { continuation in
            let request: NSFetchRequest<TimeBlock> = TimeBlock.fetchRequest()
            request.predicate = NSPredicate(
                format: "startTime >= %@ AND startTime <= %@",
                startDate as NSDate,
                endDate as NSDate
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeBlock.startTime, ascending: true)]
            
            do {
                let blocks = try viewContext.fetch(request)
                continuation.resume(returning: blocks)
            } catch {
                print("❌ 获取时间范围内的时间块失败: \(error)")
                continuation.resume(returning: [])
            }
        }
    }
    
    /// 计算每日基础统计
    private func calculateDailyBasicStats(timeBlocks: [TimeBlock]) -> DailyBasicStats {
        let totalBlocks = timeBlocks.count
        let totalDuration = timeBlocks.reduce(0.0) { $0 + $1.duration }
        let averageFocusIntensity = timeBlocks.isEmpty ? 0.0 : 
            timeBlocks.reduce(0.0) { $0 + $1.averageFocusIntensity } / Double(timeBlocks.count)
        
        let taggedBlocks = timeBlocks.filter { $0.isTagged }.count
        let beautifulMoments = timeBlocks.filter { $0.isBeautifulMoment }.count
        
        // 计算活跃时间段
        let activeHours = Set(timeBlocks.compactMap { block -> Int? in
            guard let startTime = block.startTime else { return nil }
            return Calendar.current.component(.hour, from: startTime)
        }).count
        
        return DailyBasicStats(
            totalBlocks: totalBlocks,
            totalDuration: totalDuration,
            averageFocusIntensity: averageFocusIntensity,
            taggedBlocks: taggedBlocks,
            beautifulMoments: beautifulMoments,
            activeHours: activeHours,
            productivityScore: calculateProductivityScore(
                focusIntensity: averageFocusIntensity,
                taggedRatio: totalBlocks > 0 ? Double(taggedBlocks) / Double(totalBlocks) : 0.0,
                beautifulMomentsRatio: totalBlocks > 0 ? Double(beautifulMoments) / Double(totalBlocks) : 0.0
            )
        )
    }  
  
    /// 分析每日专注强度
    private func analyzeDailyFocusIntensity(timeBlocks: [TimeBlock]) -> DailyFocusAnalysis {
        guard !timeBlocks.isEmpty else {
            return DailyFocusAnalysis(
                averageIntensity: 0.0,
                peakIntensity: 0.0,
                peakTime: nil,
                lowIntensityPeriods: [],
                focusDistribution: [:],
                focusEfficiency: 0.0
            )
        }
        
        let intensities = timeBlocks.map { $0.averageFocusIntensity }
        let averageIntensity = intensities.reduce(0, +) / Double(intensities.count)
        let peakIntensity = intensities.max() ?? 0.0
        
        // 找到峰值时间
        let peakBlock = timeBlocks.max { $0.averageFocusIntensity < $1.averageFocusIntensity }
        let peakTime = peakBlock?.startTime
        
        // 识别低强度时段
        let lowIntensityPeriods = timeBlocks.filter { $0.averageFocusIntensity < 0.3 }
            .compactMap { $0.startTime }
        
        // 专注强度分布
        var focusDistribution: [FocusIntensityRange: Int] = [:]
        for block in timeBlocks {
            let range = FocusIntensityRange.from(intensity: block.averageFocusIntensity)
            focusDistribution[range, default: 0] += 1
        }
        
        // 专注效率（高强度时间占比）
        let highIntensityBlocks = timeBlocks.filter { $0.averageFocusIntensity >= 0.7 }.count
        let focusEfficiency = Double(highIntensityBlocks) / Double(timeBlocks.count)
        
        return DailyFocusAnalysis(
            averageIntensity: averageIntensity,
            peakIntensity: peakIntensity,
            peakTime: peakTime,
            lowIntensityPeriods: lowIntensityPeriods,
            focusDistribution: focusDistribution,
            focusEfficiency: focusEfficiency
        )
    }
    
    /// 分析每日标签使用
    private func analyzeDailyTagUsage(timeBlocks: [TimeBlock]) -> DailyTagAnalysis {
        var tagUsage: [String: Int] = [:]
        var categoryUsage: [String: TimeInterval] = [:]
        
        for block in timeBlocks {
            // 统计标签使用
            for tag in block.tagsArray {
                if let tagName = tag.name {
                    tagUsage[tagName, default: 0] += 1
                }
                
                if let category = tag.category {
                    categoryUsage[category, default: 0] += block.duration
                }
            }
        }
        
        let mostUsedTag = tagUsage.max { $0.value < $1.value }?.key
        let dominantCategory = categoryUsage.max { $0.value < $1.value }?.key
        
        let taggedBlocks = timeBlocks.filter { $0.isTagged }.count
        let taggingRate = timeBlocks.isEmpty ? 0.0 : Double(taggedBlocks) / Double(timeBlocks.count)
        
        return DailyTagAnalysis(
            tagUsage: tagUsage,
            categoryUsage: categoryUsage,
            mostUsedTag: mostUsedTag,
            dominantCategory: dominantCategory,
            taggingRate: taggingRate,
            uniqueTagsUsed: tagUsage.keys.count
        )
    }
    
    /// 生成每日建议
    private func generateDailySuggestions(
        basicStats: DailyBasicStats,
        focusAnalysis: DailyFocusAnalysis,
        tagAnalysis: DailyTagAnalysis
    ) -> [OptimizationSuggestion] {
        var suggestions: [OptimizationSuggestion] = []
        
        // 基于专注强度的建议
        if focusAnalysis.averageIntensity < 0.5 {
            suggestions.append(OptimizationSuggestion(
                type: .focusImprovement,
                priority: .high,
                title: "提升专注强度",
                description: "今日平均专注强度较低(\(String(format: "%.1f%%", focusAnalysis.averageIntensity * 100)))，建议减少干扰因素",
                actionItems: [
                    "关闭不必要的通知",
                    "使用专注模式或番茄工作法",
                    "优化工作环境"
                ],
                confidence: 0.8
            ))
        }
        
        // 基于标签使用的建议
        if tagAnalysis.taggingRate < 0.7 {
            suggestions.append(OptimizationSuggestion(
                type: .timeTracking,
                priority: .medium,
                title: "完善时间标记",
                description: "今日有\(String(format: "%.1f%%", (1 - tagAnalysis.taggingRate) * 100))的时间未标记，建议及时标记活动",
                actionItems: [
                    "设置定时提醒标记时间",
                    "使用快速标签功能",
                    "回顾并补充未标记的时间"
                ],
                confidence: 0.7
            ))
        }
        
        // 基于美好时刻的建议
        if basicStats.beautifulMoments == 0 {
            suggestions.append(OptimizationSuggestion(
                type: .wellbeing,
                priority: .low,
                title: "记录美好时刻",
                description: "今日还没有记录美好时刻，试着发现并标记生活中的亮点",
                actionItems: [
                    "留意工作中的成就感",
                    "记录与他人的美好互动",
                    "标记学习新知识的时刻"
                ],
                confidence: 0.6
            ))
        }
        
        return suggestions.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    /// 按天分组时间块
    private func groupTimeBlocksByDay(timeBlocks: [TimeBlock]) -> [Date: [TimeBlock]] {
        let calendar = Calendar.current
        var groups: [Date: [TimeBlock]] = [:]
        
        for block in timeBlocks {
            guard let startTime = block.startTime else { continue }
            let dayKey = calendar.startOfDay(for: startTime)
            groups[dayKey, default: []].append(block)
        }
        
        return groups
    }
    
    /// 计算每周统计
    private func calculateWeeklyStats(dailyGroups: [Date: [TimeBlock]]) -> WeeklyStats {
        let allBlocks = dailyGroups.values.flatMap { $0 }
        
        let totalDuration = allBlocks.reduce(0.0) { $0 + $1.duration }
        let averageDailyDuration = totalDuration / 7.0
        let averageFocusIntensity = allBlocks.isEmpty ? 0.0 :
            allBlocks.reduce(0.0) { $0 + $1.averageFocusIntensity } / Double(allBlocks.count)
        
        let activeDays = dailyGroups.filter { !$1.isEmpty }.count
        let totalBeautifulMoments = allBlocks.filter { $0.isBeautifulMoment }.count
        
        // 计算每日变化
        let dailyDurations = dailyGroups.keys.sorted().map { date in
            dailyGroups[date]?.reduce(0.0) { $0 + $1.duration } ?? 0.0
        }
        let consistency = calculateConsistency(values: dailyDurations)
        
        return WeeklyStats(
            totalDuration: totalDuration,
            averageDailyDuration: averageDailyDuration,
            averageFocusIntensity: averageFocusIntensity,
            activeDays: activeDays,
            totalBeautifulMoments: totalBeautifulMoments,
            consistency: consistency,
            dailyDurations: dailyDurations
        )
    }
    
    /// 分析每周趋势
    private func analyzeWeeklyTrends(dailyGroups: [Date: [TimeBlock]]) -> WeeklyTrendAnalysis {
        let sortedDates = dailyGroups.keys.sorted()
        
        // 时长趋势
        let durationTrend = calculateTrend(
            values: sortedDates.map { date in
                dailyGroups[date]?.reduce(0.0) { $0 + $1.duration } ?? 0.0
            }
        )
        
        // 专注强度趋势
        let focusTrend = calculateTrend(
            values: sortedDates.map { date in
                let blocks = dailyGroups[date] ?? []
                return blocks.isEmpty ? 0.0 : blocks.reduce(0.0) { $0 + $1.averageFocusIntensity } / Double(blocks.count)
            }
        )
        
        // 活动量趋势
        let activityTrend = calculateTrend(
            values: sortedDates.map { date in
                Double(dailyGroups[date]?.count ?? 0)
            }
        )
        
        return WeeklyTrendAnalysis(
            durationTrend: durationTrend,
            focusTrend: focusTrend,
            activityTrend: activityTrend
        )
    }
    
    /// 识别每周模式
    private func identifyWeeklyPatterns(dailyGroups: [Date: [TimeBlock]]) -> [WeeklyPattern] {
        var patterns: [WeeklyPattern] = []
        
        // 工作日vs周末模式
        let weekdayBlocks = dailyGroups.filter { date, _ in
            let weekday = Calendar.current.component(.weekday, from: date)
            return weekday >= 2 && weekday <= 6 // 周一到周五
        }.values.flatMap { $0 }
        
        let weekendBlocks = dailyGroups.filter { date, _ in
            let weekday = Calendar.current.component(.weekday, from: date)
            return weekday == 1 || weekday == 7 // 周六周日
        }.values.flatMap { $0 }
        
        if !weekdayBlocks.isEmpty && !weekendBlocks.isEmpty {
            let weekdayAvgDuration = weekdayBlocks.reduce(0.0) { $0 + $1.duration } / Double(weekdayBlocks.count)
            let weekendAvgDuration = weekendBlocks.reduce(0.0) { $0 + $1.duration } / Double(weekendBlocks.count)
            
            if abs(weekdayAvgDuration - weekendAvgDuration) > 1800 { // 30分钟差异
                patterns.append(WeeklyPattern(
                    type: .workLifeBalance,
                    description: weekdayAvgDuration > weekendAvgDuration ? "工作日更活跃" : "周末更活跃",
                    confidence: 0.8
                ))
            }
        }
        
        return patterns
    }
    
    /// 生成每周建议
    private func generateWeeklySuggestions(
        weeklyStats: WeeklyStats,
        trends: WeeklyTrendAnalysis,
        patterns: [WeeklyPattern]
    ) -> [OptimizationSuggestion] {
        var suggestions: [OptimizationSuggestion] = []
        
        // 基于一致性的建议
        if weeklyStats.consistency < 0.6 {
            suggestions.append(OptimizationSuggestion(
                type: .consistency,
                priority: .medium,
                title: "提高时间使用一致性",
                description: "本周时间使用波动较大，建议建立更稳定的作息规律",
                actionItems: [
                    "设定固定的工作时间",
                    "建立晨间和晚间例行程序",
                    "使用日程规划工具"
                ],
                confidence: 0.7
            ))
        }
        
        // 基于趋势的建议
        if trends.focusTrend == .declining {
            suggestions.append(OptimizationSuggestion(
                type: .focusImprovement,
                priority: .high,
                title: "专注强度下降趋势",
                description: "本周专注强度呈下降趋势，需要调整策略",
                actionItems: [
                    "检查是否有新的干扰因素",
                    "调整工作环境和方法",
                    "考虑增加休息时间"
                ],
                confidence: 0.8
            ))
        }
        
        return suggestions
    }
    
    /// 分析时间模式
    private func analyzeTimePatterns(timeBlocks: [TimeBlock]) -> TimePatternAnalysis {
        var hourlyActivity: [Int: Int] = [:]
        var weekdayActivity: [Int: Int] = [:]
        
        for block in timeBlocks {
            guard let startTime = block.startTime else { continue }
            let calendar = Calendar.current
            
            let hour = calendar.component(.hour, from: startTime)
            let weekday = calendar.component(.weekday, from: startTime)
            
            hourlyActivity[hour, default: 0] += 1
            weekdayActivity[weekday, default: 0] += 1
        }
        
        let peakHour = hourlyActivity.max { $0.value < $1.value }?.key
        let peakWeekday = weekdayActivity.max { $0.value < $1.value }?.key
        
        return TimePatternAnalysis(
            hourlyDistribution: hourlyActivity,
            weekdayDistribution: weekdayActivity,
            peakHour: peakHour,
            peakWeekday: peakWeekday,
            morningActivity: hourlyActivity.filter { $0.key >= 6 && $0.key < 12 }.values.reduce(0, +),
            afternoonActivity: hourlyActivity.filter { $0.key >= 12 && $0.key < 18 }.values.reduce(0, +),
            eveningActivity: hourlyActivity.filter { $0.key >= 18 && $0.key < 24 }.values.reduce(0, +)
        )
    }
    
    /// 分析活动模式
    private func analyzeActivityPatterns(timeBlocks: [TimeBlock]) -> ActivityPatternAnalysis {
        var categoryDuration: [String: TimeInterval] = [:]
        var tagFrequency: [String: Int] = [:]
        
        for block in timeBlocks {
            // 分析类别
            if let category = block.category {
                categoryDuration[category, default: 0] += block.duration
            }
            
            // 分析标签
            for tag in block.tagsArray {
                if let tagName = tag.name {
                    tagFrequency[tagName, default: 0] += 1
                }
            }
        }
        
        let dominantCategory = categoryDuration.max { $0.value < $1.value }?.key
        let mostFrequentTag = tagFrequency.max { $0.value < $1.value }?.key
        
        return ActivityPatternAnalysis(
            categoryDistribution: categoryDuration,
            tagFrequency: tagFrequency,
            dominantCategory: dominantCategory,
            mostFrequentTag: mostFrequentTag,
            diversityIndex: calculateDiversityIndex(distribution: categoryDuration)
        )
    }
    
    /// 分析专注模式
    private func analyzeFocusPatterns(timeBlocks: [TimeBlock]) -> FocusPatternAnalysis {
        let focusIntensities = timeBlocks.map { $0.averageFocusIntensity }
        
        let averageFocus = focusIntensities.isEmpty ? 0.0 : focusIntensities.reduce(0, +) / Double(focusIntensities.count)
        let focusVariability = calculateVariability(values: focusIntensities)
        
        // 分析专注时段
        var focusTimeSlots: [Int: Double] = [:]
        for block in timeBlocks {
            guard let startTime = block.startTime else { continue }
            let hour = Calendar.current.component(.hour, from: startTime)
            focusTimeSlots[hour, default: 0] += block.averageFocusIntensity
        }
        
        let bestFocusHour = focusTimeSlots.max { $0.value < $1.value }?.key
        
        return FocusPatternAnalysis(
            averageFocusIntensity: averageFocus,
            focusVariability: focusVariability,
            bestFocusHour: bestFocusHour,
            focusTimeSlots: focusTimeSlots,
            highFocusPeriods: identifyHighFocusPeriods(timeBlocks: timeBlocks)
        )
    }
    
    /// 检测异常
    private func detectAnomalies(timeBlocks: [TimeBlock]) -> [UsageAnomaly] {
        var anomalies: [UsageAnomaly] = []
        
        // 检测异常长的时间块
        let averageDuration = timeBlocks.isEmpty ? 0.0 : timeBlocks.reduce(0.0) { $0 + $1.duration } / Double(timeBlocks.count)
        let longBlocks = timeBlocks.filter { $0.duration > averageDuration * 3 }
        
        for block in longBlocks {
            anomalies.append(UsageAnomaly(
                type: .unusuallyLongSession,
                date: block.startTime ?? Date(),
                description: "异常长的时间块: \(String(format: "%.1f", block.duration / 3600))小时",
                severity: .medium
            ))
        }
        
        // 检测异常低的专注强度
        let lowFocusBlocks = timeBlocks.filter { $0.averageFocusIntensity < 0.2 && $0.duration > 1800 } // 30分钟以上的低专注
        
        for block in lowFocusBlocks {
            anomalies.append(UsageAnomaly(
                type: .lowFocusIntensity,
                date: block.startTime ?? Date(),
                description: "长时间低专注强度: \(String(format: "%.1f%%", block.averageFocusIntensity * 100))",
                severity: .low
            ))
        }
        
        return anomalies
    }
    
    /// 生成综合建议
    private func generateComprehensiveSuggestions() async -> [OptimizationSuggestion] {
        // 获取最近30天的数据进行综合分析
        let patternAnalysis = await analyzeUsagePatterns(days: 30)
        let weeklyAnalysis = await generateWeeklyAnalysis(for: Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date())
        
        var suggestions: [OptimizationSuggestion] = []
        
        // 合并建议并去重
        suggestions.append(contentsOf: weeklyAnalysis.suggestions)
        
        // 基于长期模式的建议
        if let bestHour = patternAnalysis.focusPatterns.bestFocusHour {
            suggestions.append(OptimizationSuggestion(
                type: .timeOptimization,
                priority: .medium,
                title: "优化专注时间安排",
                description: "数据显示您在\(bestHour):00最专注，建议将重要任务安排在这个时间",
                actionItems: [
                    "将核心工作安排在\(bestHour):00-\(bestHour + 2):00",
                    "避免在低专注时段处理复杂任务",
                    "利用生物钟规律提高效率"
                ],
                confidence: 0.8
            ))
        }
        
        return Array(Set(suggestions)).sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - Helper Methods
    
    /// 计算生产力评分
    private func calculateProductivityScore(
        focusIntensity: Double,
        taggedRatio: Double,
        beautifulMomentsRatio: Double
    ) -> Double {
        return (focusIntensity * 0.5) + (taggedRatio * 0.3) + (beautifulMomentsRatio * 0.2)
    }
    
    /// 计算一致性
    private func calculateConsistency(values: [Double]) -> Double {
        guard values.count > 1 else { return 1.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        // 一致性 = 1 - (标准差 / 平均值)，限制在0-1之间
        return max(0, min(1, 1 - (standardDeviation / max(mean, 1))))
    }
    
    /// 计算趋势
    private func calculateTrend(values: [Double]) -> TrendDirection {
        guard values.count >= 2 else { return .stable }
        
        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let change = (secondAvg - firstAvg) / max(firstAvg, 1)
        
        if change > 0.1 {
            return .increasing
        } else if change < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }
    
    /// 计算变异性
    private func calculateVariability(values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        
        return sqrt(variance)
    }
    
    /// 计算多样性指数
    private func calculateDiversityIndex(distribution: [String: TimeInterval]) -> Double {
        let total = distribution.values.reduce(0, +)
        guard total > 0 else { return 0.0 }
        
        // 使用香农多样性指数
        let entropy = distribution.values.map { value in
            let proportion = value / total
            return proportion > 0 ? -proportion * log2(proportion) : 0.0
        }.reduce(0.0, +)
        
        return entropy
    }
    
    /// 识别高专注时段
    private func identifyHighFocusPeriods(timeBlocks: [TimeBlock]) -> [TimeInterval] {
        return timeBlocks
            .filter { $0.averageFocusIntensity >= 0.8 }
            .compactMap { block in
                guard let startTime = block.startTime else { return nil }
                return TimeInterval(Calendar.current.component(.hour, from: startTime) * 3600)
            }
    }
}

// MARK: - Supporting Types

/// 分析类型
enum AnalysisType {
    case daily
    case weekly
    case comprehensive
}

/// 每日基础统计
struct DailyBasicStats {
    let totalBlocks: Int
    let totalDuration: TimeInterval
    let averageFocusIntensity: Double
    let taggedBlocks: Int
    let beautifulMoments: Int
    let activeHours: Int
    let productivityScore: Double
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration.truncatingRemainder(dividingBy: 3600)) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    var taggingRate: Double {
        return totalBlocks > 0 ? Double(taggedBlocks) / Double(totalBlocks) : 0.0
    }
}

/// 每日专注分析
struct DailyFocusAnalysis {
    let averageIntensity: Double
    let peakIntensity: Double
    let peakTime: Date?
    let lowIntensityPeriods: [Date]
    let focusDistribution: [FocusIntensityRange: Int]
    let focusEfficiency: Double
    
    var formattedPeakTime: String? {
        guard let peakTime = peakTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: peakTime)
    }
}

/// 每日标签分析
struct DailyTagAnalysis {
    let tagUsage: [String: Int]
    let categoryUsage: [String: TimeInterval]
    let mostUsedTag: String?
    let dominantCategory: String?
    let taggingRate: Double
    let uniqueTagsUsed: Int
}

/// 每日分析报告
struct DailyAnalysisReport {
    let date: Date
    let basicStats: DailyBasicStats
    let focusAnalysis: DailyFocusAnalysis
    let tagAnalysis: DailyTagAnalysis
    let suggestions: [OptimizationSuggestion]
    let generatedAt: Date
    
    var overallScore: Double {
        return (basicStats.productivityScore * 0.4) + 
               (focusAnalysis.averageIntensity * 0.4) + 
               (tagAnalysis.taggingRate * 0.2)
    }
    
    var scoreGrade: String {
        switch overallScore {
        case 0.9...1.0: return "A+"
        case 0.8..<0.9: return "A"
        case 0.7..<0.8: return "B+"
        case 0.6..<0.7: return "B"
        case 0.5..<0.6: return "C+"
        case 0.4..<0.5: return "C"
        default: return "D"
        }
    }
}

/// 每周统计
struct WeeklyStats {
    let totalDuration: TimeInterval
    let averageDailyDuration: TimeInterval
    let averageFocusIntensity: Double
    let activeDays: Int
    let totalBeautifulMoments: Int
    let consistency: Double
    let dailyDurations: [TimeInterval]
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration.truncatingRemainder(dividingBy: 3600)) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    var formattedAverageDailyDuration: String {
        let hours = Int(averageDailyDuration) / 3600
        let minutes = Int(averageDailyDuration.truncatingRemainder(dividingBy: 3600)) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

/// 每周趋势分析
struct WeeklyTrendAnalysis {
    let durationTrend: TrendDirection
    let focusTrend: TrendDirection
    let activityTrend: TrendDirection
}

/// 每周模式
struct WeeklyPattern {
    let type: WeeklyPatternType
    let description: String
    let confidence: Double
}

/// 每周分析报告
struct WeeklyAnalysisReport {
    let weekStartDate: Date
    let weekEndDate: Date
    let weeklyStats: WeeklyStats
    let trendAnalysis: WeeklyTrendAnalysis
    let patterns: [WeeklyPattern]
    let suggestions: [OptimizationSuggestion]
    let generatedAt: Date
    
    var weekNumber: Int {
        return Calendar.current.component(.weekOfYear, from: weekStartDate)
    }
}

/// 使用模式分析
struct UsagePatternAnalysis {
    let analysisDateRange: DateInterval
    let timePatterns: TimePatternAnalysis
    let activityPatterns: ActivityPatternAnalysis
    let focusPatterns: FocusPatternAnalysis
    let anomalies: [UsageAnomaly]
    let generatedAt: Date
}

/// 时间模式分析
struct TimePatternAnalysis {
    let hourlyDistribution: [Int: Int]
    let weekdayDistribution: [Int: Int]
    let peakHour: Int?
    let peakWeekday: Int?
    let morningActivity: Int
    let afternoonActivity: Int
    let eveningActivity: Int
    
    var peakWeekdayName: String? {
        guard let peakWeekday = peakWeekday else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.weekdaySymbols[peakWeekday - 1]
    }
    
    var mostActiveTimeOfDay: String {
        let activities = [
            ("上午", morningActivity),
            ("下午", afternoonActivity),
            ("晚上", eveningActivity)
        ]
        return activities.max { $0.1 < $1.1 }?.0 ?? "未知"
    }
}

/// 活动模式分析
struct ActivityPatternAnalysis {
    let categoryDistribution: [String: TimeInterval]
    let tagFrequency: [String: Int]
    let dominantCategory: String?
    let mostFrequentTag: String?
    let diversityIndex: Double
    
    var diversityLevel: String {
        switch diversityIndex {
        case 0..<1.0: return "低"
        case 1.0..<2.0: return "中"
        case 2.0..<3.0: return "高"
        default: return "极高"
        }
    }
}

/// 专注模式分析
struct FocusPatternAnalysis {
    let averageFocusIntensity: Double
    let focusVariability: Double
    let bestFocusHour: Int?
    let focusTimeSlots: [Int: Double]
    let highFocusPeriods: [TimeInterval]
    
    var focusStability: String {
        switch focusVariability {
        case 0..<0.1: return "非常稳定"
        case 0.1..<0.2: return "稳定"
        case 0.2..<0.3: return "一般"
        case 0.3..<0.4: return "不稳定"
        default: return "非常不稳定"
        }
    }
}

/// 使用异常
struct UsageAnomaly {
    let type: AnomalyType
    let date: Date
    let description: String
    let severity: AnomalySeverity
}

/// 优化建议
struct OptimizationSuggestion: Hashable, Identifiable {
    let id = UUID()
    let type: SuggestionType
    let priority: SuggestionPriority
    let title: String
    let description: String
    let actionItems: [String]
    let confidence: Double
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(description)
    }
    
    static func == (lhs: OptimizationSuggestion, rhs: OptimizationSuggestion) -> Bool {
        return lhs.title == rhs.title && lhs.description == rhs.description
    }
}

// MARK: - Enums

/// 专注强度范围
enum FocusIntensityRange: String, CaseIterable {
    case veryLow = "很低 (0-20%)"
    case low = "低 (20-40%)"
    case medium = "中等 (40-60%)"
    case high = "高 (60-80%)"
    case veryHigh = "很高 (80-100%)"
    
    static func from(intensity: Double) -> FocusIntensityRange {
        switch intensity {
        case 0..<0.2: return .veryLow
        case 0.2..<0.4: return .low
        case 0.4..<0.6: return .medium
        case 0.6..<0.8: return .high
        default: return .veryHigh
        }
    }
    
    var color: String {
        switch self {
        case .veryLow: return "#FF6B6B"
        case .low: return "#FFA726"
        case .medium: return "#FFEB3B"
        case .high: return "#66BB6A"
        case .veryHigh: return "#4CAF50"
        }
    }
}

/// 趋势方向
enum TrendDirection: String {
    case increasing = "上升"
    case declining = "下降"
    case stable = "稳定"
    
    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    var color: String {
        switch self {
        case .increasing: return "#4CAF50"
        case .declining: return "#F44336"
        case .stable: return "#FF9800"
        }
    }
}

/// 每周模式类型
enum WeeklyPatternType: String {
    case workLifeBalance = "工作生活平衡"
    case consistentSchedule = "规律作息"
    case weekendRecovery = "周末恢复"
    case midweekPeak = "周中高峰"
}

/// 异常类型
enum AnomalyType: String {
    case unusuallyLongSession = "异常长会话"
    case lowFocusIntensity = "低专注强度"
    case missingData = "数据缺失"
    case inconsistentPattern = "模式异常"
}

/// 异常严重程度
enum AnomalySeverity: String {
    case low = "低"
    case medium = "中"
    case high = "高"
    
    var color: String {
        switch self {
        case .low: return "#FFC107"
        case .medium: return "#FF9800"
        case .high: return "#F44336"
        }
    }
}

/// 建议类型
enum SuggestionType: String {
    case focusImprovement = "专注提升"
    case timeTracking = "时间记录"
    case wellbeing = "身心健康"
    case consistency = "一致性"
    case timeOptimization = "时间优化"
}

/// 建议优先级
enum SuggestionPriority: Int, Comparable {
    case low = 1
    case medium = 2
    case high = 3
    
    static func < (lhs: SuggestionPriority, rhs: SuggestionPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "#4CAF50"
        case .medium: return "#FF9800"
        case .high: return "#F44336"
        }
    }
}