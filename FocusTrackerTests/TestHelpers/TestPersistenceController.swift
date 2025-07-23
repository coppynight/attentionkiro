import Foundation
import CoreData
@testable import FocusTracker

// 简化的测试用持久化控制器
class TestPersistenceController {
    static let shared = TestPersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        // 使用内存中的存储进行测试
        container = NSPersistentContainer(name: "FocusDataModel")
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("测试持久化存储加载失败: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}