import Foundation
import CoreData
import SwiftUI

/// TimeTagManager - Git风格的时间标签管理器
/// 管理时间标签的创建、编辑、删除和智能推荐
@MainActor
class TimeTagManager: ObservableObject {
    
    // MARK: - Properties
    
    private let viewContext: NSManagedObjectContext
    
    // MARK: - Published Properties
    
    @Published var allTags: [TimeTag] = []
    @Published var defaultTags: [TimeTag] = []
    @Published var customTags: [TimeTag] = []
    @Published var recentTags: [TimeTag] = []
    @Published var recommendedTags: [TimeTag] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Constants
    
    private enum TagConfig {
        static let maxRecentTags = 10
        static let maxRecommendedTags = 5
        static let minUsageForRecommendation = 3
        static let recentTagsDays = 7
    }
    
    // MARK: - Default Tags Configuration
    
    private let defaultTagsConfig: [(name: String, category: String, color: String, icon: String, description: String)] = [
        // 工作相关
        ("深度工作", "工作", "#2E8B57", "brain.head.profile", "需要高度专注的核心工作任务"),
        ("会议讨论", "工作", "#4682B4", "person.3.fill", "团队会议、讨论和协作时间"),
        ("代码开发", "工作", "#FF6347", "chevron.left.forwardslash.chevron.right", "编程、开发和技术实现"),
        ("文档整理", "工作", "#32CD32", "doc.text.fill", "文档编写、整理和维护"),
        ("邮件处理", "工作", "#FFD700", "envelope.fill", "邮件回复和沟通处理"),
        
        // 学习成长
        ("技能学习", "学习", "#9370DB", "graduationcap.fill", "新技能学习和知识获取"),
        ("阅读思考", "学习", "#20B2AA", "book.fill", "阅读书籍、文章和深度思考"),
        ("课程学习", "学习", "#FF69B4", "play.rectangle.fill", "在线课程和教育内容"),
        ("实践练习", "学习", "#FFA500", "hammer.fill", "动手实践和技能练习"),
        
        // 生活休闲
        ("运动健身", "生活", "#DC143C", "figure.run", "体育运动和健身锻炼"),
        ("休息放松", "生活", "#98FB98", "leaf.fill", "休息、冥想和放松时间"),
        ("社交娱乐", "生活", "#DDA0DD", "person.2.fill", "朋友聚会和社交活动"),
        ("家务生活", "生活", "#F0E68C", "house.fill", "家务处理和生活琐事"),
        
        // 创作表达
        ("写作创作", "创作", "#FF1493", "pencil.and.outline", "写作、创作和内容产出"),
        ("设计思考", "创作", "#00CED1", "paintbrush.fill", "设计工作和创意思考"),
        ("音乐艺术", "创作", "#FF8C00", "music.note", "音乐、艺术和创意活动"),
        
        // 特殊标记
        ("美好时刻", "特殊", "#FFD700", "sparkles", "值得纪念的美好时光"),
        ("重要突破", "特殊", "#FF4500", "star.fill", "重要进展和突破性成果"),
        ("灵感迸发", "特殊", "#9932CC", "lightbulb.fill", "创意灵感和突发想法")
    ]
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        Task {
            await loadAllTags()
            await initializeDefaultTagsIfNeeded()
            await updateRecommendations()
        }
    }
    
    // MARK: - Core Tag Management
    
    /// 加载所有标签
    func loadAllTags() async {
        isLoading = true
        
        do {
            let request: NSFetchRequest<TimeTag> = TimeTag.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \TimeTag.usageCount, ascending: false),
                NSSortDescriptor(keyPath: \TimeTag.name, ascending: true)
            ]
            
            let tags = try viewContext.fetch(request)
            
            await MainActor.run {
                self.allTags = tags
                self.categorizeTagsAsync()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "加载标签失败: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// 初始化默认标签（如果需要）
    func initializeDefaultTagsIfNeeded() async {
        // 检查是否已有默认标签
        let existingDefaultTags = allTags.filter { $0.isDefault }
        
        if existingDefaultTags.count < defaultTagsConfig.count {
            await createDefaultTags()
        }
    }
    
    /// 创建默认标签
    private func createDefaultTags() async {
        for tagConfig in defaultTagsConfig {
            // 检查是否已存在同名标签
            let existingTag = allTags.first { $0.name == tagConfig.name }
            if existingTag == nil {
                await createTag(
                    name: tagConfig.name,
                    category: tagConfig.category,
                    color: tagConfig.color,
                    icon: tagConfig.icon,
                    description: tagConfig.description,
                    isDefault: true
                )
            }
        }
        
        // 保存上下文
        do {
            try viewContext.save()
            await loadAllTags()
        } catch {
            await MainActor.run {
                self.errorMessage = "创建默认标签失败: \(error.localizedDescription)"
            }
        }
    }
    
    /// 创建新标签
    @discardableResult
    func createTag(
        name: String,
        category: String = "自定义",
        color: String = "#007AFF",
        icon: String = "tag.fill",
        description: String = "",
        isDefault: Bool = false
    ) async -> TimeTag? {
        
        // 验证标签名称
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                self.errorMessage = "标签名称不能为空"
            }
            return nil
        }
        
        // 检查重复
        if allTags.contains(where: { $0.name?.lowercased() == name.lowercased() }) {
            await MainActor.run {
                self.errorMessage = "标签名称已存在"
            }
            return nil
        }
        
        let tag = TimeTag(context: viewContext)
        tag.id = UUID()
        tag.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        tag.category = category
        tag.color = color
        tag.icon = icon
        tag.tagDescription = description
        tag.isDefault = isDefault
        tag.usageCount = 0
        tag.createdAt = Date()
        tag.lastUsedAt = nil
        
        do {
            try viewContext.save()
            await loadAllTags()
            return tag
        } catch {
            await MainActor.run {
                self.errorMessage = "创建标签失败: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    /// 更新标签
    func updateTag(
        _ tag: TimeTag,
        name: String? = nil,
        category: String? = nil,
        color: String? = nil,
        icon: String? = nil,
        description: String? = nil
    ) async -> Bool {
        
        if let newName = name {
            let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                await MainActor.run {
                    self.errorMessage = "标签名称不能为空"
                }
                return false
            }
            
            // 检查重复（排除自己）
            if allTags.contains(where: { $0.id != tag.id && $0.name?.lowercased() == trimmedName.lowercased() }) {
                await MainActor.run {
                    self.errorMessage = "标签名称已存在"
                }
                return false
            }
            
            tag.name = trimmedName
        }
        
        if let newCategory = category {
            tag.category = newCategory
        }
        
        if let newColor = color {
            tag.color = newColor
        }
        
        if let newIcon = icon {
            tag.icon = newIcon
        }
        
        if let newDescription = description {
            tag.tagDescription = newDescription
        }
        
        do {
            try viewContext.save()
            await loadAllTags()
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "更新标签失败: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    /// 删除标签
    func deleteTag(_ tag: TimeTag) async -> Bool {
        // 不允许删除默认标签
        if tag.isDefault {
            await MainActor.run {
                self.errorMessage = "不能删除默认标签"
            }
            return false
        }
        
        // 检查是否有关联的时间块
        if let timeBlocks = tag.timeBlocks, timeBlocks.count > 0 {
            await MainActor.run {
                self.errorMessage = "该标签已被使用，无法删除"
            }
            return false
        }
        
        viewContext.delete(tag)
        
        do {
            try viewContext.save()
            await loadAllTags()
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "删除标签失败: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Tag Usage and Statistics
    
    /// 使用标签（增加使用计数）
    func useTag(_ tag: TimeTag) async {
        tag.usageCount += 1
        tag.lastUsedAt = Date()
        
        do {
            try viewContext.save()
            await updateRecommendations()
        } catch {
            print("更新标签使用统计失败: \(error)")
        }
    }
    
    /// 批量使用标签
    func useTags(_ tags: [TimeTag]) async {
        for tag in tags {
            tag.usageCount += 1
            tag.lastUsedAt = Date()
        }
        
        do {
            try viewContext.save()
            await updateRecommendations()
        } catch {
            print("批量更新标签使用统计失败: \(error)")
        }
    }
    
    /// 获取标签使用统计
    func getTagUsageStats() -> TagUsageStats {
        let totalUsage = allTags.reduce(0) { $0 + Int($1.usageCount) }
        let mostUsedTag = allTags.max { $0.usageCount < $1.usageCount }
        let recentlyUsedTags = allTags.filter { 
            guard let lastUsed = $0.lastUsedAt else { return false }
            return lastUsed.timeIntervalSinceNow > -TimeInterval(TagConfig.recentTagsDays * 24 * 3600)
        }
        
        return TagUsageStats(
            totalTags: allTags.count,
            defaultTags: defaultTags.count,
            customTags: customTags.count,
            totalUsage: totalUsage,
            mostUsedTag: mostUsedTag,
            recentlyUsedCount: recentlyUsedTags.count,
            averageUsagePerTag: allTags.isEmpty ? 0 : Double(totalUsage) / Double(allTags.count)
        )
    }
    
    // MARK: - Smart Recommendations
    
    /// 更新推荐标签
    func updateRecommendations() async {
        await MainActor.run {
            // 最近使用的标签
            self.recentTags = self.allTags
                .filter { 
                    guard let lastUsed = $0.lastUsedAt else { return false }
                    return lastUsed.timeIntervalSinceNow > -TimeInterval(TagConfig.recentTagsDays * 24 * 3600)
                }
                .sorted { 
                    ($0.lastUsedAt ?? Date.distantPast) > ($1.lastUsedAt ?? Date.distantPast)
                }
                .prefix(TagConfig.maxRecentTags)
                .map { $0 }
            
            // 推荐标签（基于使用频率）
            self.recommendedTags = self.allTags
                .filter { $0.usageCount >= TagConfig.minUsageForRecommendation }
                .sorted { $0.usageCount > $1.usageCount }
                .prefix(TagConfig.maxRecommendedTags)
                .map { $0 }
        }
    }
    
    /// 基于时间和上下文的智能推荐
    func getContextualRecommendations(for timeBlock: TimeBlock) -> [TimeTag] {
        var recommendations: [TimeTag] = []
        
        // 基于时间的推荐
        let hour = Calendar.current.component(.hour, from: timeBlock.startTime ?? Date())
        let timeBasedTags = getTimeBasedRecommendations(hour: hour)
        recommendations.append(contentsOf: timeBasedTags)
        
        // 基于历史模式的推荐
        let historicalTags = getHistoricalRecommendations(for: timeBlock)
        recommendations.append(contentsOf: historicalTags)
        
        // 去重并限制数量
        let uniqueRecommendations = Array(Set(recommendations))
        return Array(uniqueRecommendations.prefix(TagConfig.maxRecommendedTags))
    }
    
    /// 基于时间的推荐
    private func getTimeBasedRecommendations(hour: Int) -> [TimeTag] {
        switch hour {
        case 6...9:
            return allTags.filter { ["运动健身", "阅读思考", "深度工作"].contains($0.name) }
        case 9...12:
            return allTags.filter { ["深度工作", "代码开发", "会议讨论"].contains($0.name) }
        case 13...17:
            return allTags.filter { ["会议讨论", "文档整理", "邮件处理"].contains($0.name) }
        case 18...22:
            return allTags.filter { ["技能学习", "写作创作", "社交娱乐"].contains($0.name) }
        default:
            return allTags.filter { ["休息放松", "阅读思考", "音乐艺术"].contains($0.name) }
        }
    }
    
    /// 基于历史模式的推荐
    private func getHistoricalRecommendations(for timeBlock: TimeBlock) -> [TimeTag] {
        // 获取相似时间段的历史标签使用
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timeBlock.startTime ?? Date())
        let weekday = calendar.component(.weekday, from: timeBlock.startTime ?? Date())
        
        // 这里可以实现更复杂的历史模式分析
        // 暂时返回最常用的标签
        return Array(allTags.sorted { $0.usageCount > $1.usageCount }.prefix(3))
    }
    
    // MARK: - Search and Filter
    
    /// 搜索标签
    func searchTags(query: String) -> [TimeTag] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allTags
        }
        
        let lowercaseQuery = query.lowercased()
        return allTags.filter { tag in
            (tag.name?.lowercased().contains(lowercaseQuery) == true) ||
            (tag.category?.lowercased().contains(lowercaseQuery) == true) ||
            (tag.tagDescription?.lowercased().contains(lowercaseQuery) == true)
        }
    }
    
    /// 按类别筛选标签
    func filterTags(by category: String) -> [TimeTag] {
        return allTags.filter { $0.category == category }
    }
    
    /// 获取所有类别
    func getAllCategories() -> [String] {
        let categories = Set(allTags.compactMap { $0.category })
        return Array(categories).sorted()
    }
    
    // MARK: - Beautiful Moment Tags
    
    /// 获取美好时刻相关标签
    func getBeautifulMomentTags() -> [TimeTag] {
        return allTags.filter { tag in
            tag.name?.contains("美好") == true ||
            tag.name?.contains("突破") == true ||
            tag.name?.contains("灵感") == true ||
            tag.category == "特殊"
        }
    }
    
    /// 创建美好时刻标签
    func createBeautifulMomentTag(name: String, description: String) async -> TimeTag? {
        return await createTag(
            name: name,
            category: "特殊",
            color: "#FFD700",
            icon: "sparkles",
            description: description,
            isDefault: false
        )
    }
    
    // MARK: - Helper Methods
    
    /// 分类标签
    private func categorizeTagsAsync() {
        defaultTags = allTags.filter { $0.isDefault }
        customTags = allTags.filter { !$0.isDefault }
    }
    
    /// 清除错误消息
    func clearError() {
        errorMessage = nil
    }
    
    /// 重置所有数据
    func reset() async {
        await loadAllTags()
        await updateRecommendations()
        clearError()
    }
}

// MARK: - Supporting Types

/// 标签使用统计
struct TagUsageStats {
    let totalTags: Int
    let defaultTags: Int
    let customTags: Int
    let totalUsage: Int
    let mostUsedTag: TimeTag?
    let recentlyUsedCount: Int
    let averageUsagePerTag: Double
    
    var formattedAverageUsage: String {
        return String(format: "%.1f", averageUsagePerTag)
    }
    
    var mostUsedTagName: String {
        return mostUsedTag?.name ?? "无"
    }
}

/// 标签推荐类型
enum TagRecommendationType {
    case recent      // 最近使用
    case frequent    // 高频使用
    case contextual  // 上下文相关
    case timeBased   // 基于时间
    case historical  // 历史模式
    
    var displayName: String {
        switch self {
        case .recent: return "最近使用"
        case .frequent: return "常用标签"
        case .contextual: return "智能推荐"
        case .timeBased: return "时间推荐"
        case .historical: return "历史模式"
        }
    }
}

/// 标签验证结果
enum TagValidationResult {
    case valid
    case empty
    case duplicate
    case tooLong
    case invalidCharacters
    
    var errorMessage: String? {
        switch self {
        case .valid: return nil
        case .empty: return "标签名称不能为空"
        case .duplicate: return "标签名称已存在"
        case .tooLong: return "标签名称过长"
        case .invalidCharacters: return "标签名称包含无效字符"
        }
    }
}

// MARK: - Extensions

extension TimeTagManager {
    
    /// 验证标签名称
    func validateTagName(_ name: String, excludingTag: TimeTag? = nil) -> TagValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查是否为空
        if trimmedName.isEmpty {
            return .empty
        }
        
        // 检查长度
        if trimmedName.count > 20 {
            return .tooLong
        }
        
        // 检查重复
        let isDuplicate = allTags.contains { tag in
            guard tag.id != excludingTag?.id else { return false }
            return tag.name?.lowercased() == trimmedName.lowercased()
        }
        
        if isDuplicate {
            return .duplicate
        }
        
        // 检查无效字符
        let invalidCharacters = CharacterSet.alphanumerics.union(.whitespaces).inverted
        if trimmedName.rangeOfCharacter(from: invalidCharacters) != nil {
            return .invalidCharacters
        }
        
        return .valid
    }
    
    /// 获取标签的使用趋势
    func getTagUsageTrend(_ tag: TimeTag, days: Int = 30) -> [TagUsageDataPoint] {
        // 这里可以实现更复杂的趋势分析
        // 暂时返回模拟数据
        var dataPoints: [TagUsageDataPoint] = []
        let calendar = Calendar.current
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let usage = Int.random(in: 0...5) // 模拟数据
            dataPoints.append(TagUsageDataPoint(date: date, usageCount: usage))
        }
        
        return dataPoints.reversed()
    }
}

/// 标签使用数据点
struct TagUsageDataPoint {
    let date: Date
    let usageCount: Int
}