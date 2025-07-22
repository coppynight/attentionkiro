import Foundation
import CoreData

extension UserSettings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettings> {
        return NSFetchRequest<UserSettings>(entityName: "UserSettings")
    }

    @NSManaged public var dailyFocusGoal: Double
    @NSManaged public var lunchBreakEnabled: Bool
    @NSManaged public var lunchBreakEnd: Date?
    @NSManaged public var lunchBreakStart: Date?
    @NSManaged public var notificationsEnabled: Bool
    @NSManaged public var sleepEndTime: Date
    @NSManaged public var sleepStartTime: Date

}