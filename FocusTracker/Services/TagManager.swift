import Foundation
import CoreData
import Combine
import SwiftUI

/// Statistics for tag usage data
struct TagStatistics {
    let totalUsageTime: TimeInterval
    let sessionCount: Int
    let mostUsedTag: String?
    let tagDistribution: [TagDistribution]
}

/// Tag distribution data for visualization
struct TagDistribution {
    let tagName: String
    let color: String
    let usageTime: TimeInterval
    let percentage: Double
    let sessionCount: Int
}

/// Tag trend data for analytics
struct TagTrend {
    let date: Date
    let tagName: String
    let usageTime: TimeInterval
    let sessionCount: Int
}

/// Tag recommendation data
struct TagRecommendation {
    let tag: SceneTag
    let confidence: Float
    let reason: String
}

/// Protocol defining tag management capabilities
protocol TagManagerProtocol {
    func getDefaultTags() -> [SceneTag]
    func createCustomTag(name: String, color: String) -> SceneTag?
    func suggestTagForApp(_ appIdentifier: String) -> TagRecommendation?
    func updateTagForSession(_ session: AppUsageSession, tag: SceneTag)
    func getTagDistribution(for date: Date) -> [TagDistribution]
    func getTagTrends(for period: DateInterval) -> [TagTrend]
    func getAllTags() -> [SceneTag]
    func deleteTag(_ tag: SceneTag) -> Bool
}

/// Manages scene tags, recommendations, and tag-related analytics
class TagManager: ObservableObject, TagManagerProtocol {
    
    // MARK: - Published Properties
    
    @Published var availableTags: [SceneTag] = []
    @Published var customTags: [SceneTag] = []
    @Published var defaultTags: [SceneTag] = []
    @Published var isInitialized: Bool = false
    
    // MARK: - Private Properties
    
    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    /// App category to default tag mapping for intelligent recommendations
    private let appCategoryMapping: [String: String] = [
        // Work/Productivity apps
        "com.microsoft.Office.Word": "工作",
        "com.microsoft.Office.Excel": "工作",
        "com.microsoft.Office.PowerPoint": "工作",
        "com.apple.mail": "工作",
        "com.slack.Slack": "工作",
        "com.microsoft.teams": "工作",
        "com.notion.id": "工作",
        "com.evernote.iPhone": "工作",
        
        // Study/Education apps
        "com.apple.iBooks": "学习",
        "com.duolingo.DuolingoMobile": "学习",
        "com.khanacademy.Khan-Academy": "学习",
        "com.apple.Keynote": "学习",
        "com.apple.Pages": "学习",
        "com.readdle.PDFExpert7": "学习",
        
        // Entertainment apps
        "com.netflix.Netflix": "娱乐",
        "com.tencent.QQMusic": "娱乐",
        "com.apple.tv": "娱乐",
        "com.spotify.client": "娱乐",
        "com.youku.YouKu": "娱乐",
        "com.bilibili.app": "娱乐",
        "com.tencent.xin.game": "娱乐",
        
        // Social apps
        "com.tencent.xin": "社交",
        "com.sina.weibo": "社交",
        "com.zhihu.ios": "社交",
        "com.tencent.mqq": "社交",
        "com.facebook.Facebook": "社交",
        "com.instagram.Instagram": "社交",
        "com.twitter.twitter": "社交",
        
        // Health/Fitness apps
        "com.apple.Health": "健康",
        "com.nike.nikeplus-gps": "健康",
        "com.myfitnesspal.MyFitnessPal": "健康",
        "com.apple.Fitness": "健康",
        "com.strava.stravarun": "健康",
        "com.calm.ios": "健康",
        
        // Shopping apps
        "com.taobao.taobao4iphone": "购物",
        "com.tmall.tmall": "购物",
        "com.jingdong.app.mall": "购物",
        "com.apple.AppStore": "购物",
        "com.amazon.Amazon": "购物",
        "com.meituan.imeituan": "购物",
        
        // Travel/Transportation apps
        "com.autonavi.amap": "出行",
        "com.baidu.map": "出行",
        "com.didi.passenger": "出行",
        "com.uber.Uber": "出行",
        "com.apple.Maps": "出行",
        "com.ctrip.wireless": "出行"
    ]
    
    /// App category identifiers to tag mapping for system categories
    private let systemCategoryMapping: [String: String] = [
        "productivity": "工作",
        "business": "工作",
        "developer": "工作",
        "education": "学习",
        "reference": "学习",
        "entertainment": "娱乐",
        "games": "娱乐",
        "social": "社交",
        "health": "健康",
        "lifestyle": "健康",
        "shopping": "购物",
        "finance": "购物",
        "travel": "出行",
        "navigation": "出行"
    ]
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        
        initializeDefaultTags()
        loadExistingTags()
    }
    
    // MARK: - Public Methods
    
    func getDefaultTags() -> [SceneTag] {
        return defaultTags
    }
    
    func createCustomTag(name: String, color: String) -> SceneTag? {
        // Check if tag with same name already exists
        if getAllTags().contains(where: { $0.name == name }) {
            print("TagManager: Tag with name '\(name)' already exists")
            return nil
        }
        
        let customTag = SceneTag.createTag(
            name: name,
            color: color,
            isDefault: false,
            in: viewContext
        )
        
        do {
            try viewContext.save()
            
            // Update local arrays
            customTags.append(customTag)
            availableTags.append(customTag)
            
            print("TagManager: Created custom tag '\(name)'")
            return customTag
        } catch {
            print("TagManager: Error creating custom tag - \(error)")
            return nil
        }
    }
    
    func suggestTagForApp(_ appIdentifier: String) -> TagRecommendation? {
        // First, check if app is already associated with a tag
        for tag in availableTags {
            if tag.isAppAssociated(appIdentifier) {
                return TagRecommendation(
                    tag: tag,
                    confidence: 1.0,
                    reason: "之前已关联此标签"
                )
            }
        }
        
        // Then check direct app mapping
        if let tagName = appCategoryMapping[appIdentifier] {
            if let tag = availableTags.first(where: { $0.name == tagName }) {
                return TagRecommendation(
                    tag: tag,
                    confidence: 0.9,
                    reason: "基于应用类型的精确匹配"
                )
            }
        }
        
        // Check system category mapping
        if let categoryId = getAppCategory(appIdentifier),
           let tagName = systemCategoryMapping[categoryId] {
            if let tag = availableTags.first(where: { $0.name == tagName }) {
                return TagRecommendation(
                    tag: tag,
                    confidence: 0.7,
                    reason: "基于应用分类的推荐"
                )
            }
        }
        
        // Fallback to usage pattern analysis
        return analyzeUsagePatternForRecommendation(appIdentifier)
    }
    
    /// Gets multiple tag recommendations for an app with different confidence levels
    func getTagRecommendations(_ appIdentifier: String, limit: Int = 3) -> [TagRecommendation] {
        var recommendations: [TagRecommendation] = []
        
        // Check if app is already associated with a tag
        for tag in availableTags {
            if tag.isAppAssociated(appIdentifier) {
                recommendations.append(TagRecommendation(
                    tag: tag,
                    confidence: 1.0,
                    reason: "之前已关联此标签"
                ))
            }
        }
        
        // Add direct app mapping
        if let tagName = appCategoryMapping[appIdentifier] {
            if let tag = availableTags.first(where: { $0.name == tagName }),
               !recommendations.contains(where: { $0.tag.tagID == tag.tagID }) {
                recommendations.append(TagRecommendation(
                    tag: tag,
                    confidence: 0.9,
                    reason: "基于应用类型的精确匹配"
                ))
            }
        }
        
        // Add system category mapping
        if let categoryId = getAppCategory(appIdentifier),
           let tagName = systemCategoryMapping[categoryId] {
            if let tag = availableTags.first(where: { $0.name == tagName }),
               !recommendations.contains(where: { $0.tag.tagID == tag.tagID }) {
                recommendations.append(TagRecommendation(
                    tag: tag,
                    confidence: 0.7,
                    reason: "基于应用分类的推荐"
                ))
            }
        }
        
        // Add usage pattern recommendations
        if let patternRecommendation = analyzeUsagePatternForRecommendation(appIdentifier),
           !recommendations.contains(where: { $0.tag.tagID == patternRecommendation.tag.tagID }) {
            recommendations.append(patternRecommendation)
        }
        
        // Sort by confidence and return top recommendations
        return Array(recommendations.sorted { $0.confidence > $1.confidence }.prefix(limit))
    }
    
    /// Applies a tag to an app usage session and learns from the association
    func applyTagToSession(_ session: AppUsageSession, tag: SceneTag, userConfirmed: Bool = true) {
        updateTagForSession(session, tag: tag)
        
        // If user confirmed this association, strengthen the learning
        if userConfirmed {
            learnFromUserChoice(appIdentifier: session.appIdentifier, chosenTag: tag)
        }
    }
    
    /// Bulk apply tags to multiple sessions
    func applyTagToSessions(_ sessions: [AppUsageSession], tag: SceneTag) {
        for session in sessions {
            session.sceneTag = tag.name
        }
        
        // Update tag associations
        let uniqueApps = Set(sessions.map { $0.appIdentifier })
        for appId in uniqueApps {
            tag.addAssociatedApp(appId)
        }
        
        tag.usageCount += Int32(sessions.count)
        
        do {
            try viewContext.save()
            print("TagManager: Applied tag '\(tag.name)' to \(sessions.count) sessions")
        } catch {
            print("TagManager: Error applying tag to sessions - \(error)")
        }
    }
    
    /// Removes tag from a session
    func removeTagFromSession(_ session: AppUsageSession) {
        let oldTagName = session.sceneTag
        session.sceneTag = nil
        
        // Optionally remove app association if no other sessions use this tag
        if let tagName = oldTagName,
           let tag = availableTags.first(where: { $0.name == tagName }) {
            
            let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
            request.predicate = NSPredicate(format: "appIdentifier == %@ AND sceneTag == %@", 
                                          session.appIdentifier, tagName)
            request.fetchLimit = 1
            
            do {
                let remainingSessions = try viewContext.fetch(request)
                if remainingSessions.isEmpty {
                    tag.removeAssociatedApp(session.appIdentifier)
                }
                
                try viewContext.save()
                print("TagManager: Removed tag from session")
            } catch {
                print("TagManager: Error removing tag from session - \(error)")
            }
        }
    }
    
    func updateTagForSession(_ session: AppUsageSession, tag: SceneTag) {
        // Update session with new tag
        session.sceneTag = tag.name
        
        // Associate app with tag for future recommendations
        tag.addAssociatedApp(session.appIdentifier)
        tag.incrementUsageCount()
        
        do {
            try viewContext.save()
            print("TagManager: Updated session with tag '\(tag.name)' for app '\(session.appName)'")
        } catch {
            print("TagManager: Error updating session tag - \(error)")
        }
    }
    
    func getTagDistribution(for date: Date) -> [TagDistribution] {
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
            
            var distributions: [TagDistribution] = []
            
            for (tagName, tagSessions) in groupedSessions {
                let tagTime = tagSessions.reduce(0) { $0 + $1.duration }
                let percentage = totalTime > 0 ? (tagTime / totalTime) * 100 : 0
                let color = availableTags.first(where: { $0.name == tagName })?.color ?? "#999999"
                
                distributions.append(TagDistribution(
                    tagName: tagName,
                    color: color,
                    usageTime: tagTime,
                    percentage: percentage,
                    sessionCount: tagSessions.count
                ))
            }
            
            return distributions.sorted { $0.usageTime > $1.usageTime }
        } catch {
            print("TagManager: Error fetching tag distribution - \(error)")
            return []
        }
    }
    
    func getTagTrends(for period: DateInterval) -> [TagTrend] {
        let calendar = Calendar.current
        let startDate = period.start
        let endDate = period.end
        
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "startTime >= %@ AND startTime < %@ AND sceneTag != nil",
            startDate as NSDate, endDate as NSDate
        )
        
        do {
            let sessions = try viewContext.fetch(request)
            var trends: [TagTrend] = []
            
            // Group by date and tag
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let groupedByDate = Dictionary(grouping: sessions) { session in
                calendar.startOfDay(for: session.startTime)
            }
            
            for (date, dateSessions) in groupedByDate {
                let groupedByTag = Dictionary(grouping: dateSessions) { $0.sceneTag ?? "未分类" }
                
                for (tagName, tagSessions) in groupedByTag {
                    let totalTime = tagSessions.reduce(0) { $0 + $1.duration }
                    
                    trends.append(TagTrend(
                        date: date,
                        tagName: tagName,
                        usageTime: totalTime,
                        sessionCount: tagSessions.count
                    ))
                }
            }
            
            return trends.sorted { $0.date < $1.date }
        } catch {
            print("TagManager: Error fetching tag trends - \(error)")
            return []
        }
    }
    
    func getAllTags() -> [SceneTag] {
        return availableTags
    }
    
    func deleteTag(_ tag: SceneTag) -> Bool {
        // Don't allow deletion of default tags
        guard !tag.isDefault else {
            print("TagManager: Cannot delete default tag '\(tag.name)'")
            return false
        }
        
        // Remove tag associations from sessions
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "sceneTag == %@", tag.name)
        
        do {
            let sessions = try viewContext.fetch(request)
            for session in sessions {
                session.sceneTag = nil
            }
            
            // Delete the tag
            viewContext.delete(tag)
            try viewContext.save()
            
            // Update local arrays
            customTags.removeAll { $0.tagID == tag.tagID }
            availableTags.removeAll { $0.tagID == tag.tagID }
            
            print("TagManager: Deleted custom tag '\(tag.name)'")
            return true
        } catch {
            print("TagManager: Error deleting tag - \(error)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func initializeDefaultTags() {
        // Check if default tags already exist
        let request: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        
        do {
            let existingDefaultTags = try viewContext.fetch(request)
            
            if existingDefaultTags.isEmpty {
                // Create default tags
                let newDefaultTags = SceneTag.createDefaultTags(in: viewContext)
                try viewContext.save()
                
                defaultTags = newDefaultTags
                print("TagManager: Created \(newDefaultTags.count) default tags")
            } else {
                defaultTags = existingDefaultTags
                print("TagManager: Loaded \(existingDefaultTags.count) existing default tags")
            }
        } catch {
            print("TagManager: Error initializing default tags - \(error)")
            // Create fallback default tags in memory
            defaultTags = []
        }
    }
    
    private func loadExistingTags() {
        let request: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SceneTag.isDefault, ascending: false),
            NSSortDescriptor(keyPath: \SceneTag.createdAt, ascending: true)
        ]
        
        do {
            let allTags = try viewContext.fetch(request)
            
            defaultTags = allTags.filter { $0.isDefault }
            customTags = allTags.filter { !$0.isDefault }
            availableTags = allTags
            
            isInitialized = true
            print("TagManager: Loaded \(allTags.count) tags (\(defaultTags.count) default, \(customTags.count) custom)")
        } catch {
            print("TagManager: Error loading existing tags - \(error)")
            availableTags = defaultTags
            isInitialized = true
        }
    }
    
    private func getAppCategory(_ appIdentifier: String) -> String? {
        // This would typically query the system or a database for app category
        // For now, we'll use some basic heuristics based on bundle identifier
        
        if appIdentifier.contains("microsoft") || appIdentifier.contains("office") {
            return "productivity"
        } else if appIdentifier.contains("game") || appIdentifier.contains("tencent.xin.game") {
            return "games"
        } else if appIdentifier.contains("music") || appIdentifier.contains("video") || appIdentifier.contains("netflix") {
            return "entertainment"
        } else if appIdentifier.contains("weibo") || appIdentifier.contains("facebook") || appIdentifier.contains("twitter") {
            return "social"
        } else if appIdentifier.contains("health") || appIdentifier.contains("fitness") {
            return "health"
        } else if appIdentifier.contains("shop") || appIdentifier.contains("taobao") || appIdentifier.contains("mall") {
            return "shopping"
        } else if appIdentifier.contains("map") || appIdentifier.contains("didi") || appIdentifier.contains("uber") {
            return "travel"
        }
        
        return nil
    }
    
    private func analyzeUsagePatternForRecommendation(_ appIdentifier: String) -> TagRecommendation? {
        // Analyze historical usage patterns to suggest a tag
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "appIdentifier == %@", appIdentifier)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AppUsageSession.startTime, ascending: false)]
        request.fetchLimit = 20
        
        do {
            let recentSessions = try viewContext.fetch(request)
            guard !recentSessions.isEmpty else { return nil }
            
            // Analyze usage time patterns
            let calendar = Calendar.current
            var workHourSessions = 0
            var eveningSessions = 0
            var weekendSessions = 0
            var longSessions = 0
            var totalDuration: TimeInterval = 0
            
            for session in recentSessions {
                let hour = calendar.component(.hour, from: session.startTime)
                let weekday = calendar.component(.weekday, from: session.startTime)
                
                totalDuration += session.duration
                
                if hour >= 9 && hour <= 17 {
                    workHourSessions += 1
                }
                if hour >= 18 && hour <= 22 {
                    eveningSessions += 1
                }
                if weekday == 1 || weekday == 7 { // Sunday or Saturday
                    weekendSessions += 1
                }
                if session.duration >= 30 * 60 { // 30+ minutes
                    longSessions += 1
                }
            }
            
            let averageDuration = totalDuration / Double(recentSessions.count)
            let sessionCount = recentSessions.count
            
            // Make recommendation based on usage patterns
            if workHourSessions > sessionCount / 2 {
                if let workTag = availableTags.first(where: { $0.name == "工作" }) {
                    return TagRecommendation(
                        tag: workTag,
                        confidence: 0.6,
                        reason: "主要在工作时间使用"
                    )
                }
            } else if eveningSessions > sessionCount / 2 {
                if let entertainmentTag = availableTags.first(where: { $0.name == "娱乐" }) {
                    return TagRecommendation(
                        tag: entertainmentTag,
                        confidence: 0.5,
                        reason: "主要在晚间使用"
                    )
                }
            } else if weekendSessions > sessionCount / 2 {
                if let entertainmentTag = availableTags.first(where: { $0.name == "娱乐" }) {
                    return TagRecommendation(
                        tag: entertainmentTag,
                        confidence: 0.4,
                        reason: "主要在周末使用"
                    )
                }
            } else if longSessions > sessionCount / 2 && averageDuration >= 45 * 60 {
                if let studyTag = availableTags.first(where: { $0.name == "学习" }) {
                    return TagRecommendation(
                        tag: studyTag,
                        confidence: 0.5,
                        reason: "长时间专注使用"
                    )
                }
            }
            
        } catch {
            print("TagManager: Error analyzing usage pattern - \(error)")
        }
        
        return nil
    }
    
    /// Learns from user's tag choice to improve future recommendations
    private func learnFromUserChoice(appIdentifier: String, chosenTag: SceneTag) {
        // This method can be enhanced with machine learning in the future
        // For now, we strengthen the association by ensuring the app is linked to the tag
        chosenTag.addAssociatedApp(appIdentifier)
        
        // Update app category mapping based on user choice (simple learning)
        // This could be expanded to use Core ML for more sophisticated learning
        print("TagManager: Learning from user choice - App: \(appIdentifier), Tag: \(chosenTag.name)")
    }
    
    /// Gets statistics about tag usage and accuracy
    func getTagRecommendationStats() -> (totalRecommendations: Int, accurateRecommendations: Int, accuracy: Double) {
        // This would track recommendation accuracy over time
        // For now, return placeholder values
        return (totalRecommendations: 0, accurateRecommendations: 0, accuracy: 0.0)
    }
    
    /// Finds similar apps based on usage patterns and existing tag associations
    func findSimilarApps(to appIdentifier: String) -> [String] {
        // Find apps that have similar usage patterns or are in the same category
        var similarApps: [String] = []
        
        // First, find apps with the same tag
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(format: "appIdentifier == %@ AND sceneTag != nil", appIdentifier)
        request.fetchLimit = 1
        
        do {
            let sessions = try viewContext.fetch(request)
            if let tagName = sessions.first?.sceneTag {
                let similarRequest: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
                similarRequest.predicate = NSPredicate(format: "sceneTag == %@ AND appIdentifier != %@", tagName, appIdentifier)
                
                let similarSessions = try viewContext.fetch(similarRequest)
                similarApps = Array(Set(similarSessions.map { $0.appIdentifier }))
            }
        } catch {
            print("TagManager: Error finding similar apps - \(error)")
        }
        
        return similarApps
    }
}