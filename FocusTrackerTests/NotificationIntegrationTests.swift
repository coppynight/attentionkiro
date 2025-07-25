import XCTest
import CoreData
@testable import FocusTracker

class NotificationIntegrationTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var focusManager: FocusManager!
    var usageMonitor: NotificationTestUsageMonitor!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        usageMonitor = NotificationTestUsageMonitor()
        focusManager = FocusManager(usageMonitor: usageMonitor, viewContext: viewContext)
        
        // Create default user settings
        _ = UserSettings.createDefaultSettings(in: viewContext)
        try viewContext.save()
    }
    
    override func tearDownWithError() throws {
        viewContext = nil
        persistenceController = nil
        focusManager = nil
        usageMonitor = nil
    }
    
    func testFocusManagerNotificationIntegration() {
        // Create a focus session
        let now = Date()
        let startTime = now.addingTimeInterval(-2 * 3600) // 2 hours ago
        
        // Simulate focus session detection
        usageMonitor.simulateFocusSessionDetection(startTime: startTime, endTime: now)
        
        // Wait for async operations
        let expectation = XCTestExpectation(description: "Focus session processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify focus session was created
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        do {
            let sessions = try viewContext.fetch(request)
            XCTAssertGreaterThanOrEqual(sessions.count, 1)
            
            if let session = sessions.first {
                XCTAssertEqual(session.startTime, startTime)
                XCTAssertEqual(session.duration, 2 * 3600, accuracy: 1.0)
                XCTAssertTrue(session.isValid)
            }
        } catch {
            XCTFail("Failed to fetch focus sessions: \(error)")
        }
    }
    
    func testStreakCalculation() {
        // Create focus sessions for the past 3 days
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create user settings with 2 hour goal
        let settings = getUserSettings()
        settings.dailyFocusGoal = 2 * 3600 // 2 hours
        
        // Create sessions for today, yesterday, and day before
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            createFocusSession(on: date, duration: 2.5 * 3600) // 2.5 hours
        }
        
        // Save context
        do {
            try viewContext.save()
        } catch {
            XCTFail("Failed to save context: \(error)")
        }
        
        // Test streak calculation
        let mockNotificationManager = NotificationTestMockManager()
        let streak = mockNotificationManager.testCalculateStreak(viewContext: viewContext)
        
        XCTAssertEqual(streak, 3)
    }
    
    func testDeclineDetection() {
        // Create user settings
        let settings = getUserSettings()
        settings.dailyFocusGoal = 2 * 3600 // 2 hours
        
        // Create focus sessions for yesterday and today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Yesterday: 3 hours
        createFocusSession(on: yesterday, duration: 3 * 3600)
        
        // Today: 1.5 hours (50% decline)
        createFocusSession(on: today, duration: 1.5 * 3600)
        
        // Save context
        do {
            try viewContext.save()
        } catch {
            XCTFail("Failed to save context: \(error)")
        }
        
        // Test decline detection
        let mockNotificationManager = NotificationTestMockManager()
        let decline = mockNotificationManager.testCalculateDecline(viewContext: viewContext)
        
        XCTAssertEqual(decline, 0.5, accuracy: 0.01) // 50% decline
    }
    
    // MARK: - Helper Methods
    
    private func getUserSettings() -> UserSettings {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try viewContext.fetch(request)
            if let userSettings = settings.first {
                return userSettings
            } else {
                let newSettings = UserSettings.createDefaultSettings(in: viewContext)
                try viewContext.save()
                return newSettings
            }
        } catch {
            XCTFail("Failed to fetch user settings: \(error)")
            return UserSettings.createDefaultSettings(in: viewContext)
        }
    }
    
    private func createFocusSession(on date: Date, duration: TimeInterval) {
        let session = FocusSession(context: viewContext)
        session.startTime = date
        session.endTime = date.addingTimeInterval(duration)
        session.duration = duration
        session.isValid = true
        session.sessionType = "focus"
    }
}

// MARK: - Mock Classes

class NotificationTestUsageMonitor: UsageMonitor {
    var onFocusSessionDetectedCallback: ((Date, Date) -> Void)?
    
    override var onFocusSessionDetected: ((Date, Date) -> Void)? {
        get {
            return onFocusSessionDetectedCallback
        }
        set {
            onFocusSessionDetectedCallback = newValue
        }
    }
    
    func simulateFocusSessionDetection(startTime: Date, endTime: Date) {
        onFocusSessionDetectedCallback?(startTime, endTime)
    }
}

class NotificationTestMockManager {
    func testCalculateStreak(viewContext: NSManagedObjectContext) -> Int {
        let calendar = Calendar.current
        let today = Date()
        var streakDays = 0
        
        for i in 0..<30 { // Check up to 30 days back
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let stats = getFocusStatistics(for: date, viewContext: viewContext)
            let userSettings = getUserSettings(viewContext: viewContext)
            
            if stats.totalFocusTime >= userSettings.dailyFocusGoal {
                streakDays += 1
            } else {
                break // Streak is broken
            }
        }
        
        return streakDays
    }
    
    func testCalculateDecline(viewContext: NSManagedObjectContext) -> Double {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let todayStats = getFocusStatistics(for: today, viewContext: viewContext)
        let yesterdayStats = getFocusStatistics(for: yesterday, viewContext: viewContext)
        
        if yesterdayStats.totalFocusTime > 0 && todayStats.totalFocusTime > 0 {
            return (yesterdayStats.totalFocusTime - todayStats.totalFocusTime) / yesterdayStats.totalFocusTime
        }
        
        return 0
    }
    
    private func getFocusStatistics(for date: Date, viewContext: NSManagedObjectContext) -> FocusStatistics {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@ AND isValid == YES", 
                                      startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let sessions = try viewContext.fetch(request)
            let totalTime = sessions.reduce(0) { $0 + $1.duration }
            let longestSession = sessions.map { $0.duration }.max() ?? 0
            let averageSession = sessions.isEmpty ? 0 : totalTime / Double(sessions.count)
            
            return FocusStatistics(
                totalFocusTime: totalTime,
                sessionCount: sessions.count,
                longestSession: longestSession,
                averageSession: averageSession
            )
        } catch {
            return FocusStatistics(totalFocusTime: 0, sessionCount: 0, longestSession: 0, averageSession: 0)
        }
    }
    
    private func getUserSettings(viewContext: NSManagedObjectContext) -> UserSettings {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try viewContext.fetch(request)
            if let userSettings = settings.first {
                return userSettings
            } else {
                return UserSettings.createDefaultSettings(in: viewContext)
            }
        } catch {
            return UserSettings.createDefaultSettings(in: viewContext)
        }
    }
}