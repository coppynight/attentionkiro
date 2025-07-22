import Foundation
import CoreData

@objc(UserSettings)
public class UserSettings: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Returns the daily focus goal in hours and minutes format
    var formattedDailyGoal: String {
        let hours = Int(dailyFocusGoal) / 3600
        let minutes = Int(dailyFocusGoal.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Returns the sleep duration in hours
    var sleepDurationHours: Double {
        let calendar = Calendar.current
        let sleepStart = calendar.dateComponents([.hour, .minute], from: sleepStartTime)
        let sleepEnd = calendar.dateComponents([.hour, .minute], from: sleepEndTime)
        
        let startMinutes = (sleepStart.hour ?? 0) * 60 + (sleepStart.minute ?? 0)
        let endMinutes = (sleepEnd.hour ?? 0) * 60 + (sleepEnd.minute ?? 0)
        
        var duration = endMinutes - startMinutes
        if duration < 0 {
            duration += 24 * 60 // Handle overnight sleep
        }
        
        return Double(duration) / 60.0
    }
    
    // MARK: - Helper Methods
    
    /// Checks if a given time falls within the sleep period
    func isWithinSleepTime(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        let currentMinutes = (timeComponents.hour ?? 0) * 60 + (timeComponents.minute ?? 0)
        
        let sleepStart = calendar.dateComponents([.hour, .minute], from: sleepStartTime)
        let sleepEnd = calendar.dateComponents([.hour, .minute], from: sleepEndTime)
        
        let startMinutes = (sleepStart.hour ?? 0) * 60 + (sleepStart.minute ?? 0)
        let endMinutes = (sleepEnd.hour ?? 0) * 60 + (sleepEnd.minute ?? 0)
        
        if startMinutes <= endMinutes {
            // Same day sleep period
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            // Overnight sleep period
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }
    
    /// Checks if a given time falls within the lunch break period
    func isWithinLunchBreak(_ date: Date) -> Bool {
        guard lunchBreakEnabled,
              let lunchStart = lunchBreakStart,
              let lunchEnd = lunchBreakEnd else {
            return false
        }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
        let currentMinutes = (timeComponents.hour ?? 0) * 60 + (timeComponents.minute ?? 0)
        
        let lunchStartComponents = calendar.dateComponents([.hour, .minute], from: lunchStart)
        let lunchEndComponents = calendar.dateComponents([.hour, .minute], from: lunchEnd)
        
        let startMinutes = (lunchStartComponents.hour ?? 0) * 60 + (lunchStartComponents.minute ?? 0)
        let endMinutes = (lunchEndComponents.hour ?? 0) * 60 + (lunchEndComponents.minute ?? 0)
        
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }
    
    /// Returns default settings
    static func createDefaultSettings(in context: NSManagedObjectContext) -> UserSettings {
        let settings = UserSettings(context: context)
        
        // Set default values
        settings.dailyFocusGoal = 2 * 3600 // 2 hours default goal
        settings.notificationsEnabled = true
        settings.lunchBreakEnabled = false
        
        // Default sleep time: 11 PM to 7 AM
        let calendar = Calendar.current
        settings.sleepStartTime = calendar.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
        settings.sleepEndTime = calendar.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        
        // Default lunch break: 12 PM to 2 PM
        settings.lunchBreakStart = calendar.date(from: DateComponents(hour: 12, minute: 0))
        settings.lunchBreakEnd = calendar.date(from: DateComponents(hour: 14, minute: 0))
        
        return settings
    }
}