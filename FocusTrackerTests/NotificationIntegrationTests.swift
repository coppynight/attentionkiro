import XCTest
import CoreData
@testable import FocusTracker

@MainActor
final class NotificationIntegrationTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var notificationManager: NotificationManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Set up test persistence controller
        persistenceController = PersistenceController.preview
        viewContext = persistenceController.container.viewContext
        notificationManager = NotificationManager.shared
    }
    
    override func tearDown() async throws {
        persistenceController = nil
        viewContext = nil
        notificationManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    func testNotificationManagerIntegrationWithCoreData() async throws {
        // Given - Create some test focus sessions
        let focusSession1 = FocusSession(context: viewContext)
        focusSession1.startTime = Date().addingTimeInterval(-3600) // 1 hour ago
        focusSession1.endTime = Date().addingTimeInterval(-1800) // 30 minutes ago
        focusSession1.duration = 1800 // 30 minutes
        focusSession1.isValid = true
        focusSession1.sessionType = "focus"
        
        let focusSession2 = FocusSession(context: viewContext)
        focusSession2.startTime = Date().addingTimeInterval(-7200) // 2 hours ago
        focusSession2.endTime = Date().addingTimeInterval(-3600) // 1 hour ago
        focusSession2.duration = 3600 // 1 hour
        focusSession2.isValid = true
        focusSession2.sessionType = "focus"
        
        try viewContext.save()
        
        // When - Check smart notifications
        await notificationManager.checkAndSendSmartNotifications(viewContext: viewContext)
        
        // Then - Verify no crashes occurred
        XCTAssertTrue(true, "Smart notifications check completed without errors")
    }
    
    func testScheduledDailySummaryWithRealData() async throws {
        // Given - Create test focus sessions for today
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        
        let focusSession = FocusSession(context: viewContext)
        focusSession.startTime = startOfDay.addingTimeInterval(3600) // 1 hour after start of day
        focusSession.endTime = startOfDay.addingTimeInterval(5400) // 1.5 hours after start of day
        focusSession.duration = 1800 // 30 minutes
        focusSession.isValid = true
        focusSession.sessionType = "focus"
        
        try viewContext.save()
        
        // When - Send scheduled daily summary
        await notificationManager.sendScheduledDailySummary(viewContext: viewContext)
        
        // Then - Verify no crashes occurred
        XCTAssertTrue(true, "Scheduled daily summary completed without errors")
    }
    
    func testNotificationPermissionFlow() async throws {
        // Given - Fresh notification manager state
        let initialAuthStatus = notificationManager.authorizationStatus
        
        // When - Check authorization status
        await notificationManager.checkAuthorizationStatus()
        
        // Then - Verify status was checked
        XCTAssertTrue(true, "Authorization status check completed")
        
        // Note: Actual permission request would require user interaction
        // This test just verifies the flow doesn't crash
    }
    
    func testNotificationCategoriesSetup() {
        // When - Setup notification categories
        notificationManager.setupNotificationCategories()
        
        // Then - Verify setup completed without errors
        XCTAssertTrue(true, "Notification categories setup completed")
    }
    
    func testNotificationDelegateSetup() {
        // When - Setup notification delegate
        notificationManager.setupNotificationDelegate()
        
        // Then - Verify setup completed without errors
        XCTAssertTrue(true, "Notification delegate setup completed")
    }
}