import Foundation
import CoreData

@objc(UserSettings)
public class UserSettings: NSManagedObject {
    
    // MARK: - Default Values
    
    static let defaultTimeBlockGranularity: TimeInterval = 20 * 60 // 20 minutes
    static let defaultDailyGoalHours: Double = 8.0
    static let defaultWorkingHoursStart = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    static let defaultWorkingHoursEnd = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    static let defaultHeatmapColorScheme = "github"
    
    // MARK: - Convenience Methods
    
    /// Get or create the singleton user settings instance
    static func getOrCreate(in context: NSManagedObjectContext) -> UserSettings {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try context.fetch(request)
            if let existingSettings = settings.first {
                return existingSettings
            }
        } catch {
            print("Error fetching user settings: \(error)")
        }
        
        // Create new settings with default values
        let newSettings = UserSettings(context: context)
        newSettings.timeBlockGranularity = defaultTimeBlockGranularity
        newSettings.dailyGoalHours = defaultDailyGoalHours
        newSettings.workingHoursStart = defaultWorkingHoursStart
        newSettings.workingHoursEnd = defaultWorkingHoursEnd
        newSettings.heatmapColorScheme = defaultHeatmapColorScheme
        newSettings.enableBeautifulMoments = true
        newSettings.autoTaggingEnabled = false
        newSettings.weeklyReviewEnabled = true
        
        return newSettings
    }
    
    // MARK: - Computed Properties
    
    /// Formatted time block granularity for display
    var formattedGranularity: String {
        let minutes = Int(timeBlockGranularity) / 60
        return "\(minutes) 分钟"
    }
    
    /// Formatted daily goal for display
    var formattedDailyGoal: String {
        return String(format: "%.1f 小时", dailyGoalHours)
    }
    
    /// Working hours duration in seconds
    var workingHoursDuration: TimeInterval {
        guard let start = workingHoursStart, let end = workingHoursEnd else {
            return 9 * 3600 // Default 9 hours
        }
        return end.timeIntervalSince(start)
    }
}