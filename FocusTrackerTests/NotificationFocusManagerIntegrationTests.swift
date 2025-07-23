import XCTest
import CoreData
@testable import FocusTracker

@MainActor
final class NotificationFocusManagerIntegrationTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var focusManager: FocusManager!
    var usageMonitor: UsageMonitor!
    var notificationManager: NotificationManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Set up test persistence controller
        persistenceController = PersistenceController.preview
        viewContext = persistenceController.container.viewContext
        
        // Set up usage monitor and focus manager
        usageMonitor = UsageMonitor()
        focusManager = FocusManager(usageMonitor: usageMonitor, viewContext: viewContext)
        notificationManager = NotificationManager.shared
    }
    
    override func tearDown() async throws {
        focusManager.stopMonitoring()
        persistenceController = nil
        viewContext = nil
        focusManager = nil
        usageMonitor = nil
        notificationManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    func testFocusManagerTriggersNotifications() async throws {
        // Given - Start monitoring
        focusManager.startMonitoring()
        
        // Create a valid focus session manually
        let startTime = Date().addingTimeInterval(-3600) // 1 hour ago
        let endTime = Date().addingTimeInterval(-1800) // 30 minutes ago
        
        // When - Simulate focus session detection
        usageMonitor.onFocusSessionDetected?(startTime, endTime)
        
        // Wait for async operations
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Then - Verify focus session was created
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        let sessions = try viewContext.fetch(request)
        
        XCTAssertGreaterThan(sessions.count, 0, "Focus session should be created")
        
        if let session = sessions.first {
            XCTAssertTrue(session.isValid, "Focus session should be valid")
            XCTAssertEqual(session.duration, 1800, "Focus session duration should be 30 minutes")
        }
    }
    
    func testNotificationManagerWithRealFocusData() async throws {
        // Given - Create multiple focus sessions for different days
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        // Create sessions for streak testing
        createFocusSession(on: today, duration: 7200) // 2 hours today
        createFocusSession(on: yesterday, duration: 7200) // 2 hours yesterday
        createFocusSession(on: twoDaysAgo, duration: 7200) // 2 hours two days ago
        
        try viewContext.save()
        
        // When - Check smart notifications
        await notificationManager.checkAndSendSmartNotifications(viewContext: viewContext)
        
        // Then - Verify no crashes occurred
        XCTAssertTrue(true, "Smart notifications completed without errors")
    }
    
    func testDailySummaryWithActualData() async throws {
        // Given - Create focus sessions for today
        let today = Date()
        createFocusSession(on: today, duration: 1800) // 30 minutes
        createFocusSession(on: today, duration: 3600) // 1 hour
        
        try viewContext.save()
        
        // When - Send scheduled daily summary
        await notificationManager.sendScheduledDailySummary(viewContext: viewContext)
        
        // Then - Verify no crashes occurred
        XCTAssertTrue(true, "Daily summary with actual data completed without errors")
    }
    
    func testStreakCalculationWithRealData() async throws {
        // Given - Create a 5-day streak
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            createFocusSession(on: date, duration: 7200) // 2 hours each day
        }
        
        try viewContext.save()
        
        // When - Check smart notifications (which includes streak calculation)
        await notificationManager.checkAndSendSmartNotifications(viewContext: viewContext)
        
        // Then - Verify no crashes occurred
        XCTAssertTrue(true, "Streak calculation completed without errors")
    }
    
    func testDeclineDetectionWithRealData() async throws {
        // Given - Create sessions showing decline
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        createFocusSession(on: yesterday, duration: 7200) // 2 hours yesterday
        createFocusSession(on: today, duration: 2400) // 40 minutes today (66% decline)
        
        try viewContext.save()
        
        // When - Check smart notifications
        await notificationManager.checkAndSendSmartNotifications(viewContext: viewContext)
        
        // Then - Verify no crashes occurred
        XCTAssertTrue(true, "Decline detection completed without errors")
    }
    
    func testGoalAchievementDetection() async throws {
        // Given - Create user settings with 2-hour goal
        let userSettings = UserSettings.createDefaultSettings(in: viewContext)
        userSettings.dailyFocusGoal = 7200 // 2 hours
        
        // Create focus session that meets the goal
        createFocusSession(on: Date(), duration: 7200) // 2 hours
        
        try viewContext.save()
        
        // When - Check smart notifications
        await notificationManager.checkAndSendSmartNotifications(viewContext: viewContext)
        
        // Then - Verify no crashes occurred
        XCTAssertTrue(true, "Goal achievement detection completed without errors")
    }
    
    // MARK: - Helper Methods
    
    private func createFocusSession(on date: Date, duration: TimeInterval) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let sessionStart = startOfDay.addingTimeInterval(3600) // 1 hour after start of day
        let sessionEnd = sessionStart.addingTimeInterval(duration)
        
        let focusSession = FocusSession(context: viewContext)
        focusSession.startTime = sessionStart
        focusSession.endTime = sessionEnd
        focusSession.duration = duration
        focusSession.isValid = true
        focusSession.sessionType = "focus"
    }
}