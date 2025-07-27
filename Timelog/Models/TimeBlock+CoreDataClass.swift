import Foundation
import CoreData

@objc(TimeBlock)
public class TimeBlock: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Formatted time range string for display
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        guard let start = startTime, let end = endTime else {
            return "Invalid time range"
        }
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    /// Formatted duration string for display
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    /// Check if this time block represents a beautiful moment
    var isBeautifulMoment: Bool {
        // Check if any commits are marked as beautiful moments
        if let commits = commits?.allObjects as? [TimeCommit] {
            return commits.contains { $0.isBeautifulMoment }
        }
        // Fallback to legacy check
        return notes?.contains("✨") == true || taggedActivity?.contains("美好时刻") == true
    }
    
    /// Get all associated commits as an array
    var commitsArray: [TimeCommit] {
        guard let commits = commits?.allObjects as? [TimeCommit] else { return [] }
        return commits.sorted { ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast) }
    }
    
    /// Get all associated tags as an array
    var tagsArray: [TimeTag] {
        guard let tags = tags?.allObjects as? [TimeTag] else { return [] }
        return tags.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    /// Get the primary commit (usually the first or most important one)
    var primaryCommit: TimeCommit? {
        return commitsArray.first
    }
    
    /// Calculate average focus intensity from all commits
    var averageFocusIntensity: Double {
        let commits = commitsArray
        guard !commits.isEmpty else { return 0.0 }
        let totalIntensity = commits.reduce(0.0) { $0 + $1.focusIntensity }
        return totalIntensity / Double(commits.count)
    }
    
    /// Get formatted tag names for display
    var formattedTagNames: String {
        let tagNames = tagsArray.compactMap { $0.name }
        return tagNames.isEmpty ? "未标记" : tagNames.joined(separator: ", ")
    }
    
    // MARK: - Convenience Methods
    
    /// Create a new time block with the given parameters
    static func create(in context: NSManagedObjectContext,
                      startTime: Date,
                      endTime: Date,
                      activity: String? = nil,
                      category: String? = nil,
                      notes: String? = nil) -> TimeBlock {
        let timeBlock = TimeBlock(context: context)
        timeBlock.id = UUID()
        timeBlock.startTime = startTime
        timeBlock.endTime = endTime
        timeBlock.duration = endTime.timeIntervalSince(startTime)
        timeBlock.taggedActivity = activity
        timeBlock.category = category
        timeBlock.notes = notes
        timeBlock.isTagged = activity != nil
        return timeBlock
    }
    
    /// Update the time block with new tagging information
    func updateTag(activity: String, category: String, notes: String? = nil) {
        self.taggedActivity = activity
        self.category = category
        self.notes = notes
        self.isTagged = true
    }
    
    /// Remove all tagging information
    func removeTag() {
        self.taggedActivity = nil
        self.category = nil
        self.notes = nil
        self.isTagged = false
    }
    
    /// Add a commit to this time block
    func addCommit(message: String, 
                  focusIntensity: Double = 0.5,
                  interruptionCount: Int32 = 0,
                  isBeautifulMoment: Bool = false) -> TimeCommit {
        guard let context = managedObjectContext else {
            fatalError("TimeBlock must have a managed object context")
        }
        
        let commit = TimeCommit.create(
            in: context,
            timeBlock: self,
            commitMessage: message,
            focusIntensity: focusIntensity,
            interruptionCount: interruptionCount,
            isBeautifulMoment: isBeautifulMoment
        )
        
        return commit
    }
    
    /// Add a tag to this time block
    func addTag(_ tag: TimeTag) {
        addToTags(tag)
        tag.incrementUsage()
        self.isTagged = true
    }
    
    /// Remove a tag from this time block
    func removeTag(_ tag: TimeTag) {
        removeFromTags(tag)
        
        // Update isTagged status based on remaining tags
        self.isTagged = (tags?.count ?? 0) > 0 || taggedActivity != nil
    }
    
    /// Add multiple tags to this time block
    func addTags(_ tagsToAdd: [TimeTag]) {
        for tag in tagsToAdd {
            addTag(tag)
        }
    }
    
    /// Remove all tags from this time block
    func removeAllTags() {
        if let currentTags = tags?.allObjects as? [TimeTag] {
            for tag in currentTags {
                removeFromTags(tag)
            }
        }
        
        // Update isTagged status
        self.isTagged = taggedActivity != nil
    }
    
    /// Check if this time block has a specific tag
    func hasTag(named tagName: String) -> Bool {
        return tagsArray.contains { $0.name == tagName }
    }
    
    /// Get the highest quality commit
    var bestCommit: TimeCommit? {
        return commitsArray.max { $0.qualityScore < $1.qualityScore }
    }
    
    /// Calculate total interruptions across all commits
    var totalInterruptions: Int32 {
        return commitsArray.reduce(0) { $0 + $1.interruptionCount }
    }
}