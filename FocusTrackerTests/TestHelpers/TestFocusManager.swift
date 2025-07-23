import Foundation
import CoreData
@testable import FocusTracker

// 简化的测试用专注管理器
class TestFocusManager {
    var isMonitoring = false
    var currentSession: FocusSession?
    var todaysFocusTime: TimeInterval = 0
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func startMonitoring() {
        isMonitoring = true
    }
    
    func stopMonitoring() {
        isMonitoring = false
    }
}