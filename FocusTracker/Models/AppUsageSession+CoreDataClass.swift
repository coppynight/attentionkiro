import Foundation
import CoreData

@objc(AppUsageSession)
public class AppUsageSession: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Returns the duration of the app usage session in a human-readable format
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Returns true if this is an active (ongoing) usage session
    var isActive: Bool {
        return endTime == nil
    }
    
    /// Returns the actual duration if session is complete, or current duration if ongoing
    var currentDuration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        } else {
            return Date().timeIntervalSince(startTime)
        }
    }
    
    /// Returns the app category display name
    var categoryDisplayName: String {
        guard let categoryId = categoryIdentifier else { return "未分类" }
        
        // Map system category identifiers to display names
        switch categoryId {
        case "productivity":
            return "效率工具"
        case "social":
            return "社交网络"
        case "entertainment":
            return "娱乐"
        case "games":
            return "游戏"
        case "education":
            return "教育"
        case "health":
            return "健康健身"
        case "finance":
            return "财务"
        case "shopping":
            return "购物"
        case "travel":
            return "旅行"
        case "news":
            return "新闻"
        case "utilities":
            return "工具"
        case "reference":
            return "参考"
        case "lifestyle":
            return "生活"
        case "business":
            return "商务"
        case "developer":
            return "开发者工具"
        default:
            return "其他"
        }
    }
    
    // MARK: - Helper Methods
    
    /// Ends the app usage session and calculates the final duration
    func endSession() {
        guard endTime == nil else { return }
        
        let now = Date()
        endTime = now
        duration = now.timeIntervalSince(startTime)
    }
    
    /// Updates the interruption count
    func recordInterruption() {
        interruptionCount += 1
    }
    
    /// Determines if this session represents productive time based on app category and duration
    func evaluateProductivity() -> Bool {
        guard let categoryId = categoryIdentifier else { return false }
        
        // Define productive categories
        let productiveCategories = ["productivity", "education", "business", "developer", "reference"]
        let isProductiveCategory = productiveCategories.contains(categoryId)
        
        // Consider sessions longer than 5 minutes in productive categories as productive
        let minimumProductiveTime: TimeInterval = 5 * 60 // 5 minutes
        let hasMinimumDuration = duration >= minimumProductiveTime
        
        return isProductiveCategory && hasMinimumDuration
    }
    
    /// Updates the productive time flag based on current session data
    func updateProductivityStatus() {
        isProductiveTime = evaluateProductivity()
    }
    
    /// Creates a new app usage session
    static func createSession(
        appIdentifier: String,
        appName: String,
        categoryIdentifier: String? = nil,
        startTime: Date = Date(),
        in context: NSManagedObjectContext
    ) -> AppUsageSession {
        let session = AppUsageSession(context: context)
        session.appIdentifier = appIdentifier
        session.appName = appName
        session.categoryIdentifier = categoryIdentifier
        session.startTime = startTime
        session.duration = 0
        session.interruptionCount = 0
        session.isProductiveTime = false
        
        return session
    }
}