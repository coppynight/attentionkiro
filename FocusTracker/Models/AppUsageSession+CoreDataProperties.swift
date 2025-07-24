import Foundation
import CoreData

extension AppUsageSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppUsageSession> {
        return NSFetchRequest<AppUsageSession>(entityName: "AppUsageSession")
    }

    @NSManaged public var appIdentifier: String
    @NSManaged public var appName: String
    @NSManaged public var categoryIdentifier: String?
    @NSManaged public var duration: Double
    @NSManaged public var endTime: Date?
    @NSManaged public var interruptionCount: Int16
    @NSManaged public var isProductiveTime: Bool
    @NSManaged public var sceneTag: String?
    @NSManaged public var startTime: Date

}