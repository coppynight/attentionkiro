import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 创建一些示例数据用于预览
        let sampleSession = FocusSession(context: viewContext)
        sampleSession.startTime = Date().addingTimeInterval(-3600) // 1小时前
        sampleSession.endTime = Date()
        sampleSession.duration = 3600 // 1小时
        sampleSession.isValid = true
        sampleSession.sessionType = "focus"
        
        // 创建默认场景标签
        let defaultTags = SceneTag.createDefaultTags(in: viewContext)
        
        // 创建示例应用使用会话
        let sampleAppSession = AppUsageSession(context: viewContext)
        sampleAppSession.appIdentifier = "com.apple.mobilesafari"
        sampleAppSession.appName = "Safari"
        sampleAppSession.categoryIdentifier = "Productivity"
        sampleAppSession.startTime = Date().addingTimeInterval(-1800) // 30分钟前
        sampleAppSession.endTime = Date().addingTimeInterval(-600) // 10分钟前结束
        sampleAppSession.duration = 1200 // 20分钟
        sampleAppSession.sceneTag = "工作"
        sampleAppSession.isProductiveTime = true
        sampleAppSession.interruptionCount = 1
        
        // 创建用户设置
        let settings = UserSettings.createDefaultSettings(in: viewContext)
        
        do {
            try viewContext.save()
        } catch {
            // 在预览中替换这个实现，以便在出现错误时处理错误
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FocusDataModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // 启用轻量级迁移
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.shouldMigrateStoreAutomatically = true
            storeDescription.shouldInferMappingModelAutomatically = true
        }
        
        container.loadPersistentStores(completionHandler: { [weak container] (storeDescription, error) in
            if let error = error as NSError? {
                // 如果迁移失败，尝试删除旧的存储并重新创建
                print("Core Data error: \(error), \(error.userInfo)")
                
                // 在开发阶段，可以删除旧数据重新开始
                if let storeURL = storeDescription.url {
                    do {
                        try FileManager.default.removeItem(at: storeURL)
                        print("Removed old Core Data store, will recreate")
                        
                        // 重新尝试加载存储
                        container?.loadPersistentStores { _, recreateError in
                            if let recreateError = recreateError {
                                print("Failed to recreate Core Data store: \(recreateError)")
                                // 在生产环境中，应该有更优雅的错误处理
                                // 这里暂时使用fatalError，但应该考虑其他恢复策略
                                fatalError("Failed to recreate Core Data store: \(recreateError)")
                            }
                        }
                    } catch {
                        print("Failed to remove old Core Data store: \(error)")
                        // 在生产环境中，应该有更优雅的错误处理
                        fatalError("Failed to remove old Core Data store: \(error)")
                    }
                } else {
                    print("Unresolved Core Data error without store URL: \(error), \(error.userInfo)")
                    // 在生产环境中，应该有更优雅的错误处理
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Initialize default data if needed
        initializeDefaultDataIfNeeded()
    }
    
    // MARK: - Helper Methods
    
    /// Initializes default data (tags, settings) if they don't exist
    private func initializeDefaultDataIfNeeded() {
        let context = container.viewContext
        
        // Check if default tags exist
        let tagRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        tagRequest.predicate = NSPredicate(format: "isDefault == YES")
        
        do {
            let existingDefaultTags = try context.fetch(tagRequest)
            if existingDefaultTags.isEmpty {
                // Create default tags
                let _ = SceneTag.createDefaultTags(in: context)
                try context.save()
            }
        } catch {
            print("Failed to initialize default tags: \(error)")
        }
        
        // Check if user settings exist
        let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let existingSettings = try context.fetch(settingsRequest)
            if existingSettings.isEmpty {
                // Create default settings
                let _ = UserSettings.createDefaultSettings(in: context)
                try context.save()
            }
        } catch {
            print("Failed to initialize default settings: \(error)")
        }
    }
    
    /// Saves the context if there are changes
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
    
    // MARK: - AppUsageSession Methods
    
    /// Creates and saves an AppUsageSession
    func saveAppUsageSession(from appUsageData: AppUsageData, sceneTag: String? = nil) {
        let context = container.viewContext
        
        // Check for duplicate sessions to prevent data corruption
        if isDuplicateAppUsageSession(appUsageData: appUsageData, in: context) {
            print("PersistenceController: Skipping duplicate app usage session")
            return
        }
        
        let session = AppUsageSession(context: context)
        session.appIdentifier = appUsageData.appIdentifier
        session.appName = appUsageData.appName
        session.categoryIdentifier = appUsageData.categoryIdentifier
        session.startTime = appUsageData.startTime
        session.endTime = appUsageData.endTime
        session.duration = appUsageData.duration
        session.interruptionCount = Int16(appUsageData.interruptionCount)
        session.sceneTag = sceneTag
        session.isProductiveTime = determineProductivity(for: appUsageData.categoryIdentifier)
        
        save()
        print("PersistenceController: Saved app usage session for \(appUsageData.appName)")
    }
    
    /// Fetches app usage sessions for a specific date
    func fetchAppUsageSessions(for date: Date) -> [AppUsageSession] {
        let context = container.viewContext
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AppUsageSession.startTime, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch app usage sessions: \(error)")
            return []
        }
    }
    
    /// Fetches app usage sessions within a date range
    func fetchAppUsageSessions(from startDate: Date, to endDate: Date) -> [AppUsageSession] {
        let context = container.viewContext
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AppUsageSession.startTime, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch app usage sessions in range: \(error)")
            return []
        }
    }
    
    /// Checks if an app usage session is a duplicate
    private func isDuplicateAppUsageSession(appUsageData: AppUsageData, in context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        
        // Check for sessions with the same app and overlapping time
        let buffer: TimeInterval = 5 // 5 second buffer
        let startBuffer = appUsageData.startTime.addingTimeInterval(-buffer)
        let endBuffer = appUsageData.endTime.addingTimeInterval(buffer)
        
        request.predicate = NSPredicate(format: "appIdentifier == %@ AND startTime >= %@ AND endTime <= %@", 
                                      appUsageData.appIdentifier, 
                                      startBuffer as NSDate, 
                                      endBuffer as NSDate)
        request.fetchLimit = 1
        
        do {
            let existingSessions = try context.fetch(request)
            return !existingSessions.isEmpty
        } catch {
            print("Failed to check for duplicate sessions: \(error)")
            return false
        }
    }
    
    /// Determines if an app category is considered productive
    private func determineProductivity(for categoryIdentifier: String) -> Bool {
        let productiveCategories = ["Productivity", "Education", "Business", "Developer Tools", "Reference"]
        return productiveCategories.contains(categoryIdentifier)
    }
    
    // MARK: - SceneTag Methods
    
    /// Fetches all scene tags
    func fetchAllSceneTags() -> [SceneTag] {
        let context = container.viewContext
        let request: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \SceneTag.isDefault, ascending: false),
            NSSortDescriptor(keyPath: \SceneTag.name, ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch scene tags: \(error)")
            return []
        }
    }
    
    /// Fetches default scene tags
    func fetchDefaultSceneTags() -> [SceneTag] {
        let context = container.viewContext
        let request: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SceneTag.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch default scene tags: \(error)")
            return []
        }
    }
    
    /// Creates a custom scene tag
    func createCustomSceneTag(name: String, color: String) -> SceneTag? {
        let context = container.viewContext
        
        // Check if tag with same name already exists
        let request: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let existingTags = try context.fetch(request)
            if !existingTags.isEmpty {
                print("PersistenceController: Tag with name '\(name)' already exists")
                return nil
            }
        } catch {
            print("Failed to check for existing tag: \(error)")
            return nil
        }
        
        // Create new tag
        let tag = SceneTag(context: context)
        tag.tagID = UUID().uuidString
        tag.name = name
        tag.color = color
        tag.isDefault = false
        tag.createdAt = Date()
        tag.usageCount = 0
        tag.associatedApps = ""
        
        save()
        print("PersistenceController: Created custom scene tag '\(name)'")
        return tag
    }
    
    /// Updates scene tag usage count
    func updateSceneTagUsage(tagName: String) {
        let context = container.viewContext
        let request: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", tagName)
        
        do {
            let tags = try context.fetch(request)
            if let tag = tags.first {
                tag.usageCount += 1
                save()
            }
        } catch {
            print("Failed to update scene tag usage: \(error)")
        }
    }
    
    /// Associates an app with a scene tag
    func associateApp(_ appIdentifier: String, withTag tagName: String) {
        let context = container.viewContext
        let request: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", tagName)
        
        do {
            let tags = try context.fetch(request)
            if let tag = tags.first {
                let currentApps = tag.associatedApps ?? ""
                let appsArray = currentApps.isEmpty ? [] : currentApps.components(separatedBy: ",")
                
                if !appsArray.contains(appIdentifier) {
                    let updatedApps = appsArray + [appIdentifier]
                    tag.associatedApps = updatedApps.joined(separator: ",")
                    save()
                }
            }
        } catch {
            print("Failed to associate app with tag: \(error)")
        }
    }
    
    // MARK: - Data Integrity Methods
    
    /// Performs data integrity checks and cleanup
    func performDataIntegrityCheck() {
        let context = container.viewContext
        
        // Check for orphaned app usage sessions (sessions without valid time ranges)
        cleanupInvalidAppUsageSessions(in: context)
        
        // Check for duplicate focus sessions
        cleanupDuplicateFocusSessions(in: context)
        
        // Validate user settings
        validateUserSettings(in: context)
        
        save()
    }
    
    private func cleanupInvalidAppUsageSessions(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        
        do {
            let sessions = try context.fetch(request)
            var deletedCount = 0
            
            for session in sessions {
                // Remove sessions with invalid duration or time ranges
                if session.duration <= 0 || (session.endTime != nil && session.endTime! <= session.startTime) {
                    context.delete(session)
                    deletedCount += 1
                }
            }
            
            if deletedCount > 0 {
                print("PersistenceController: Cleaned up \(deletedCount) invalid app usage sessions")
            }
        } catch {
            print("Failed to cleanup invalid app usage sessions: \(error)")
        }
    }
    
    private func cleanupDuplicateFocusSessions(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.startTime, ascending: true)]
        
        do {
            let sessions = try context.fetch(request)
            var deletedCount = 0
            var previousSession: FocusSession?
            
            for session in sessions {
                if let prev = previousSession {
                    // Check for overlapping sessions (within 1 minute)
                    let timeDifference = abs(session.startTime.timeIntervalSince(prev.startTime))
                    if timeDifference < 60 {
                        // Keep the longer session
                        if session.duration > prev.duration {
                            context.delete(prev)
                        } else {
                            context.delete(session)
                            continue
                        }
                        deletedCount += 1
                    }
                }
                previousSession = session
            }
            
            if deletedCount > 0 {
                print("PersistenceController: Cleaned up \(deletedCount) duplicate focus sessions")
            }
        } catch {
            print("Failed to cleanup duplicate focus sessions: \(error)")
        }
    }
    
    private func validateUserSettings(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try context.fetch(request)
            
            // Ensure only one UserSettings instance exists
            if settings.count > 1 {
                // Keep the first one, delete the rest
                for i in 1..<settings.count {
                    context.delete(settings[i])
                }
                print("PersistenceController: Cleaned up duplicate user settings")
            } else if settings.isEmpty {
                // Create default settings if none exist
                let _ = UserSettings.createDefaultSettings(in: context)
                print("PersistenceController: Created missing user settings")
            }
        } catch {
            print("Failed to validate user settings: \(error)")
        }
    }
}