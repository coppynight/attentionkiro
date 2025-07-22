import Foundation
import CoreData

@objc(FocusSession)
public class FocusSession: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Returns the duration of the focus session in a human-readable format
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// Returns true if this is an active (ongoing) focus session
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
    
    // MARK: - Helper Methods
    
    /// Ends the focus session and calculates the final duration
    func endSession() {
        guard endTime == nil else { return }
        
        endTime = Date()
        duration = endTime!.timeIntervalSince(startTime)
    }
    
    /// Validates if the session meets minimum focus criteria
    func validateSession() -> Bool {
        let minimumFocusTime: TimeInterval = 30 * 60 // 30 minutes
        return duration >= minimumFocusTime
    }
}