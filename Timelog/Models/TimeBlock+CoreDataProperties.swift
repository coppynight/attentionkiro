import Foundation
import CoreData

extension TimeBlock {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeBlock> {
        return NSFetchRequest<TimeBlock>(entityName: "TimeBlock")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var duration: Double
    @NSManaged public var taggedActivity: String?
    @NSManaged public var category: String?
    @NSManaged public var notes: String?
    @NSManaged public var isTagged: Bool
    @NSManaged public var commits: NSSet?
    @NSManaged public var tags: NSSet?

}

// MARK: Generated accessors for commits
extension TimeBlock {

    @objc(addCommitsObject:)
    @NSManaged public func addToCommits(_ value: TimeCommit)

    @objc(removeCommitsObject:)
    @NSManaged public func removeFromCommits(_ value: TimeCommit)

    @objc(addCommits:)
    @NSManaged public func addToCommits(_ values: NSSet)

    @objc(removeCommits:)
    @NSManaged public func removeFromCommits(_ values: NSSet)

}

// MARK: Generated accessors for tags
extension TimeBlock {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: TimeTag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: TimeTag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}

extension TimeBlock : Identifiable {

}