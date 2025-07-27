import Foundation
import CoreData
import Combine

/// TimeBlockManager - 时间块管理器
/// 负责时间块的创建、查询、更新和删除操作
/// 提供时间块相关的业务逻辑和数据管理功能
@MainActor
class TimeBlockManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var timeBlocks: [TimeBlock] = []
    @Published var isLoading: Bool = false
    @Published var selectedDate: Date = Date()
    
    // MARK: - Private Properties
    
    private let viewContext: NSManagedObjectContext
    private let userSettings: UserSettings
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        self.userSettings = UserSettings.getOrCreate(in: viewContext)
        
        setupDateObserver()
        loadTimeBlocks(for: selectedDate)
    }
    
    // MARK: - Public Methods
    
    /// 加载指定日期的时间块
    /// - Parameter date: 目标日期
    func loadTimeBlocks(for date: Date) {
        isLoading = true
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<TimeBlock> = TimeBlock.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeBlock.startTime, ascending: true)]
        
        do {
            timeBlocks = try viewContext.fetch(request)
            print("📅 加载了 \(timeBlocks.count) 个时间块 for \(DateFormatter.shortDate.string(from: date))")
        } catch {
            print("❌ 加载时间块失败: \(error)")
            timeBlocks = []
        }
        
        isLoading = false
    }
    
    /// 创建新的时间块
    /// - Parameters:
    ///   - startTime: 开始时间
    ///   - endTime: 结束时间
    ///   - activity: 活动描述
    ///   - category: 分类
    ///   - notes: 备注
    /// - Returns: 创建的时间块
    @discardableResult
    func createTimeBlock(
        startTime: Date,
        endTime: Date,
        activity: String? = nil,
        category: String? = nil,
        notes: String? = nil
    ) -> TimeBlock {
        let timeBlock = TimeBlock.create(
            in: viewContext,
            startTime: startTime,
            endTime: endTime,
            activity: activity,
            category: category,
            notes: notes
        )
        
        saveContext()
        refreshCurrentDateBlocks()
        
        print("✅ 创建时间块: \(timeBlock.timeRangeString)")
        return timeBlock
    }
    
    /// 更新时间块信息
    /// - Parameters:
    ///   - timeBlock: 要更新的时间块
    ///   - activity: 新的活动描述
    ///   - category: 新的分类
    ///   - notes: 新的备注
    func updateTimeBlock(
        _ timeBlock: TimeBlock,
        activity: String? = nil,
        category: String? = nil,
        notes: String? = nil
    ) {
        if let activity = activity {
            timeBlock.taggedActivity = activity
        }
        if let category = category {
            timeBlock.category = category
        }
        if let notes = notes {
            timeBlock.notes = notes
        }
        
        timeBlock.isTagged = timeBlock.taggedActivity != nil || !timeBlock.tagsArray.isEmpty
        
        saveContext()
        print("📝 更新时间块: \(timeBlock.timeRangeString)")
    }
    
    /// 删除时间块
    /// - Parameter timeBlock: 要删除的时间块
    func deleteTimeBlock(_ timeBlock: TimeBlock) {
        viewContext.delete(timeBlock)
        saveContext()
        refreshCurrentDateBlocks()
        
        print("🗑️ 删除时间块: \(timeBlock.timeRangeString)")
    }
    
    /// 为时间块添加标签
    /// - Parameters:
    ///   - timeBlock: 目标时间块
    ///   - tags: 要添加的标签数组
    func addTags(to timeBlock: TimeBlock, tags: [TimeTag]) {
        timeBlock.addTags(tags)
        saveContext()
        
        let tagNames = tags.compactMap { $0.name }.joined(separator: ", ")
        print("🏷️ 为时间块添加标签: \(tagNames)")
    }
    
    /// 从时间块移除标签
    /// - Parameters:
    ///   - timeBlock: 目标时间块
    ///   - tag: 要移除的标签
    func removeTag(from timeBlock: TimeBlock, tag: TimeTag) {
        timeBlock.removeTag(tag)
        saveContext()
        
        print("🏷️ 从时间块移除标签: \(tag.name ?? "未知")")
    }
    
    /// 获取指定时间范围内的时间块
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 时间块数组
    func getTimeBlocks(from startDate: Date, to endDate: Date) -> [TimeBlock] {
        let request: NSFetchRequest<TimeBlock> = TimeBlock.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeBlock.startTime, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("❌ 获取时间范围内的时间块失败: \(error)")
            return []
        }
    }
    
    /// 获取未标记的时间块
    /// - Parameter date: 目标日期，nil表示所有日期
    /// - Returns: 未标记的时间块数组
    func getUntaggedTimeBlocks(for date: Date? = nil) -> [TimeBlock] {
        let request: NSFetchRequest<TimeBlock> = TimeBlock.fetchRequest()
        
        var predicates: [NSPredicate] = [NSPredicate(format: "isTagged == NO")]
        
        if let date = date {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            predicates.append(NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeBlock.startTime, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("❌ 获取未标记时间块失败: \(error)")
            return []
        }
    }
    
    /// 获取美好时刻时间块
    /// - Parameter limit: 限制数量，nil表示不限制
    /// - Returns: 美好时刻时间块数组
    func getBeautifulMoments(limit: Int? = nil) -> [TimeBlock] {
        let request: NSFetchRequest<TimeBlock> = TimeBlock.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeBlock.startTime, ascending: false)]
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            let allBlocks = try viewContext.fetch(request)
            return allBlocks.filter { $0.isBeautifulMoment }
        } catch {
            print("❌ 获取美好时刻失败: \(error)")
            return []
        }
    }
    
    /// 生成指定日期的时间块网格（用于热力图）
    /// - Parameter date: 目标日期
    /// - Returns: 时间块网格数据
    func generateTimeBlockGrid(for date: Date) -> [TimeBlockGridItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let granularity = userSettings.timeBlockGranularity
        let blocksPerDay = Int(24 * 60 * 60 / granularity)
        
        var gridItems: [TimeBlockGridItem] = []
        
        for i in 0..<blocksPerDay {
            let blockStartTime = startOfDay.addingTimeInterval(Double(i) * granularity)
            let blockEndTime = blockStartTime.addingTimeInterval(granularity)
            
            // 查找该时间段内的时间块
            let matchingBlock = timeBlocks.first { block in
                guard let blockStart = block.startTime, let blockEnd = block.endTime else { return false }
                return blockStart < blockEndTime && blockEnd > blockStartTime
            }
            
            let gridItem = TimeBlockGridItem(
                startTime: blockStartTime,
                endTime: blockEndTime,
                timeBlock: matchingBlock,
                focusIntensity: matchingBlock?.averageFocusIntensity ?? 0.0,
                isBeautifulMoment: matchingBlock?.isBeautifulMoment ?? false
            )
            
            gridItems.append(gridItem)
        }
        
        return gridItems
    }
    
    /// 获取时间块统计信息
    /// - Parameter date: 目标日期
    /// - Returns: 统计信息
    func getTimeBlockStats(for date: Date) -> TimeBlockStats {
        let dayBlocks = timeBlocks
        
        let totalBlocks = dayBlocks.count
        let taggedBlocks = dayBlocks.filter { $0.isTagged }.count
        let totalDuration = dayBlocks.reduce(0.0) { $0 + $1.duration }
        let averageFocusIntensity = dayBlocks.isEmpty ? 0.0 : dayBlocks.reduce(0.0) { $0 + $1.averageFocusIntensity } / Double(dayBlocks.count)
        let beautifulMomentsCount = dayBlocks.filter { $0.isBeautifulMoment }.count
        
        return TimeBlockStats(
            totalBlocks: totalBlocks,
            taggedBlocks: taggedBlocks,
            totalDuration: totalDuration,
            averageFocusIntensity: averageFocusIntensity,
            beautifulMomentsCount: beautifulMomentsCount
        )
    }
    
    /// 搜索时间块
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - dateRange: 日期范围
    /// - Returns: 匹配的时间块
    func searchTimeBlocks(query: String, in dateRange: DateInterval? = nil) -> [TimeBlock] {
        let request: NSFetchRequest<TimeBlock> = TimeBlock.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        // 搜索条件
        let searchPredicate = NSPredicate(format: "taggedActivity CONTAINS[cd] %@ OR category CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", query, query, query)
        predicates.append(searchPredicate)
        
        // 日期范围条件
        if let dateRange = dateRange {
            let datePredicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", dateRange.start as NSDate, dateRange.end as NSDate)
            predicates.append(datePredicate)
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeBlock.startTime, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("❌ 搜索时间块失败: \(error)")
            return []
        }
    }
    
    // MARK: - Private Methods
    
    private func setupDateObserver() {
        $selectedDate
            .removeDuplicates()
            .sink { [weak self] date in
                self?.loadTimeBlocks(for: date)
            }
            .store(in: &cancellables)
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("❌ 保存时间块失败: \(error)")
        }
    }
    
    private func refreshCurrentDateBlocks() {
        loadTimeBlocks(for: selectedDate)
    }
}

// MARK: - Supporting Types

/// 时间块网格项（用于热力图）
struct TimeBlockGridItem: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let timeBlock: TimeBlock?
    let focusIntensity: Double
    let isBeautifulMoment: Bool
    
    var isEmpty: Bool {
        return timeBlock == nil
    }
    
    var displayIntensity: Double {
        return isEmpty ? 0.0 : max(0.1, focusIntensity)
    }
    
    var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}

/// 时间块统计信息
struct TimeBlockStats {
    let totalBlocks: Int
    let taggedBlocks: Int
    let totalDuration: TimeInterval
    let averageFocusIntensity: Double
    let beautifulMomentsCount: Int
    
    var taggedPercentage: Double {
        guard totalBlocks > 0 else { return 0.0 }
        return Double(taggedBlocks) / Double(totalBlocks) * 100
    }
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration.truncatingRemainder(dividingBy: 3600)) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    var formattedAverageFocusIntensity: String {
        return String(format: "%.1f%%", averageFocusIntensity * 100)
    }
}

// MARK: - Extensions
// DateFormatter extension moved to HeatmapEngineDemo.swift to avoid duplication