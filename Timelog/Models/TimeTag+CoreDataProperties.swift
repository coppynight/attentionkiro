import Foundation
import CoreData

extension TimeTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeTag> {
        return NSFetchRequest<TimeTag>(entityName: "TimeTag")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var tagDescription: String?
    @NSManaged public var category: String?
    @NSManaged public var color: String?
    @NSManaged public var icon: String?
    @NSManaged public var isDefault: Bool
    @NSManaged public var usageCount: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastUsedAt: Date?
    @NSManaged public var timeBlocks: NSSet?

}

// MARK: Generated accessors for timeBlocks
extension TimeTag {

    @objc(addTimeBlocksObject:)
    @NSManaged public func addToTimeBlocks(_ value: TimeBlock)

    @objc(removeTimeBlocksObject:)
    @NSManaged public func removeFromTimeBlocks(_ value: TimeBlock)

    @objc(addTimeBlocks:)
    @NSManaged public func addToTimeBlocks(_ values: NSSet)

    @objc(removeTimeBlocks:)
    @NSManaged public func removeFromTimeBlocks(_ values: NSSet)

}

extension TimeTag : Identifiable {

}