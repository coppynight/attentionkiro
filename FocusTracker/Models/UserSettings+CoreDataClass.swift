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
    
    /// Returns the current timezone offset in hours
    var currentTimeZoneOffsetHours: Double {
        if useLocalTimeZone {
            // Use system timezone
            return Double(TimeZone.current.secondsFromGMT()) / 3600.0
        } else {
            // Use manually set timezone offset
            return timeZoneOffset
        }
    }
    
    // MARK: - Helper Methods
    
    /// Checks if a given time falls within the sleep period, accounting for timezone
    func isWithinSleepTime(_ date: Date) -> Bool {
        // If flexible sleep days is enabled, check if today is a weekend
        if flexibleSleepDays {
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: date)
            
            // If it's weekend (Saturday or Sunday), don't apply sleep time filtering
            if weekday == 1 || weekday == 7 {
                return false
            }
        }
        
        // Adjust for timezone if needed
        let adjustedDate = adjustForTimeZone(date)
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: adjustedDate)
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
    
    /// Checks if a given time falls within the lunch break period, accounting for timezone
    func isWithinLunchBreak(_ date: Date) -> Bool {
        guard lunchBreakEnabled,
              let lunchStart = lunchBreakStart,
              let lunchEnd = lunchBreakEnd else {
            return false
        }
        
        // Adjust for timezone if needed
        let adjustedDate = adjustForTimeZone(date)
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: adjustedDate)
        let currentMinutes = (timeComponents.hour ?? 0) * 60 + (timeComponents.minute ?? 0)
        
        let lunchStartComponents = calendar.dateComponents([.hour, .minute], from: lunchStart)
        let lunchEndComponents = calendar.dateComponents([.hour, .minute], from: lunchEnd)
        
        let startMinutes = (lunchStartComponents.hour ?? 0) * 60 + (lunchStartComponents.minute ?? 0)
        let endMinutes = (lunchEndComponents.hour ?? 0) * 60 + (lunchEndComponents.minute ?? 0)
        
        // Check if the current time is within the lunch break period
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }
    
    /// Adjusts a date for the configured timezone settings
    func adjustForTimeZone(_ date: Date) -> Date {
        if !useLocalTimeZone {
            // Calculate the difference between the configured timezone and the system timezone
            let systemOffset = Double(TimeZone.current.secondsFromGMT())
            let configuredOffset = timeZoneOffset * 3600.0
            let offsetDifference = configuredOffset - systemOffset
            
            // Apply the offset difference to the date
            return date.addingTimeInterval(offsetDifference)
        }
        
        // If using local timezone, no adjustment needed
        return date
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
        
        // Default timezone settings
        settings.useLocalTimeZone = true
        settings.timeZoneOffset = Double(TimeZone.current.secondsFromGMT()) / 3600.0
        settings.flexibleSleepDays = false
        
        return settings
    }
    
    /// Returns a list of common timezone offsets
    static var commonTimeZoneOffsets: [(name: String, offset: Double)] {
        return [
            ("GMT-12:00", -12.0),
            ("GMT-11:00", -11.0),
            ("GMT-10:00", -10.0),
            ("GMT-09:00", -9.0),
            ("GMT-08:00", -8.0),
            ("GMT-07:00", -7.0),
            ("GMT-06:00", -6.0),
            ("GMT-05:00", -5.0),
            ("GMT-04:00", -4.0),
            ("GMT-03:00", -3.0),
            ("GMT-02:00", -2.0),
            ("GMT-01:00", -1.0),
            ("GMT+00:00", 0.0),
            ("GMT+01:00", 1.0),
            ("GMT+02:00", 2.0),
            ("GMT+03:00", 3.0),
            ("GMT+04:00", 4.0),
            ("GMT+05:00", 5.0),
            ("GMT+05:30", 5.5),
            ("GMT+06:00", 6.0),
            ("GMT+07:00", 7.0),
            ("GMT+08:00", 8.0),
            ("GMT+09:00", 9.0),
            ("GMT+10:00", 10.0),
            ("GMT+11:00", 11.0),
            ("GMT+12:00", 12.0),
        ]
    }
    
    /// Returns the formatted timezone offset string
    func formattedTimeZoneOffset() -> String {
        let offset = useLocalTimeZone ? Double(TimeZone.current.secondsFromGMT()) / 3600.0 : timeZoneOffset
        
        let hours = Int(offset)
        let minutes = Int(abs(offset.truncatingRemainder(dividingBy: 1)) * 60)
        
        let sign = offset >= 0 ? "+" : "-"
        return String(format: "GMT%@%02d:%02d", sign, abs(hours), minutes)
    }
}