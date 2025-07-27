import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create default tags
        TimeTag.createDefaultTags(in: viewContext)
        
        // Add sample time blocks for previews
        let calendar = Calendar.current
        let now = Date()
        
        // Create sample time blocks for today
        for hour in 9...17 {
            if let startTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now),
               let endTime = calendar.date(bySettingHour: hour, minute: 30, second: 0, of: now) {
                
                let timeBlock = TimeBlock.create(
                    in: viewContext,
                    startTime: startTime,
                    endTime: endTime,
                    activity: hour % 2 == 0 ? "工作任务" : nil,
                    category: hour % 2 == 0 ? "工作" : nil
                )
                
                // Add a commit for some blocks
                if hour % 3 == 0 {
                    let focusIntensity = Double.random(in: 0.3...0.9)
                    let interruptions = Int32.random(in: 0...3)
                    let isBeautiful = hour == 15 // Mark 3 PM as a beautiful moment
                    
                    _ = timeBlock.addCommit(
                        message: isBeautiful ? "完成了重要的项目里程碑 ✨" : "专注工作中",
                        focusIntensity: focusIntensity,
                        interruptionCount: interruptions,
                        isBeautifulMoment: isBeautiful
                    )
                }
                
                // Add tags to some blocks
                if hour % 2 == 0 {
                    let workTag = TimeTag.fetchDefaultTags(in: viewContext).first { $0.name == "工作" }
                    if let workTag = workTag {
                        timeBlock.addTag(workTag)
                    }
                }
            }
        }
        
        // Create user settings
        _ = UserSettings.getOrCreate(in: viewContext)
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TimelogDataModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Initialize default data on first launch
        initializeDefaultDataIfNeeded()
    }
    
    // MARK: - Data Management
    
    /// Save the view context
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Failed to save context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    /// Initialize default data if this is the first launch
    private func initializeDefaultDataIfNeeded() {
        let context = container.viewContext
        
        // Check if default tags already exist
        let tagRequest: NSFetchRequest<TimeTag> = TimeTag.fetchRequest()
        tagRequest.predicate = NSPredicate(format: "isDefault == YES")
        
        do {
            let existingDefaultTags = try context.fetch(tagRequest)
            if existingDefaultTags.isEmpty {
                // Create default tags
                TimeTag.createDefaultTags(in: context)
                
                // Create default user settings
                _ = UserSettings.getOrCreate(in: context)
                
                // Save the context
                try context.save()
                print("Default data initialized successfully")
            }
        } catch {
            print("Failed to initialize default data: \(error)")
        }
    }
    
    /// Clear all data (for testing or reset purposes)
    func clearAllData() {
        let context = container.viewContext
        
        // Delete all entities
        let entityNames = ["TimeCommit", "TimeTag", "TimeBlock", "UserSettings"]
        
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                print("Failed to delete \(entityName): \(error)")
            }
        }
        
        // Save context
        save()
        
        // Reinitialize default data
        initializeDefaultDataIfNeeded()
    }
}