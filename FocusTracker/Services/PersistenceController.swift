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
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
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
                        container?.loadPersistentStores { _, error in
                            if let error = error {
                                fatalError("Failed to recreate Core Data store: \(error)")
                            }
                        }
                    } catch {
                        fatalError("Failed to remove old Core Data store: \(error)")
                    }
                } else {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}