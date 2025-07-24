import Foundation
import CoreData

// This is a temporary test file to verify the data model works
// It should be removed after the new Core Data entities are properly added to the Xcode project

class DataModelTest {
    static func testNewEntities() {
        let container = NSPersistentContainer(name: "FocusDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Failed to load store: \(error)")
                return
            }
            
            let context = container.viewContext
            
            // Test creating SceneTag
            let tag = NSEntityDescription.entity(forEntityName: "SceneTag", in: context)!
            let sceneTag = NSManagedObject(entity: tag, insertInto: context)
            sceneTag.setValue(UUID().uuidString, forKey: "tagID")
            sceneTag.setValue("工作", forKey: "name")
            sceneTag.setValue("#007AFF", forKey: "color")
            sceneTag.setValue(true, forKey: "isDefault")
            sceneTag.setValue(Date(), forKey: "createdAt")
            sceneTag.setValue(0, forKey: "usageCount")
            
            // Test creating AppUsageSession
            let session = NSEntityDescription.entity(forEntityName: "AppUsageSession", in: context)!
            let appSession = NSManagedObject(entity: session, insertInto: context)
            appSession.setValue("com.apple.mobilesafari", forKey: "appIdentifier")
            appSession.setValue("Safari", forKey: "appName")
            appSession.setValue("productivity", forKey: "categoryIdentifier")
            appSession.setValue(Date(), forKey: "startTime")
            appSession.setValue(0.0, forKey: "duration")
            appSession.setValue(0, forKey: "interruptionCount")
            appSession.setValue(false, forKey: "isProductiveTime")
            appSession.setValue("工作", forKey: "sceneTag")
            
            do {
                try context.save()
                print("Successfully created test entities")
            } catch {
                print("Failed to save test entities: \(error)")
            }
        }
    }
}