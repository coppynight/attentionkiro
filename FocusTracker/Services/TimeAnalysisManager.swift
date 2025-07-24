import Foundation
import CoreData
import Combine
import SwiftUI

/// Statistics for time usage analysis
struct UsageStatistics {
    let totalUsageTime: TimeInterval
    let appCount: Int
    let longestSession: TimeInterval
    let averageSession: TimeInterval
    let mostUsedApp: String?
    let productiveTime: TimeInterval
    let productivityRatio: Double
}

/// Daily usage data for trends
struct DailyUsageData {
    let date: Date
    let totalUsageTime: TimeInterval
    let appCount: Int
    let sessionCount: Int
    let productiveTime: TimeInterval
    let topApps: [AppUsageStatistics]
}

/// App usage statistics for breakdown analysis
struct AppUsageStatistics {
    let appIdentifier: String
    let appName: String
    let categoryIdentifier: String?
    let totalTime: TimeInterval
    let sessionCount: Int
    let averageSessionTime: TimeInterval
    let isProductiveApp: Bool
    let percentage: Double
}

/// Scene tag data for distribution analysis
struct SceneTagData {
    let tagName: String
    let color: String
    let totalTime: TimeInterval
    let sessionCount: Int
    let percentage: Double
    let averageSessionTime: TimeInterval
}

/// Time distribution data for hourly analysis
struct HourlyDistribution {
    let hour: Int
    let totalTime: TimeInterval
    let sessionCount: Int
    let intensity: Double // 0.0 to 1.0
}

/// Weekly comparison data
struct WeeklyComparison {
    let weekdayAverage: TimeInterval
    let weekendAverage: TimeInterval
    let weekdayProductivity: Double
    let weekendProductivity: Double
    let difference: TimeInterval
    let changePercentage: Double
}

/// Daily tag usage data for trend analysis
struct DailyTagUsage {
    let date: Date
    let tagName: String
    let usageTime: TimeInterval
    let percentage: Double
    let sessionCount: Int
}

/// Tag trend analysis data
struct TagTrendAnalysis {
    let tagName: String
    let direction: TrendDirection
    let changePercentage: Double
    let averageDailyUsage: TimeInterval
    let totalSessions: Int
}

/// Trend direction enumeration
enum TrendDirection {
    case increasing
    case decreasing
    case stable
}

/// Comprehensive tag usage report
struct TagUsageReport {
    let period: DateInterval
    let totalUsageTime: TimeInterval
    let tagDistribution: [TagDistribution]
    let trendAnalysis: [String: TagTrendAnalysis]
    let mostUsedTag: String?
    let generatedAt: Date
}

/// Combined tag and focus statistics
struct CombinedTagFocusStats {
    let date: Date
    let focusTime: TimeInterval
    let totalUsageTime: TimeInterval
    let tagDistribution: [SceneTagData]
    let focusEfficiency: Double
    let mostFocusedTag: String?
}

/// Protocol defining time analysis capabilities
protocol TimeAnalysisManagerProtocol {
    func startMonitoring()
    func stopMonitoring()
    func getUsageStatistics(for date: Date) -> UsageStatistics
    func getWeeklyTrend() -> [DailyUsageData]
    func getAppUsageBreakdown(for date: Date) -> [AppUsageStatistics]
    func getSceneTagDistribution(for date: Date) -> [SceneTagData]
    func getHourlyDistribution(for date: Date) -> [HourlyDistribution]
    func getWeeklyComparison() -> WeeklyComparison
    func getMonthlyTrend() -> [DailyUsageData]
    
    // Scene tag statistics integration (Requirements 9.5, 9.8)
    func getTagUsagePercentages(for date: Date) -> [String: Double]
    func getTagGroupedTimeDistribution(for date: Date) -> [String: [AppUsageStatistics]]
    func getTagUsagePercentageChanges(for period: DateInterval) -> [String: (current: Double, previous: Double, change: Double)]
    func getWeeklyTagTrends() -> [String: [DailyTagUsage]]
    func getMonthlyTagTrends() -> [String: [DailyTagUsage]]
    func generateTagUsageReport(for period: DateInterval) -> TagUsageReport
    func getCombinedTagAndFocusStatistics(for date: Date) -> CombinedTagFocusStats
}

/// Manages time analysis, statistics, and usage monitoring extending existing focus functionality
class TimeAnalysisManager: ObservableObject, TimeAnalysisManagerProtocol {
    
    // MARK: - Published Properties
    
    @Published var todaysUsageTime: TimeInterval = 0
    @Published var todaysAppBreakdown: [AppUsageStatistics] = []
    @Published var todaysTagDistribution: [SceneTagData] = []
    @Published var currentActiveApp: String?
    @Published var isMonitoring: Bool = false
    @Published var weeklyTrend: [DailyUsageData] = []
    @Published var hourlyDistribution: [HourlyDistribution] = []
    @Published var weeklyComparison: WeeklyComparison?
    
    // Scene tag statistics (Requirements 9.5, 9.8)
    @Published var tagUsagePercentages: [String: Double] = [:]
    @Published var tagGroupedDistribution: [String: [AppUsageStatistics]] = [:]
    @Published var weeklyTagTrends: [String: [DailyTagUsage]] = [:]
    @Published var monthlyTagTrends: [String: [DailyTagUsage]] = [:]
    @Published var latestTagReport: TagUsageReport?
    
    // MARK: - Private Properties
    
    private let viewContext: NSManagedObjectContext
    private let focusManager: FocusManager
    private let tagManager: TagManager
    private var cancellables = Set<AnyCancellable>()
    
    // Cache for performance optimization
    private var statisticsCache: [String: Any] = [:]
    private var lastCacheUpdate: Date = Date.distantPast
    private let cacheValidityDuration: TimeInterval = 5 * 60 // 5 minutes
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext, focusManager: FocusManager, tagManager: TagManager) {
        self.viewContext = viewContext
        self.focusManager = focusManager
        self.tagManager = tagManager
        
        setupDataObservers()
        calculateTodaysData()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        focusManager.startMonitoring()
        
        // Start periodic data updates
        startPeriodicUpdates()
        
        print("TimeAnalysisManager: Started time analysis monitoring")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        stopPeriodicUpdates()
        
        print("TimeAnalysisManager: Stopped time analysis monitoring")
    }
    
    func getUsageStatistics(for date: Date) -> UsageStatistics {
        let cacheKey = "usage_stats_\(dateKey(for: date))"
        
        if let cached = getCachedResult(key: cacheKey) as? UsageStatistics {
            return cached
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", 
                                      startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let sessions = try viewContext.fetch(request)
            
            let totalTime = sessions.reduce(0) { $0 + $1.duration }
            let uniqueApps = Set(sessions.map { $0.appIdentifier })
            let longestSession = sessions.map { $0.duration }.max() ?? 0
            let averageSession = sessions.isEmpty ? 0 : totalTime / Double(sessions.count)
            let productiveSessions = sessions.filter { $0.isProductiveTime }
            let productiveTime = productiveSessions.reduce(0) { $0 + $1.duration }
            let productivityRatio = totalTime > 0 ? productiveTime / totalTime : 0
            
            // Find most used app
            let appUsage = Dictionary(grouping: sessions) { $0.appIdentifier }
            let mostUsedApp = appUsage.max { first, second in
                let firstTime = first.value.reduce(0) { $0 + $1.duration }
                let secondTime = second.value.reduce(0) { $0 + $1.duration }
                return firstTime < secondTime
            }?.key
            
            let statistics = UsageStatistics(
                totalUsageTime: totalTime,
                appCount: uniqueApps.count,
                longestSession: longestSession,
                averageSession: averageSession,
                mostUsedApp: mostUsedApp,
                productiveTime: productiveTime,
                productivityRatio: productivityRatio
            )
            
            setCachedResult(key: cacheKey, value: statistics)
            return statistics
            
        } catch {
            print("TimeAnalysisManager: Error fetching usage statistics - \(error)")
            return UsageStatistics(
                totalUsageTime: 0, appCount: 0, longestSession: 0, 
                averageSession: 0, mostUsedApp: nil, productiveTime: 0, productivityRatio: 0
            )
        }
    }
    
    func getWeeklyTrend() -> [DailyUsageData] {
        let cacheKey = "weekly_trend"
        
        if let cached = getCachedResult(key: cacheKey) as? [DailyUsageData] {
            return cached
        }
        
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [DailyUsageData] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let stats = getUsageStatistics(for: date)
            let appBreakdown = getAppUsageBreakdown(for: date)
            let topApps = Array(appBreakdown.prefix(3))
            
            weeklyData.append(DailyUsageData(
                date: date,
                totalUsageTime: stats.totalUsageTime,
                appCount: stats.appCount,
                sessionCount: getSessionCount(for: date),
                productiveTime: stats.productiveTime,
                topApps: topApps
            ))
        }
        
        let result = Array(weeklyData.reversed())
        setCachedResult(key: cacheKey, value: result)
        return result
    }
    
    func getAppUsageBreakdown(for date: Date) -> [AppUsageStatistics] {
        let cacheKey = "app_breakdown_\(dateKey(for: date))"
        
        if let cached = getCachedResult(key: cacheKey) as? [AppUsageStatistics] {
            return cached
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", 
                                      startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let sessions = try viewContext.fetch(request)
            let totalTime = sessions.reduce(0) { $0 + $1.duration }
            
            // Group sessions by app
            let groupedSessions = Dictionary(grouping: sessions) { $0.appIdentifier }
            
            var appUsageData: [AppUsageStatistics] = []
            
            for (appId, appSessions) in groupedSessions {
                let appTotalTime = appSessions.reduce(0) { $0 + $1.duration }
                let appName = appSessions.first?.appName ?? appId
                let categoryId = appSessions.first?.categoryIdentifier
                let sessionCount = appSessions.count
                let averageTime = appTotalTime / Double(sessionCount)
                let percentage = totalTime > 0 ? (appTotalTime / totalTime) * 100 : 0
                let isProductive = appSessions.first?.isProductiveTime ?? false
                
                appUsageData.append(AppUsageStatistics(
                    appIdentifier: appId,
                    appName: appName,
                    categoryIdentifier: categoryId,
                    totalTime: appTotalTime,
                    sessionCount: sessionCount,
                    averageSessionTime: averageTime,
                    isProductiveApp: isProductive,
                    percentage: percentage
                ))
            }
            
            let result = appUsageData.sorted { $0.totalTime > $1.totalTime }
            setCachedResult(key: cacheKey, value: result)
            return result
            
        } catch {
            print("TimeAnalysisManager: Error fetching app usage breakdown - \(error)")
            return []
        }
    }
    
    func getSceneTagDistribution(for date: Date) -> [SceneTagData] {
        let cacheKey = "tag_distribution_\(dateKey(for: date))"
        
        if let cached = getCachedResult(key: cacheKey) as? [SceneTagData] {
            return cached
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "startTime >= %@ AND startTime < %@ AND sceneTag != nil",
            startOfDay as NSDate, endOfDay as NSDate
        )
        
        do {
            let sessions = try viewContext.fetch(request)
            let totalTime = sessions.reduce(0) { $0 + $1.duration }
            
            // Group sessions by tag
            let groupedSessions = Dictionary(grouping: sessions) { $0.sceneTag ?? "未分类" }
            
            var tagData: [SceneTagData] = []
            
            for (tagName, tagSessions) in groupedSessions {
                let tagTime = tagSessions.reduce(0) { $0 + $1.duration }
                let sessionCount = tagSessions.count
                let averageTime = tagTime / Double(sessionCount)
                let percentage = totalTime > 0 ? (tagTime / totalTime) * 100 : 0
                
                // Get tag color from TagManager
                let color = tagManager.getAllTags().first(where: { $0.name == tagName })?.color ?? "#999999"
                
                tagData.append(SceneTagData(
                    tagName: tagName,
                    color: color,
                    totalTime: tagTime,
                    sessionCount: sessionCount,
                    percentage: percentage,
                    averageSessionTime: averageTime
                ))
            }
            
            let result = tagData.sorted { $0.totalTime > $1.totalTime }
            setCachedResult(key: cacheKey, value: result)
            return result
            
        } catch {
            print("TimeAnalysisManager: Error fetching scene tag distribution - \(error)")
            return []
        }
    }
    
    func getHourlyDistribution(for date: Date) -> [HourlyDistribution] {
        let cacheKey = "hourly_distribution_\(dateKey(for: date))"
        
        if let cached = getCachedResult(key: cacheKey) as? [HourlyDistribution] {
            return cached
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", 
                                      startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let sessions = try viewContext.fetch(request)
            
            // Group sessions by hour
            var hourlyData: [Int: (time: TimeInterval, count: Int)] = [:]
            
            for session in sessions {
                let hour = calendar.component(.hour, from: session.startTime)
                let existing = hourlyData[hour] ?? (time: 0, count: 0)
                hourlyData[hour] = (time: existing.time + session.duration, count: existing.count + 1)
            }
            
            // Find maximum time for intensity calculation
            let maxTime = hourlyData.values.map { $0.time }.max() ?? 1
            
            var distribution: [HourlyDistribution] = []
            
            for hour in 0..<24 {
                let data = hourlyData[hour] ?? (time: 0, count: 0)
                let intensity = maxTime > 0 ? data.time / maxTime : 0
                
                distribution.append(HourlyDistribution(
                    hour: hour,
                    totalTime: data.time,
                    sessionCount: data.count,
                    intensity: intensity
                ))
            }
            
            setCachedResult(key: cacheKey, value: distribution)
            return distribution
            
        } catch {
            print("TimeAnalysisManager: Error fetching hourly distribution - \(error)")
            return []
        }
    }
    
    func getWeeklyComparison() -> WeeklyComparison {
        let cacheKey = "weekly_comparison"
        
        if let cached = getCachedResult(key: cacheKey) as? WeeklyComparison {
            return cached
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        var weekdayTimes: [TimeInterval] = []
        var weekendTimes: [TimeInterval] = []
        var weekdayProductiveTimes: [TimeInterval] = []
        var weekendProductiveTimes: [TimeInterval] = []
        
        // Analyze last 14 days to get better averages
        for i in 0..<14 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let weekday = calendar.component(.weekday, from: date)
            let stats = getUsageStatistics(for: date)
            
            if weekday == 1 || weekday == 7 { // Sunday or Saturday
                weekendTimes.append(stats.totalUsageTime)
                weekendProductiveTimes.append(stats.productiveTime)
            } else {
                weekdayTimes.append(stats.totalUsageTime)
                weekdayProductiveTimes.append(stats.productiveTime)
            }
        }
        
        let weekdayAverage = weekdayTimes.isEmpty ? 0 : weekdayTimes.reduce(0, +) / Double(weekdayTimes.count)
        let weekendAverage = weekendTimes.isEmpty ? 0 : weekendTimes.reduce(0, +) / Double(weekendTimes.count)
        
        let weekdayProductiveAverage = weekdayProductiveTimes.isEmpty ? 0 : weekdayProductiveTimes.reduce(0, +) / Double(weekdayProductiveTimes.count)
        let weekendProductiveAverage = weekendProductiveTimes.isEmpty ? 0 : weekendProductiveTimes.reduce(0, +) / Double(weekendProductiveTimes.count)
        
        let weekdayProductivity = weekdayAverage > 0 ? weekdayProductiveAverage / weekdayAverage : 0
        let weekendProductivity = weekendAverage > 0 ? weekendProductiveAverage / weekendAverage : 0
        
        let difference = weekendAverage - weekdayAverage
        let changePercentage = weekdayAverage > 0 ? (difference / weekdayAverage) * 100 : 0
        
        let comparison = WeeklyComparison(
            weekdayAverage: weekdayAverage,
            weekendAverage: weekendAverage,
            weekdayProductivity: weekdayProductivity,
            weekendProductivity: weekendProductivity,
            difference: difference,
            changePercentage: changePercentage
        )
        
        setCachedResult(key: cacheKey, value: comparison)
        return comparison
    }
    
    func getMonthlyTrend() -> [DailyUsageData] {
        let cacheKey = "monthly_trend"
        
        if let cached = getCachedResult(key: cacheKey) as? [DailyUsageData] {
            return cached
        }
        
        let calendar = Calendar.current
        let today = Date()
        var monthlyData: [DailyUsageData] = []
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let stats = getUsageStatistics(for: date)
            let appBreakdown = getAppUsageBreakdown(for: date)
            let topApps = Array(appBreakdown.prefix(3))
            
            monthlyData.append(DailyUsageData(
                date: date,
                totalUsageTime: stats.totalUsageTime,
                appCount: stats.appCount,
                sessionCount: getSessionCount(for: date),
                productiveTime: stats.productiveTime,
                topApps: topApps
            ))
        }
        
        let result = Array(monthlyData.reversed())
        setCachedResult(key: cacheKey, value: result)
        return result
    }
    
    // MARK: - Integration with Focus Manager
    
    /// Gets combined focus and usage statistics for comprehensive analysis
    func getCombinedStatistics(for date: Date) -> (focus: FocusStatistics, usage: UsageStatistics) {
        let focusStats = focusManager.getFocusStatistics(for: date)
        let usageStats = getUsageStatistics(for: date)
        return (focus: focusStats, usage: usageStats)
    }
    
    /// Gets combined weekly trend including both focus and usage data
    func getCombinedWeeklyTrend() -> [(focus: DailyFocusData, usage: DailyUsageData)] {
        let focusTrend = focusManager.getWeeklyTrend()
        let usageTrend = getWeeklyTrend()
        
        return zip(focusTrend, usageTrend).map { (focus: $0, usage: $1) }
    }
    
    // MARK: - Private Methods
    
    private func setupDataObservers() {
        // Observe changes in Core Data to invalidate cache
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] _ in
                self?.invalidateCache()
                self?.calculateTodaysData()
            }
            .store(in: &cancellables)
    }
    
    private func calculateTodaysData() {
        let today = Date()
        
        DispatchQueue.main.async {
            self.todaysUsageTime = self.getUsageStatistics(for: today).totalUsageTime
            self.todaysAppBreakdown = self.getAppUsageBreakdown(for: today)
            self.todaysTagDistribution = self.getSceneTagDistribution(for: today)
            self.weeklyTrend = self.getWeeklyTrend()
            self.hourlyDistribution = self.getHourlyDistribution(for: today)
            self.weeklyComparison = self.getWeeklyComparison()
            
            // Update scene tag statistics (Requirements 9.5, 9.8)
            self.tagUsagePercentages = self.getTagUsagePercentages(for: today)
            self.tagGroupedDistribution = self.getTagGroupedTimeDistribution(for: today)
            self.weeklyTagTrends = self.getWeeklyTagTrends()
            self.monthlyTagTrends = self.getMonthlyTagTrends()
            
            // Generate today's tag report
            let todayInterval = DateInterval(start: Calendar.current.startOfDay(for: today), 
                                           end: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: today))!)
            self.latestTagReport = self.generateTagUsageReport(for: todayInterval)
        }
    }
    
    private func startPeriodicUpdates() {
        // Update data every 5 minutes when monitoring
        Timer.publish(every: 5 * 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                if self?.isMonitoring == true {
                    self?.calculateTodaysData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func stopPeriodicUpdates() {
        cancellables.removeAll()
        setupDataObservers() // Keep data observers active
    }
    
    private func getSessionCount(for date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", 
                                      startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            return try viewContext.count(for: request)
        } catch {
            print("TimeAnalysisManager: Error counting sessions - \(error)")
            return 0
        }
    }
    
    // MARK: - Cache Management
    
    private func getCachedResult(key: String) -> Any? {
        guard Date().timeIntervalSince(lastCacheUpdate) < cacheValidityDuration else {
            return nil
        }
        return statisticsCache[key]
    }
    
    private func setCachedResult(key: String, value: Any) {
        statisticsCache[key] = value
        lastCacheUpdate = Date()
    }
    
    private func invalidateCache() {
        statisticsCache.removeAll()
        lastCacheUpdate = Date.distantPast
    }
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Helper Extensions

extension TimeAnalysisManager {
    
    /// Formats time interval to human readable string
    func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Gets productivity insights based on usage patterns
    func getProductivityInsights(for date: Date) -> [String] {
        let stats = getUsageStatistics(for: date)
        let tagDistribution = getSceneTagDistribution(for: date)
        var insights: [String] = []
        
        // Productivity ratio insights
        if stats.productivityRatio > 0.7 {
            insights.append("今天的效率很高，\(Int(stats.productivityRatio * 100))%的时间用于高效工作")
        } else if stats.productivityRatio < 0.3 {
            insights.append("今天的娱乐时间较多，可以考虑增加一些高效工作时间")
        }
        
        // App diversity insights
        if stats.appCount > 20 {
            insights.append("今天使用了\(stats.appCount)个应用，注意力可能比较分散")
        } else if stats.appCount < 5 {
            insights.append("今天专注使用了少数几个应用，专注度很好")
        }
        
        // Tag distribution insights
        let workTag = tagDistribution.first { $0.tagName == "工作" }
        let entertainmentTag = tagDistribution.first { $0.tagName == "娱乐" }
        
        if let work = workTag, let entertainment = entertainmentTag {
            if work.totalTime > entertainment.totalTime * 2 {
                insights.append("工作时间是娱乐时间的2倍以上，工作专注度很好")
            } else if entertainment.totalTime > work.totalTime * 2 {
                insights.append("娱乐时间较多，可以适当增加工作时间")
            }
        }
        
        return insights
    }
    
    /// Gets usage pattern analysis
    func getUsagePatterns(for period: DateInterval) -> [String: Any] {
        // This can be expanded for more sophisticated pattern analysis
        let calendar = Calendar.current
        var patterns: [String: Any] = [:]
        
        // Peak usage hours
        var hourlyTotals: [Int: TimeInterval] = [:]
        
        let startDate = period.start
        let endDate = period.end
        var currentDate = startDate
        
        while currentDate < endDate {
            let hourlyDist = getHourlyDistribution(for: currentDate)
            for hourData in hourlyDist {
                hourlyTotals[hourData.hour, default: 0] += hourData.totalTime
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        let peakHour = hourlyTotals.max { $0.value < $1.value }?.key ?? 12
        patterns["peakHour"] = peakHour
        
        // Most used apps
        // This would require aggregating across the period
        patterns["analysisDate"] = Date()
        
        return patterns
    }
    
    // MARK: - Scene Tag Statistics Integration
    
    /// Gets comprehensive tag statistics for a specific period
    func getTagStatistics(for period: DateInterval) -> TagStatistics {
        let startDate = period.start
        let endDate = period.end
        
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "startTime >= %@ AND startTime < %@ AND sceneTag != nil",
            startDate as NSDate, endDate as NSDate
        )
        
        do {
            let sessions = try viewContext.fetch(request)
            let totalTime = sessions.reduce(0) { $0 + $1.duration }
            
            // Group by tags
            let groupedSessions = Dictionary(grouping: sessions) { $0.sceneTag ?? "未分类" }
            
            var distributions: [TagDistribution] = []
            var mostUsedTag: String?
            var maxTime: TimeInterval = 0
            
            for (tagName, tagSessions) in groupedSessions {
                let tagTime = tagSessions.reduce(0) { $0 + $1.duration }
                let percentage = totalTime > 0 ? (tagTime / totalTime) * 100 : 0
                let color = tagManager.getAllTags().first(where: { $0.name == tagName })?.color ?? "#999999"
                
                distributions.append(TagDistribution(
                    tagName: tagName,
                    color: color,
                    usageTime: tagTime,
                    percentage: percentage,
                    sessionCount: tagSessions.count
                ))
                
                if tagTime > maxTime {
                    maxTime = tagTime
                    mostUsedTag = tagName
                }
            }
            
            return TagStatistics(
                totalUsageTime: totalTime,
                sessionCount: sessions.count,
                mostUsedTag: mostUsedTag,
                tagDistribution: distributions.sorted { $0.usageTime > $1.usageTime }
            )
            
        } catch {
            print("TimeAnalysisManager: Error fetching tag statistics - \(error)")
            return TagStatistics(
                totalUsageTime: 0,
                sessionCount: 0,
                mostUsedTag: nil,
                tagDistribution: []
            )
        }
    }
    
    /// Gets tag usage trends over a period with daily breakdown
    func getTagTrends(for period: DateInterval) -> [TagTrend] {
        return tagManager.getTagTrends(for: period)
    }
    
    /// Gets tag usage percentage distribution for visualization (Requirement 9.5)
    func getTagUsagePercentages(for date: Date) -> [String: Double] {
        let tagDistribution = getSceneTagDistribution(for: date)
        var percentages: [String: Double] = [:]
        
        for tagData in tagDistribution {
            percentages[tagData.tagName] = tagData.percentage
        }
        
        return percentages
    }
    
    /// Gets scene tag time distribution grouped by tags for analysis view (Requirement 9.5)
    func getTagGroupedTimeDistribution(for date: Date) -> [String: [AppUsageStatistics]] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", 
                                      startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let sessions = try viewContext.fetch(request)
            
            // Group sessions by tag first, then by app within each tag
            var tagGroupedData: [String: [String: [AppUsageSession]]] = [:]
            
            for session in sessions {
                let tagName = session.sceneTag ?? "未分类"
                let appId = session.appIdentifier
                
                if tagGroupedData[tagName] == nil {
                    tagGroupedData[tagName] = [:]
                }
                
                if tagGroupedData[tagName]![appId] == nil {
                    tagGroupedData[tagName]![appId] = []
                }
                
                tagGroupedData[tagName]![appId]!.append(session)
            }
            
            // Convert to AppUsageStatistics grouped by tags
            var result: [String: [AppUsageStatistics]] = [:]
            
            for (tagName, appSessions) in tagGroupedData {
                var appUsageList: [AppUsageStatistics] = []
                let tagTotalTime = appSessions.values.flatMap { $0 }.reduce(0) { $0 + $1.duration }
                
                for (appId, sessions) in appSessions {
                    let appTotalTime = sessions.reduce(0) { $0 + $1.duration }
                    let appName = sessions.first?.appName ?? appId
                    let categoryId = sessions.first?.categoryIdentifier
                    let sessionCount = sessions.count
                    let averageTime = appTotalTime / Double(sessionCount)
                    let percentage = tagTotalTime > 0 ? (appTotalTime / tagTotalTime) * 100 : 0
                    let isProductive = sessions.first?.isProductiveTime ?? false
                    
                    appUsageList.append(AppUsageStatistics(
                        appIdentifier: appId,
                        appName: appName,
                        categoryIdentifier: categoryId,
                        totalTime: appTotalTime,
                        sessionCount: sessionCount,
                        averageSessionTime: averageTime,
                        isProductiveApp: isProductive,
                        percentage: percentage
                    ))
                }
                
                result[tagName] = appUsageList.sorted { $0.totalTime > $1.totalTime }
            }
            
            return result
            
        } catch {
            print("TimeAnalysisManager: Error fetching tag grouped time distribution - \(error)")
            return [:]
        }
    }
    
    /// Gets scene tag usage percentage changes over time for reports (Requirement 9.8)
    func getTagUsagePercentageChanges(for period: DateInterval) -> [String: (current: Double, previous: Double, change: Double)] {
        let calendar = Calendar.current
        let periodDuration = period.duration
        
        // Calculate previous period for comparison
        let previousStart = calendar.date(byAdding: .second, value: -Int(periodDuration), to: period.start)!
        let previousPeriod = DateInterval(start: previousStart, end: period.start)
        
        // Get current and previous period statistics
        let currentStats = getTagStatistics(for: period)
        let previousStats = getTagStatistics(for: previousPeriod)
        
        var changes: [String: (current: Double, previous: Double, change: Double)] = [:]
        
        // Create a set of all tags from both periods
        let allTags = Set(currentStats.tagDistribution.map { $0.tagName } + 
                         previousStats.tagDistribution.map { $0.tagName })
        
        for tagName in allTags {
            let currentPercentage = currentStats.tagDistribution.first { $0.tagName == tagName }?.percentage ?? 0
            let previousPercentage = previousStats.tagDistribution.first { $0.tagName == tagName }?.percentage ?? 0
            let change = currentPercentage - previousPercentage
            
            changes[tagName] = (current: currentPercentage, previous: previousPercentage, change: change)
        }
        
        return changes
    }
    
    /// Gets weekly tag usage trends for reports (Requirement 9.8)
    func getWeeklyTagTrends() -> [String: [DailyTagUsage]] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyTagData: [String: [DailyTagUsage]] = [:]
        
        // Get data for the past 7 days
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let tagDistribution = getSceneTagDistribution(for: date)
            
            for tagData in tagDistribution {
                if weeklyTagData[tagData.tagName] == nil {
                    weeklyTagData[tagData.tagName] = []
                }
                
                weeklyTagData[tagData.tagName]!.append(DailyTagUsage(
                    date: date,
                    tagName: tagData.tagName,
                    usageTime: tagData.totalTime,
                    percentage: tagData.percentage,
                    sessionCount: tagData.sessionCount
                ))
            }
        }
        
        // Sort each tag's data by date
        for tagName in weeklyTagData.keys {
            weeklyTagData[tagName] = weeklyTagData[tagName]?.sorted { $0.date < $1.date }
        }
        
        return weeklyTagData
    }
    
    /// Gets monthly tag usage trends for comprehensive reports (Requirement 9.8)
    func getMonthlyTagTrends() -> [String: [DailyTagUsage]] {
        let calendar = Calendar.current
        let today = Date()
        var monthlyTagData: [String: [DailyTagUsage]] = [:]
        
        // Get data for the past 30 days
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let tagDistribution = getSceneTagDistribution(for: date)
            
            for tagData in tagDistribution {
                if monthlyTagData[tagData.tagName] == nil {
                    monthlyTagData[tagData.tagName] = []
                }
                
                monthlyTagData[tagData.tagName]!.append(DailyTagUsage(
                    date: date,
                    tagName: tagData.tagName,
                    usageTime: tagData.totalTime,
                    percentage: tagData.percentage,
                    sessionCount: tagData.sessionCount
                ))
            }
        }
        
        // Sort each tag's data by date
        for tagName in monthlyTagData.keys {
            monthlyTagData[tagName] = monthlyTagData[tagName]?.sorted { $0.date < $1.date }
        }
        
        return monthlyTagData
    }
    
    /// Gets tag usage report with percentage distribution and trends (Requirement 9.8)
    func generateTagUsageReport(for period: DateInterval) -> TagUsageReport {
        let tagStats = getTagStatistics(for: period)
        let tagChanges = getTagUsagePercentageChanges(for: period)
        let tagTrends = getTagTrends(for: period)
        
        // Calculate trend direction for each tag
        var trendAnalysis: [String: TagTrendAnalysis] = [:]
        
        for tagName in tagStats.tagDistribution.map({ $0.tagName }) {
            let tagTrendData = tagTrends.filter { $0.tagName == tagName }
            let change = tagChanges[tagName]?.change ?? 0
            
            var direction: TrendDirection = .stable
            if change > 5 {
                direction = .increasing
            } else if change < -5 {
                direction = .decreasing
            }
            
            let averageUsage = tagTrendData.isEmpty ? 0 : 
                tagTrendData.reduce(0) { $0 + $1.usageTime } / Double(tagTrendData.count)
            
            trendAnalysis[tagName] = TagTrendAnalysis(
                tagName: tagName,
                direction: direction,
                changePercentage: change,
                averageDailyUsage: averageUsage,
                totalSessions: tagTrendData.reduce(0) { $0 + $1.sessionCount }
            )
        }
        
        return TagUsageReport(
            period: period,
            totalUsageTime: tagStats.totalUsageTime,
            tagDistribution: tagStats.tagDistribution,
            trendAnalysis: trendAnalysis,
            mostUsedTag: tagStats.mostUsedTag,
            generatedAt: Date()
        )
    }
    
    /// Gets the most productive tags based on usage patterns
    func getMostProductiveTags(for period: DateInterval, limit: Int = 5) -> [SceneTagData] {
        let calendar = Calendar.current
        let startDate = period.start
        let endDate = period.end
        
        var tagProductivity: [String: (totalTime: TimeInterval, productiveTime: TimeInterval, sessions: Int)] = [:]
        
        var currentDate = startDate
        while currentDate < endDate {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
            
            let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
            request.predicate = NSPredicate(
                format: "startTime >= %@ AND startTime < %@ AND sceneTag != nil",
                currentDate as NSDate, dayEnd as NSDate
            )
            
            do {
                let sessions = try viewContext.fetch(request)
                
                for session in sessions {
                    let tagName = session.sceneTag ?? "未分类"
                    let existing = tagProductivity[tagName] ?? (totalTime: 0, productiveTime: 0, sessions: 0)
                    
                    let productiveTime = session.isProductiveTime ? session.duration : 0
                    
                    tagProductivity[tagName] = (
                        totalTime: existing.totalTime + session.duration,
                        productiveTime: existing.productiveTime + productiveTime,
                        sessions: existing.sessions + 1
                    )
                }
            } catch {
                print("TimeAnalysisManager: Error fetching productive tags - \(error)")
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        // Calculate productivity scores and create SceneTagData
        var productiveTags: [SceneTagData] = []
        
        for (tagName, data) in tagProductivity {
            let productivityRatio = data.totalTime > 0 ? data.productiveTime / data.totalTime : 0
            let averageSessionTime = data.sessions > 0 ? data.totalTime / Double(data.sessions) : 0
            let color = tagManager.getAllTags().first(where: { $0.name == tagName })?.color ?? "#999999"
            
            // Only include tags with significant productivity
            if productivityRatio > 0.3 {
                productiveTags.append(SceneTagData(
                    tagName: tagName,
                    color: color,
                    totalTime: data.totalTime,
                    sessionCount: data.sessions,
                    percentage: productivityRatio * 100, // Use productivity ratio as percentage
                    averageSessionTime: averageSessionTime
                ))
            }
        }
        
        return Array(productiveTags.sorted { $0.percentage > $1.percentage }.prefix(limit))
    }
    
    /// Integrates tag statistics with focus time statistics for comprehensive analysis
    func getCombinedTagAndFocusStatistics(for date: Date) -> CombinedTagFocusStats {
        let focusStats = focusManager.getFocusStatistics(for: date)
        let tagDistribution = getSceneTagDistribution(for: date)
        let usageStats = getUsageStatistics(for: date)
        
        return CombinedTagFocusStats(
            date: date,
            focusTime: focusStats.totalFocusTime,
            totalUsageTime: usageStats.totalUsageTime,
            tagDistribution: tagDistribution,
            focusEfficiency: focusStats.totalFocusTime > 0 ? focusStats.totalFocusTime / usageStats.totalUsageTime : 0,
            mostFocusedTag: tagDistribution.max { $0.totalTime < $1.totalTime }?.tagName
        )
    }
    
    /// Gets tag usage comparison between two periods
    func compareTagUsage(period1: DateInterval, period2: DateInterval) -> [String: (period1: TimeInterval, period2: TimeInterval, change: Double)] {
        let stats1 = getTagStatistics(for: period1)
        let stats2 = getTagStatistics(for: period2)
        
        var comparison: [String: (period1: TimeInterval, period2: TimeInterval, change: Double)] = [:]
        
        // Get all unique tag names from both periods
        let allTags = Set(stats1.tagDistribution.map { $0.tagName } + stats2.tagDistribution.map { $0.tagName })
        
        for tagName in allTags {
            let time1 = stats1.tagDistribution.first { $0.tagName == tagName }?.usageTime ?? 0
            let time2 = stats2.tagDistribution.first { $0.tagName == tagName }?.usageTime ?? 0
            
            let change = time1 > 0 ? ((time2 - time1) / time1) * 100 : (time2 > 0 ? 100 : 0)
            
            comparison[tagName] = (period1: time1, period2: time2, change: change)
        }
        
        return comparison
    }
    
    /// Gets tag usage efficiency metrics
    func getTagEfficiencyMetrics(for date: Date) -> [String: Double] {
        let tagDistribution = getSceneTagDistribution(for: date)
        var efficiency: [String: Double] = [:]
        
        for tagData in tagDistribution {
            // Calculate efficiency based on average session time and total usage
            let avgSessionMinutes = tagData.averageSessionTime / 60
            let _ = tagData.totalTime / 3600 // totalHours - not currently used in calculation
            
            // Efficiency score: longer average sessions and reasonable total time indicate better focus
            var score = 0.0
            
            // Reward longer average sessions (up to 60 minutes)
            if avgSessionMinutes > 0 {
                score += min(avgSessionMinutes / 60.0, 1.0) * 50
            }
            
            // Reward consistent usage (not too fragmented)
            if tagData.sessionCount > 0 {
                let fragmentationPenalty = max(0, (Double(tagData.sessionCount) - 5) * 2)
                score = max(0, score - fragmentationPenalty)
            }
            
            // Bonus for productive tags
            let productiveTags = ["工作", "学习"]
            if productiveTags.contains(tagData.tagName) {
                score += 20
            }
            
            efficiency[tagData.tagName] = min(score, 100) // Cap at 100
        }
        
        return efficiency
    }
    
    /// Gets recommended tag usage balance based on current patterns
    func getTagBalanceRecommendations(for date: Date) -> [String: String] {
        let tagDistribution = getSceneTagDistribution(for: date)
        let totalTime = tagDistribution.reduce(0) { $0 + $1.totalTime }
        
        var recommendations: [String: String] = [:]
        
        // Analyze current distribution
        let workTime = tagDistribution.first { $0.tagName == "工作" }?.totalTime ?? 0
        let studyTime = tagDistribution.first { $0.tagName == "学习" }?.totalTime ?? 0
        let entertainmentTime = tagDistribution.first { $0.tagName == "娱乐" }?.totalTime ?? 0
        let socialTime = tagDistribution.first { $0.tagName == "社交" }?.totalTime ?? 0
        
        let productiveTime = workTime + studyTime
        let leisureTime = entertainmentTime + socialTime
        
        // Provide balance recommendations
        if totalTime > 0 {
            let productiveRatio = productiveTime / totalTime
            let _ = leisureTime / totalTime // leisureRatio - not currently used
            
            if productiveRatio > 0.8 {
                recommendations["balance"] = "今天工作学习时间很多，建议适当放松一下"
            } else if productiveRatio < 0.3 {
                recommendations["balance"] = "今天娱乐时间较多，可以增加一些工作或学习时间"
            } else {
                recommendations["balance"] = "今天的时间分配比较均衡"
            }
            
            if socialTime > totalTime * 0.4 {
                recommendations["social"] = "社交时间较多，注意不要影响其他重要事务"
            }
            
            if entertainmentTime > totalTime * 0.5 {
                recommendations["entertainment"] = "娱乐时间较长，可以考虑做一些更有意义的活动"
            }
        }
        
        return recommendations
    }
    
    // MARK: - Integration with Focus Statistics
    
    /// Gets comprehensive analysis combining focus time and tag distribution
    func getComprehensiveAnalysis(for date: Date) -> ComprehensiveAnalysis {
        let focusStats = focusManager.getFocusStatistics(for: date)
        let usageStats = getUsageStatistics(for: date)
        let tagDistribution = getSceneTagDistribution(for: date)
        let tagPercentages = getTagUsagePercentages(for: date)
        
        // Calculate focus efficiency by tag (simplified - using overall focus efficiency)
        var tagFocusEfficiency: [String: Double] = [:]
        let overallEfficiency = usageStats.totalUsageTime > 0 ? focusStats.totalFocusTime / usageStats.totalUsageTime : 0
        for tagData in tagDistribution {
            // For now, use overall efficiency as approximation for each tag
            tagFocusEfficiency[tagData.tagName] = overallEfficiency
        }
        
        return ComprehensiveAnalysis(
            date: date,
            totalFocusTime: focusStats.totalFocusTime,
            totalUsageTime: usageStats.totalUsageTime,
            overallEfficiency: usageStats.totalUsageTime > 0 ? focusStats.totalFocusTime / usageStats.totalUsageTime : 0,
            tagDistribution: tagDistribution,
            tagPercentages: tagPercentages,
            tagFocusEfficiency: tagFocusEfficiency,
            productivityScore: calculateProductivityScore(focusStats: focusStats, usageStats: usageStats, tagDistribution: tagDistribution)
        )
    }
    
    /// Calculates a comprehensive productivity score based on focus and tag data
    private func calculateProductivityScore(focusStats: FocusStatistics, usageStats: UsageStatistics, tagDistribution: [SceneTagData]) -> Double {
        var score = 0.0
        
        // Base score from focus efficiency (0-40 points)
        let focusEfficiency = usageStats.totalUsageTime > 0 ? focusStats.totalFocusTime / usageStats.totalUsageTime : 0
        score += focusEfficiency * 40
        
        // Bonus for productive tag usage (0-30 points)
        let productiveTags = ["工作", "学习"]
        let productiveTime = tagDistribution.filter { productiveTags.contains($0.tagName) }.reduce(0) { $0 + $1.totalTime }
        let productiveRatio = usageStats.totalUsageTime > 0 ? productiveTime / usageStats.totalUsageTime : 0
        score += productiveRatio * 30
        
        // Bonus for session quality (0-20 points)
        let avgSessionTime = focusStats.sessionCount > 0 ? focusStats.totalFocusTime / Double(focusStats.sessionCount) : 0
        let sessionQuality = min(avgSessionTime / (45 * 60), 1.0) // Normalize to 45 minutes
        score += sessionQuality * 20
        
        // Penalty for excessive entertainment (0-10 points deduction)
        let entertainmentTime = tagDistribution.first { $0.tagName == "娱乐" }?.totalTime ?? 0
        let entertainmentRatio = usageStats.totalUsageTime > 0 ? entertainmentTime / usageStats.totalUsageTime : 0
        if entertainmentRatio > 0.5 {
            score -= (entertainmentRatio - 0.5) * 20
        }
        
        return max(0, min(100, score))
    }
    
    /// Gets tag-based insights and recommendations
    func getTagBasedInsights(for date: Date) -> [TagInsight] {
        let tagDistribution = getSceneTagDistribution(for: date)
        let tagEfficiency = getTagEfficiencyMetrics(for: date)
        let _ = tagDistribution.reduce(0) { $0 + $1.totalTime } // totalTime - not currently used
        
        var insights: [TagInsight] = []
        
        for tagData in tagDistribution {
            let efficiency = tagEfficiency[tagData.tagName] ?? 0
            let percentage = tagData.percentage
            
            var insight = TagInsight(
                tagName: tagData.tagName,
                color: tagData.color,
                usageTime: tagData.totalTime,
                percentage: percentage,
                efficiency: efficiency,
                recommendation: "",
                priority: .medium
            )
            
            // Generate recommendations based on usage patterns
            if tagData.tagName == "工作" {
                if percentage > 60 {
                    insight.recommendation = "工作时间很充足，注意劳逸结合"
                    insight.priority = .low
                } else if percentage < 20 {
                    insight.recommendation = "工作时间较少，可以考虑增加专注工作时间"
                    insight.priority = .high
                } else {
                    insight.recommendation = "工作时间分配合理"
                    insight.priority = .medium
                }
            } else if tagData.tagName == "娱乐" {
                if percentage > 50 {
                    insight.recommendation = "娱乐时间较多，建议平衡工作和娱乐"
                    insight.priority = .high
                } else if percentage < 10 {
                    insight.recommendation = "适当增加一些娱乐放松时间"
                    insight.priority = .low
                } else {
                    insight.recommendation = "娱乐时间适中"
                    insight.priority = .medium
                }
            } else if tagData.tagName == "学习" {
                if efficiency > 70 {
                    insight.recommendation = "学习效率很高，继续保持"
                    insight.priority = .low
                } else if efficiency < 40 {
                    insight.recommendation = "学习时间较分散，建议集中时间学习"
                    insight.priority = .high
                } else {
                    insight.recommendation = "学习状态良好"
                    insight.priority = .medium
                }
            }
            
            insights.append(insight)
        }
        
        return insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}

// MARK: - Supporting Data Structures

/// Comprehensive analysis combining focus and tag data
struct ComprehensiveAnalysis {
    let date: Date
    let totalFocusTime: TimeInterval
    let totalUsageTime: TimeInterval
    let overallEfficiency: Double
    let tagDistribution: [SceneTagData]
    let tagPercentages: [String: Double]
    let tagFocusEfficiency: [String: Double]
    let productivityScore: Double
}

/// Tag-based insight with recommendations
struct TagInsight {
    let tagName: String
    let color: String
    let usageTime: TimeInterval
    let percentage: Double
    let efficiency: Double
    var recommendation: String
    var priority: InsightPriority
}

/// Priority levels for insights
enum InsightPriority: Int, CaseIterable {
    case high = 3
    case medium = 2
    case low = 1
}