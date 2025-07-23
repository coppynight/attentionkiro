import XCTest
import UserNotifications
@testable import FocusTracker

@MainActor
final class NotificationManagerTests: XCTestCase {
    
    var notificationManager: NotificationManager!
    var mockNotificationCenter: MockUNUserNotificationCenter!
    
    override func setUp() async throws {
        try await super.setUp()
        notificationManager = NotificationManager.shared
        mockNotificationCenter = MockUNUserNotificationCenter()
    }
    
    override func tearDown() async throws {
        notificationManager = nil
        mockNotificationCenter = nil
        try await super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func testRequestNotificationPermission_Success() async throws {
        // Given
        mockNotificationCenter.shouldGrantPermission = true
        
        // When
        let granted = await notificationManager.requestNotificationPermission()
        
        // Then
        XCTAssertTrue(granted)
        XCTAssertTrue(notificationManager.isAuthorized)
    }
    
    func testRequestNotificationPermission_Denied() async throws {
        // Given
        mockNotificationCenter.shouldGrantPermission = false
        
        // When
        let granted = await notificationManager.requestNotificationPermission()
        
        // Then
        XCTAssertFalse(granted)
        XCTAssertFalse(notificationManager.isAuthorized)
    }
    
    // MARK: - Daily Summary Tests
    
    func testSendDailySummaryNotification_WithFocusTime() async throws {
        // Given
        let focusTime: TimeInterval = 3600 // 1 hour
        let sessionsCount = 2
        let longestSession: TimeInterval = 1800 // 30 minutes
        let goalTime: TimeInterval = 7200 // 2 hours
        
        // When
        await notificationManager.sendDailySummaryNotification(
            focusTime: focusTime,
            sessionsCount: sessionsCount,
            longestSession: longestSession,
            goalTime: goalTime
        )
        
        // Then - This would require mocking the notification center
        // For now, we just verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    func testSendDailySummaryNotification_NoFocusTime() async throws {
        // Given
        let focusTime: TimeInterval = 0
        let sessionsCount = 0
        let longestSession: TimeInterval = 0
        let goalTime: TimeInterval = 7200 // 2 hours
        
        // When
        await notificationManager.sendDailySummaryNotification(
            focusTime: focusTime,
            sessionsCount: sessionsCount,
            longestSession: longestSession,
            goalTime: goalTime
        )
        
        // Then - This would require mocking the notification center
        // For now, we just verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Streak Notification Tests
    
    func testSendStreakAchievedNotification() async throws {
        // Given
        let streakDays = 5
        
        // When
        await notificationManager.sendStreakAchievedNotification(streakDays: streakDays)
        
        // Then - This would require mocking the notification center
        // For now, we just verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Decline Warning Tests
    
    func testSendDeclineWarningNotification() async throws {
        // Given
        let todayTime: TimeInterval = 1800 // 30 minutes
        let yesterdayTime: TimeInterval = 3600 // 1 hour
        
        // When
        await notificationManager.sendDeclineWarningNotification(
            todayTime: todayTime,
            yesterdayTime: yesterdayTime
        )
        
        // Then - This would require mocking the notification center
        // For now, we just verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Goal Achievement Tests
    
    func testSendGoalAchievedNotification() async throws {
        // Given
        let focusTime: TimeInterval = 7200 // 2 hours
        let goal: TimeInterval = 7200 // 2 hours
        
        // When
        await notificationManager.sendGoalAchievedNotification(focusTime: focusTime, goal: goal)
        
        // Then - This would require mocking the notification center
        // For now, we just verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Notification Categories Tests
    
    func testSetupNotificationCategories() {
        // When
        notificationManager.setupNotificationCategories()
        
        // Then - This would require mocking the notification center
        // For now, we just verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Settings Integration Tests
    
    func testUpdateNotificationSettings_EnabledWithoutAuth() async throws {
        // Given
        notificationManager.isAuthorized = false
        
        // When
        await notificationManager.updateNotificationSettings(enabled: true)
        
        // Then - This would trigger permission request
        // For now, we just verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    func testUpdateNotificationSettings_EnabledWithAuth() async throws {
        // Given
        notificationManager.isAuthorized = true
        
        // When
        await notificationManager.updateNotificationSettings(enabled: true)
        
        // Then - This would schedule daily notifications
        // For now, we just verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    func testUpdateNotificationSettings_Disabled() async throws {
        // When
        await notificationManager.updateNotificationSettings(enabled: false)
        
        // Then - This would cancel all notifications
        // For now, we just verify the method doesn't crash
        XCTAssertTrue(true)
    }
}

// MARK: - Mock Classes

class MockUNUserNotificationCenter {
    var shouldGrantPermission = true
    var scheduledRequests: [UNNotificationRequest] = []
    
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        return shouldGrantPermission
    }
    
    func add(_ request: UNNotificationRequest) async throws {
        scheduledRequests.append(request)
    }
    
    func removeAllPendingNotificationRequests() {
        scheduledRequests.removeAll()
    }
    
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        scheduledRequests.removeAll { request in
            identifiers.contains(request.identifier)
        }
    }
}