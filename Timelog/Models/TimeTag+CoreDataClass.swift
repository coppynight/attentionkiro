import Foundation
import CoreData

@objc(TimeTag)
public class TimeTag: NSManagedObject {
    
    // MARK: - Default Tags
    
    static let defaultTags = [
        ("工作", "工作相关的时间投入", "#007AFF", true),
        ("学习", "学习和技能提升", "#34C759", true),
        ("娱乐", "休闲娱乐时光", "#FF9500", true),
        ("社交", "与他人的交流互动", "#FF2D92", true),
        ("运动", "体育锻炼和健身", "#FF3B30", true),
        ("阅读", "阅读书籍和文章", "#5856D6", true),
        ("创作", "创意和创作活动", "#AF52DE", true),
        ("思考", "深度思考和反思", "#00C7BE", true),
        ("美好时刻", "特别珍贵的时光", "#FFD60A", true)
    ]
    
    // MARK: - Computed Properties
    
    /// Formatted usage count for display
    var formattedUsageCount: String {
        return "\(usageCount) 次使用"
    }
    
    /// Check if this tag is frequently used
    var isFrequentlyUsed: Bool {
        return usageCount >= 10
    }
    
    /// Get the color as a hex string with fallback
    var safeColor: String {
        return color ?? "#007AFF"
    }
    
    /// Get display name with emoji for beautiful moments
    var displayName: String {
        if name == "美好时刻" {
            return "✨ \(name ?? "")"
        }
        return name ?? "未命名标签"
    }
    
    // MARK: - Convenience Methods
    
    /// Create a new time tag with the given parameters
    static func create(in context: NSManagedObjectContext,
                      name: String,
                      description: String? = nil,
                      color: String = "#007AFF",
                      isDefault: Bool = false) -> TimeTag {
        let tag = TimeTag(context: context)
        tag.id = UUID()
        tag.name = name
        tag.tagDescription = description
        tag.color = color
        tag.isDefault = isDefault
        tag.usageCount = 0
        tag.createdAt = Date()
        return tag
    }
    
    /// Create all default tags if they don't exist
    static func createDefaultTags(in context: NSManagedObjectContext) {
        let existingTags = fetchExistingTagNames(in: context)
        
        for (name, description, color, isDefault) in defaultTags {
            if !existingTags.contains(name) {
                _ = TimeTag.create(
                    in: context,
                    name: name,
                    description: description,
                    color: color,
                    isDefault: isDefault
                )
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to create default tags: \(error)")
        }
    }
    
    /// Fetch existing tag names to avoid duplicates
    private static func fetchExistingTagNames(in context: NSManagedObjectContext) -> Set<String> {
        let request: NSFetchRequest<TimeTag> = TimeTag.fetchRequest()
        request.propertiesToFetch = ["name"]
        
        do {
            let tags = try context.fetch(request)
            return Set(tags.compactMap { $0.name })
        } catch {
            print("Failed to fetch existing tags: \(error)")
            return Set()
        }
    }
    
    /// Increment usage count when tag is applied
    func incrementUsage() {
        usageCount += 1
    }
    
    /// Update tag information
    func updateTag(name: String? = nil,
                  description: String? = nil,
                  color: String? = nil) {
        if let name = name {
            self.name = name
        }
        if let description = description {
            self.tagDescription = description
        }
        if let color = color {
            self.color = color
        }
    }
    
    /// Get all time blocks associated with this tag
    func getAssociatedTimeBlocks() -> [TimeBlock] {
        guard let timeBlocks = timeBlocks else { return [] }
        return Array(timeBlocks) as? [TimeBlock] ?? []
    }
    
    /// Calculate total time spent with this tag
    func getTotalTimeSpent() -> TimeInterval {
        let blocks = getAssociatedTimeBlocks()
        return blocks.reduce(0) { $0 + $1.duration }
    }
    
    /// Get formatted total time spent
    var formattedTotalTime: String {
        let totalTime = getTotalTimeSpent()
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Fetch Requests

extension TimeTag {
    
    /// Fetch all tags sorted by usage count
    static func fetchByUsage(in context: NSManagedObjectContext) -> [TimeTag] {
        let request: NSFetchRequest<TimeTag> = TimeTag.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TimeTag.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \TimeTag.name, ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch tags by usage: \(error)")
            return []
        }
    }
    
    /// Fetch default tags only
    static func fetchDefaultTags(in context: NSManagedObjectContext) -> [TimeTag] {
        let request: NSFetchRequest<TimeTag> = TimeTag.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeTag.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch default tags: \(error)")
            return []
        }
    }
    
    /// Fetch custom tags only
    static func fetchCustomTags(in context: NSManagedObjectContext) -> [TimeTag] {
        let request: NSFetchRequest<TimeTag> = TimeTag.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == NO")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TimeTag.createdAt, ascending: false)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch custom tags: \(error)")
            return []
        }
    }
}