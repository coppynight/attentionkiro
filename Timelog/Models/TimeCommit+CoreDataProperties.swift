import Foundation
import CoreData

extension TimeCommit {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeCommit> {
        return NSFetchRequest<TimeCommit>(entityName: "TimeCommit")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var commitHash: String?
    @NSManaged public var commitMessage: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var focusIntensity: Double
    @NSManaged public var interruptionCount: Int32
    @NSManaged public var isBeautifulMoment: Bool
    @NSManaged public var qualityScore: Double
    @NSManaged public var timeBlock: TimeBlock?

}

extension TimeCommit : Identifiable {

}