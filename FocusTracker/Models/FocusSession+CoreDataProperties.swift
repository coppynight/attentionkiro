import Foundation
import CoreData

extension FocusSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FocusSession> {
        return NSFetchRequest<FocusSession>(entityName: "FocusSession")
    }

    @NSManaged public var activityName: String?
    @NSManaged public var category: String?
    @NSManaged public var duration: Double
    @NSManaged public var endTime: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isActive: Bool
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isValid: Bool
    @NSManaged public var notes: String?
    @NSManaged public var sessionType: String
    @NSManaged public var startTime: Date
    @NSManaged public var targetDuration: Double

}