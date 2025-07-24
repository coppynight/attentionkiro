import Foundation
import CoreData

extension SceneTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SceneTag> {
        return NSFetchRequest<SceneTag>(entityName: "SceneTag")
    }

    @NSManaged public var associatedApps: String?
    @NSManaged public var color: String
    @NSManaged public var createdAt: Date
    @NSManaged public var isDefault: Bool
    @NSManaged public var name: String
    @NSManaged public var tagID: String
    @NSManaged public var usageCount: Int32

}