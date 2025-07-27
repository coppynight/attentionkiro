import Foundation
import CoreData
import Combine

/// BeautifulMomentManager - 美好时刻管理器
/// 专门负责美好时刻的创建、管理和分析
/// 将特殊的时间片段标记为人生中的重要"tag"
@MainActor
class BeautifulMomentManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var beautifulMoments: [TimeCommit] = []
    @Published var isLoading: Bool = false
    @Published var selectedTimeRange: BeautifulMomentTimeRange = .thisWeek
    
    // MARK: - Private Properties
    
    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        
        setupTimeRangeObserver()
        loadBeautifulMoments()
    }
    
    // MARK: - Public Methods
    
    /// 创建美好时刻
    /// - Parameters:
    ///   - timeBlock: 关联的时间块
    ///   - title: 美好时刻标题
    ///   - description: 详细描述
    ///   - emotion: 情感标签
    ///   - intensity: 美好程度 (0.0 - 1.0)
    /// - Returns: 创建的提交记录
    @discardableResult
    func createBeautifulMoment(
        for timeBlock: TimeBlock,
        title: String,
        description: String? = nil,
        emotion: BeautifulMomentEmotion = .joy,
        intensity: Double = 0.8
    ) -> TimeCommit? {
        
        // 创建美好时刻的提交消息
        let commitMessage = generateBeautifulMomentCommitMessage(title: title, emotion: emotion)
        
        // 创建提交记录
        let commit = timeBlock.addCommit(
            message: commitMessage,
            focusIntensity: intensity,
            interruptionCount: 0,
            isBeautifulMoment: true
        )
        
        // 添加美好时刻标签
        if let beautifulMomentTag = getBeautifulMomentTag() {
            timeBlock.addTag(beautifulMomentTag)
        }
        
        // 保存到Core Data
        do {
            try viewContext.save()
            print("✨ 创建美好时刻: \(title)")
            
            // 刷新数据
            loadBeautifulMoments()
            
            return commit
        } catch {
            print("❌ 保存美好时刻失败: \(error)")
            return nil
        }
    }
    
    /// 更新美好时刻
    /// - Parameters:
    ///   - commit: 要更新的提交记录
    ///   - title: 新标题
    ///   - description: 新描述
    ///   - emotion: 新情感标签
    func updateBeautifulMoment(
        _ commit: TimeCommit,
        title: String? = nil,
        description: String? = nil,
        emotion: BeautifulMomentEmotion? = nil
    ) {
        if let title = title, let emotion = emotion {
            let newMessage = generateBeautifulMomentCommitMessage(title: title, emotion: emotion)
            commit.updateCommit(message: newMessage)
        }
        
        saveContext()
        loadBeautifulMoments()
        
        print("📝 更新美好时刻: \(commit.commitMessage ?? "未知")")
    }
    
    /// 删除美好时刻
    /// - Parameter commit: 要删除的提交记录
    func deleteBeautifulMoment(_ commit: TimeCommit) {
        // 移除美好时刻标记
        commit.isBeautifulMoment = false
        
        // 如果这是唯一的提交记录，则删除整个提交
        if let timeBlock = commit.timeBlock, timeBlock.commitsArray.count == 1 {
            viewContext.delete(commit)
        }
        
        saveContext()
        loadBeautifulMoments()
        
        print("🗑️ 删除美好时刻")
    }
    
    /// 获取美好时刻统计
    /// - Parameter timeRange: 时间范围
    /// - Returns: 统计信息
    func getBeautifulMomentStats(for timeRange: BeautifulMomentTimeRange = .thisWeek) -> BeautifulMomentStats {
        let dateRange = timeRange.dateInterval
        let moments = getBeautifulMoments(in: dateRange)
        
        return BeautifulMomentStats(moments: moments, timeRange: timeRange)
    }
    
    /// 获取情感分布
    /// - Parameter timeRange: 时间范围
    /// - Returns: 情感分布字典
    func getEmotionDistribution(for timeRange: BeautifulMomentTimeRange = .thisWeek) -> [BeautifulMomentEmotion: Int] {
        let dateRange = timeRange.dateInterval
        let moments = getBeautifulMoments(in: dateRange)
        
        var distribution: [BeautifulMomentEmotion: Int] = [:]
        
        for moment in moments {
            if let emotion = extractEmotionFromCommitMessage(moment.commitMessage) {
                distribution[emotion, default: 0] += 1
            }
        }
        
        return distribution
    }
    
    /// 获取美好时刻趋势
    /// - Parameter days: 天数
    /// - Returns: 每日美好时刻数量
    func getBeautifulMomentTrend(days: Int = 30) -> [BeautifulMomentTrendPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        var trendPoints: [BeautifulMomentTrendPoint] = []
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: i, to: startDate)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayMoments = getBeautifulMoments(from: dayStart, to: dayEnd)
            
            trendPoints.append(BeautifulMomentTrendPoint(
                date: date,
                count: dayMoments.count,
                averageIntensity: dayMoments.isEmpty ? 0.0 : dayMoments.reduce(0.0) { $0 + $1.focusIntensity } / Double(dayMoments.count)
            ))
        }
        
        return trendPoints
    }
    
    /// 生成美好时刻回忆录
    /// - Parameter timeRange: 时间范围
    /// - Returns: 回忆录内容
    func generateMemoryBook(for timeRange: BeautifulMomentTimeRange) -> BeautifulMomentMemoryBook {
        let dateRange = timeRange.dateInterval
        let moments = getBeautifulMoments(in: dateRange)
        
        return BeautifulMomentMemoryBook(
            timeRange: timeRange,
            moments: moments,
            stats: getBeautifulMomentStats(for: timeRange),
            emotionDistribution: getEmotionDistribution(for: timeRange)
        )
    }
    
    /// 搜索美好时刻
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - emotion: 情感筛选
    ///   - dateRange: 日期范围
    /// - Returns: 匹配的美好时刻
    func searchBeautifulMoments(
        query: String? = nil,
        emotion: BeautifulMomentEmotion? = nil,
        in dateRange: DateInterval? = nil
    ) -> [TimeCommit] {
        let request: NSFetchRequest<TimeCommit> = TimeCommit.fetchRequest()
        
        var predicates: [NSPredicate] = [NSPredicate(format: "isBeautifulMoment == YES")]
        
        // 搜索关键词
        if let query = query, !query.isEmpty {
            let searchPredicate = NSPredicate(format: "commitMessage CONTAINS[cd] %@", query)
            predicates.append(searchPredicate)
        }
        
        // 情感筛选
        if let emotion = emotion {
            let emotionPredicate = NSPredicate(format: "commitMessage CONTAINS[cd] %@", emotion.emoji)
            predicates.append(emotionPredicate)
        }
        
        // 日期范围
        if let dateRange = dateRange {
            let datePredicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", dateRange.start as NSDate, dateRange.end as NSDate)
            predicates.append(datePredicate)
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeCommit.createdAt, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("❌ 搜索美好时刻失败: \(error)")
            return []
        }
    }
    
    // MARK: - Private Methods
    
    private func setupTimeRangeObserver() {
        $selectedTimeRange
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.loadBeautifulMoments()
            }
            .store(in: &cancellables)
    }
    
    private func loadBeautifulMoments() {
        isLoading = true
        
        let dateRange = selectedTimeRange.dateInterval
        beautifulMoments = getBeautifulMoments(in: dateRange)
        
        isLoading = false
        print("✨ 加载了 \(beautifulMoments.count) 个美好时刻")
    }
    
    private func getBeautifulMoments(in dateRange: DateInterval) -> [TimeCommit] {
        return getBeautifulMoments(from: dateRange.start, to: dateRange.end)
    }
    
    private func getBeautifulMoments(from startDate: Date, to endDate: Date) -> [TimeCommit] {
        let request: NSFetchRequest<TimeCommit> = TimeCommit.fetchRequest()
        request.predicate = NSPredicate(format: "isBeautifulMoment == YES AND createdAt >= %@ AND createdAt <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeCommit.createdAt, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("❌ 获取美好时刻失败: \(error)")
            return []
        }
    }
    
    private func getBeautifulMomentTag() -> TimeTag? {
        let request: NSFetchRequest<TimeTag> = TimeTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "美好时刻")
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("❌ 获取美好时刻标签失败: \(error)")
            return nil
        }
    }
    
    private func generateBeautifulMomentCommitMessage(title: String, emotion: BeautifulMomentEmotion) -> String {
        return "\(emotion.emoji) \(title) - 美好时刻记录"
    }
    
    private func extractEmotionFromCommitMessage(_ message: String?) -> BeautifulMomentEmotion? {
        guard let message = message else { return nil }
        
        for emotion in BeautifulMomentEmotion.allCases {
            if message.contains(emotion.emoji) {
                return emotion
            }
        }
        
        return nil
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("❌ 保存美好时刻失败: \(error)")
        }
    }
}

// MARK: - Supporting Types

/// 美好时刻情感类型
enum BeautifulMomentEmotion: String, CaseIterable {
    case joy = "喜悦"
    case gratitude = "感恩"
    case achievement = "成就"
    case love = "爱意"
    case peace = "平静"
    case excitement = "兴奋"
    case inspiration = "灵感"
    case connection = "连接"
    
    var emoji: String {
        switch self {
        case .joy: return "😊"
        case .gratitude: return "🙏"
        case .achievement: return "🎉"
        case .love: return "❤️"
        case .peace: return "🕊️"
        case .excitement: return "🚀"
        case .inspiration: return "💡"
        case .connection: return "🤝"
        }
    }
    
    var description: String {
        switch self {
        case .joy: return "快乐和喜悦的时刻"
        case .gratitude: return "感恩和感谢的时刻"
        case .achievement: return "成就和胜利的时刻"
        case .love: return "爱与被爱的时刻"
        case .peace: return "平静和安宁的时刻"
        case .excitement: return "兴奋和激动的时刻"
        case .inspiration: return "灵感和创意的时刻"
        case .connection: return "连接和共鸣的时刻"
        }
    }
}

/// 美好时刻时间范围
enum BeautifulMomentTimeRange: String, CaseIterable {
    case today = "今天"
    case thisWeek = "本周"
    case thisMonth = "本月"
    case thisYear = "今年"
    case allTime = "全部"
    
    var dateInterval: DateInterval {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return DateInterval(start: startOfDay, end: endOfDay)
            
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)!.start
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
            return DateInterval(start: startOfWeek, end: endOfWeek)
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)!.start
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            return DateInterval(start: startOfMonth, end: endOfMonth)
            
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: now)!.start
            let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear)!
            return DateInterval(start: startOfYear, end: endOfYear)
            
        case .allTime:
            let distantPast = Date.distantPast
            let distantFuture = Date.distantFuture
            return DateInterval(start: distantPast, end: distantFuture)
        }
    }
}

/// 美好时刻统计
struct BeautifulMomentStats {
    let totalCount: Int
    let averageIntensity: Double
    let mostCommonEmotion: BeautifulMomentEmotion?
    let timeRange: BeautifulMomentTimeRange
    let totalDuration: TimeInterval
    
    init(moments: [TimeCommit], timeRange: BeautifulMomentTimeRange) {
        self.totalCount = moments.count
        self.timeRange = timeRange
        
        if moments.isEmpty {
            self.averageIntensity = 0.0
            self.mostCommonEmotion = nil
            self.totalDuration = 0.0
        } else {
            self.averageIntensity = moments.reduce(0.0) { $0 + $1.focusIntensity } / Double(moments.count)
            self.totalDuration = moments.compactMap { $0.timeBlock?.duration }.reduce(0, +)
            
            // 计算最常见的情感
            var emotionCounts: [BeautifulMomentEmotion: Int] = [:]
            for moment in moments {
                if let message = moment.commitMessage {
                    for emotion in BeautifulMomentEmotion.allCases {
                        if message.contains(emotion.emoji) {
                            emotionCounts[emotion, default: 0] += 1
                            break
                        }
                    }
                }
            }
            self.mostCommonEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key
        }
    }
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration.truncatingRemainder(dividingBy: 3600)) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    var formattedAverageIntensity: String {
        return String(format: "%.1f%%", averageIntensity * 100)
    }
}

/// 美好时刻趋势点
struct BeautifulMomentTrendPoint {
    let date: Date
    let count: Int
    let averageIntensity: Double
}

/// 美好时刻回忆录
struct BeautifulMomentMemoryBook {
    let timeRange: BeautifulMomentTimeRange
    let moments: [TimeCommit]
    let stats: BeautifulMomentStats
    let emotionDistribution: [BeautifulMomentEmotion: Int]
    
    var title: String {
        return "\(timeRange.rawValue)的美好时刻回忆录"
    }
    
    var summary: String {
        let count = stats.totalCount
        let emotion = stats.mostCommonEmotion?.rawValue ?? "未知"
        return "在\(timeRange.rawValue)里，你记录了\(count)个美好时刻，最常感受到的是\(emotion)。"
    }
}