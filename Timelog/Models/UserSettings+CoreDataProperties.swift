import Foundation
import CoreData

extension UserSettings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettings> {
        return NSFetchRequest<UserSettings>(entityName: "UserSettings")
    }

    @NSManaged public var autoTaggingEnabled: Bool
    @NSManaged public var dailyGoalHours: Double
    @NSManaged public var enableBeautifulMoments: Bool
    @NSManaged public var heatmapColorScheme: String?
    @NSManaged public var timeBlockGranularity: Double
    @NSManaged public var weeklyReviewEnabled: Bool
    @NSManaged public var workingHoursEnd: Date?
    @NSManaged public var workingHoursStart: Date?

}