import XCTest
import CoreData
@testable import FocusTracker

class FocusManagerTests: XCTestCase {
    
    var viewContext: NSManagedObjectContext!
    var usageMonitor: UsageMonitor!
    var focusManager: FocusManager!
    
    override func setUpWithError() throws {
        // 使用内存中的Core Data存储进行测试
        let container = NSPersistentContainer(name: "FocusDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                XCTFail("Failed to load store: \(error)")
            }
        }
        
        viewContext = container.viewContext
        usageMonitor = UsageMonitor()
        focusManager = FocusManager(usageMonitor: usageMonitor, viewContext: viewContext)
    }
    
    override func tearDownWithError() throws {
        viewContext = nil
        usageMonitor = nil
        focusManager = nil
    }
    
    func testAddFocusSession() throws {
        // 添加测试专注记录
        let testSession = FocusSession(context: viewContext)
        testSession.startTime = Date().addingTimeInterval(-45 * 60) // 45分钟前
        testSession.endTime = Date()
        testSession.duration = 45 * 60 // 45分钟
        testSession.isValid = true
        testSession.sessionType = "focus"
        
        try viewContext.save()
        focusManager.calculateTodaysFocusTime()
        
        // 验证记录已添加
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        let sessions = try viewContext.fetch(request)
        XCTAssertEqual(sessions.count, 1, "应该有一个专注记录")
        XCTAssertEqual(sessions.first?.duration, 45 * 60, "专注时长应为45分钟")
    }
    
    func testCoreFunctionality() throws {
        // 测试核心功能
        
        // 1. 测试添加有效的专注记录
        let validSession = FocusSession(context: viewContext)
        validSession.startTime = Date().addingTimeInterval(-60 * 60) // 1小时前
        validSession.endTime = Date()
        validSession.duration = 60 * 60 // 1小时
        validSession.isValid = true
        validSession.sessionType = "focus"
        
        try viewContext.save()
        
        // 2. 测试获取周趋势数据
        let weeklyTrend = focusManager.getWeeklyTrend()
        XCTAssertEqual(weeklyTrend.count, 7, "周趋势数据应包含7天")
        
        // 3. 测试获取今日统计数据
        let todayStats = focusManager.getFocusStatistics(for: Date())
        XCTAssertEqual(todayStats.sessionCount, 1, "今日应有1个有效专注记录")
        XCTAssertEqual(todayStats.totalFocusTime, 60 * 60, "今日总专注时间应为1小时")
    }
}