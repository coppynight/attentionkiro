import Foundation
import CoreData

extension FocusSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FocusSession> {
        return NSFetchRequest<FocusSession>(entityName: "FocusSession")
    }

    @NSManaged public var duration: Double
    @NSManaged public var endTime: Date?
    @NSManaged public var isValid: Bool
    @NSManaged public var sessionType: String
    @NSManaged public var startTime: Date

}