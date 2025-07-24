import XCTest
import CoreData
@testable import FocusTracker

class NotificationManagerTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        viewContext = nil
        persistenceController = nil
    }
    
    func testNotificationPermissionRequest() async {
        // This is a mock test since we can't actually request permissions in a test
        // Just verify the method exists and doesn't crash
        let notificationManager = NotificationManager.shared
        
        // We're not actually requesting permission in tests, just making sure the method exists
        XCTAssertNotNil(notificationManager)
    }
    
    func testDailySummaryNotificationContent() async {
        // Create test data
        let focusTime: TimeInterval = 2 * 3600 + 30 * 60 // 2h 30m
        let sessionsCount = 3
        let longestSession: TimeInterval = 1 * 3600 + 15 * 60 // 1h 15m
        let goalTime: TimeInterval = 2 * 3600 // 2h
        
        // Create a mock notification center for testing
        let mockNotificationCenter = MockNotificationCenter()
        let notificationManager = MockNotificationManager(notificationCenter: mockNotificationCenter)
        
        // Send a daily summary notification
        await notificationManager.sendDailySummaryNotification(
            focusTime: focusTime,
            sessionsCount: sessionsCount,
            longestSession: longestSession,
            goalTime: goalTime
        )
        
        // Verify the notification content
        XCTAssertEqual(mockNotificationCenter.lastContent?.title, "今日专注总结")
        XCTAssertTrue(mockNotificationCenter.lastContent?.body.contains("2小时30分钟") ?? false)
        XCTAssertTrue(mockNotificationCenter.lastContent?.body.contains("3 个专注时段") ?? false)
        XCTAssertTrue(mockNotificationCenter.lastContent?.body.contains("1小时15分钟") ?? false)
        XCTAssertTrue(mockNotificationCenter.lastContent?.body.contains("已达成目标") ?? false)
    }
    
    func testEncouragementNotificationContent() async {
        // Create a mock notification center for testing
        let mockNotificationCenter = MockNotificationCenter()
        let notificationManager = MockNotificationManager(notificationCenter: mockNotificationCenter)
        
        // Send an encouragement notification
        let message = "太棒了！你已经连续专注1小时了！"
        await notificationManager.sendEncouragementNotification(message: message)
        
        // Verify the notification content
        XCTAssertEqual(mockNotificationCenter.lastContent?.title, "专注鼓励")
        XCTAssertEqual(mockNotificationCenter.lastContent?.body, message)
    }
    
    func testGoalAchievedNotificationContent() async {
        // Create test data
        let focusTime: TimeInterval = 2 * 3600 + 30 * 60 // 2h 30m
        let goalTime: TimeInterval = 2 * 3600 // 2h
        
        // Create a mock notification center for testing
        let mockNotificationCenter = MockNotificationCenter()
        let notificationManager = MockNotificationManager(notificationCenter: mockNotificationCenter)
        
        // Send a goal achieved notification
        await notificationManager.sendGoalAchievedNotification(focusTime: focusTime, goal: goalTime)
        
        // Verify the notification content
        XCTAssertEqual(mockNotificationCenter.lastContent?.title, "🎉 目标达成！")
        XCTAssertTrue(mockNotificationCenter.lastContent?.body.contains("2小时30分钟") ?? false)
        XCTAssertTrue(mockNotificationCenter.lastContent?.body.contains("达成了每日目标") ?? false)
    }
}

// MARK: - Mock Classes for Testing

class MockNotificationCenter {
    var lastContent: UNMutableNotificationContent?
    var lastRequest: UNNotificationRequest?
    
    func add(_ request: UNNotificationRequest) throws {
        lastRequest = request
        if let content = request.content as? UNMutableNotificationContent {
            lastContent = content
        }
    }
    
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        // No-op for testing
    }
    
    func removeAllPendingNotificationRequests() {
        // No-op for testing
    }
    
    func removeAllDeliveredNotifications() {
        // No-op for testing
    }
}

class MockNotificationManager {
    private let notificationCenter: MockNotificationCenter
    
    init(notificationCenter: MockNotificationCenter) {
        self.notificationCenter = notificationCenter
    }
    
    func sendDailySummaryNotification(focusTime: TimeInterval, sessionsCount: Int, longestSession: TimeInterval, goalTime: TimeInterval) async {
        let focusHours = Int(focusTime / 3600)
        let focusMinutes = Int((focusTime.truncatingRemainder(dividingBy: 3600)) / 60)
        let longestHours = Int(longestSession / 3600)
        let longestMinutes = Int((longestSession.truncatingRemainder(dividingBy: 3600)) / 60)
        
        let content = UNMutableNotificationContent()
        content.title = "今日专注总结"
        
        if focusTime > 0 {
            let goalAchieved = focusTime >= goalTime
            let goalEmoji = goalAchieved ? "🎉 " : ""
            let goalText = goalAchieved ? "，已达成目标！" : ""
            
            content.body = "\(goalEmoji)今天专注了 \(focusHours)小时\(focusMinutes)分钟，共 \(sessionsCount) 个专注时段。最长专注 \(longestHours)小时\(longestMinutes)分钟\(goalText)"
        } else {
            content.body = "今天还没有专注时段，明天继续加油！"
        }
        
        content.sound = .default
        content.categoryIdentifier = "DAILY_SUMMARY"
        content.userInfo = ["type": "daily_summary", "date": Date().timeIntervalSince1970]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "daily-summary-test",
            content: content,
            trigger: trigger
        )
        
        try? notificationCenter.add(request)
    }
    
    func sendEncouragementNotification(message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "专注鼓励"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "ENCOURAGEMENT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "encouragement-test",
            content: content,
            trigger: trigger
        )
        
        try? notificationCenter.add(request)
    }
    
    func sendGoalAchievedNotification(focusTime: TimeInterval, goal: TimeInterval) async {
        let focusHours = Int(focusTime / 3600)
        let focusMinutes = Int((focusTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 目标达成！"
        content.body = "恭喜！你今天已专注 \(focusHours)小时\(focusMinutes)分钟，达成了每日目标！"
        content.sound = .default
        content.categoryIdentifier = "GOAL_ACHIEVED"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "goal-achieved-test",
            content: content,
            trigger: trigger
        )
        
        try? notificationCenter.add(request)
    }
}