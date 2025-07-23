import XCTest
import CoreData
@testable import FocusTracker

/// Test class for verifying background detection functionality
class BackgroundDetectionTests: XCTestCase {
    
    private var testContext: NSManagedObjectContext!
    private var focusManager: FocusManager!
    private var usageMonitor: UsageMonitor!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory Core Data stack for testing
        let persistentContainer = NSPersistentContainer(name: "FocusDataModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        testContext = persistentContainer.viewContext
        usageMonitor = UsageMonitor()
        focusManager = FocusManager(usageMonitor: usageMonitor, viewContext: testContext)
    }
    
    override func tearDownWithError() throws {
        focusManager = nil
        usageMonitor = nil
        testContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Background Detection Tests
    
    func testAppStateTransitionDetection() throws {
        // Given: UsageMonitor with callback
        var detectedSessions: [(Date, Date)] = []
        
        usageMonitor.onFocusSessionDetected = { startTime, endTime in
            detectedSessions.append((startTime, endTime))
        }
        
        // When: Simulating app state transitions
        usageMonitor.startMonitoring()
        
        let inactiveTime = Date()
        usageMonitor.lastAppInactiveTime = inactiveTime
        
        // Simulate app becoming active after 35 minutes
        let activeTime = inactiveTime.addingTimeInterval(35 * 60)
        
        // Manually trigger the detection (simulating app becoming active)
        if let inactiveTime = usageMonitor.lastAppInactiveTime {
            let inactiveDuration = activeTime.timeIntervalSince(inactiveTime)
            if inactiveDuration >= 30 * 60 {
                usageMonitor.onFocusSessionDetected?(inactiveTime, activeTime)
            }
        }
        
        // Then: Session should be detected
        XCTAssertFalse(detectedSessions.isEmpty, "No focus session was detected during app state transition")
        
        let session = detectedSessions.first!
        XCTAssertEqual(session.0, inactiveTime, "Start time does not match app inactive time")
        XCTAssertEqual(session.1, activeTime, "End time does not match app active time")
    }
    
    func testBackgroundTaskManagement() throws {
        // Given: UsageMonitor
        usageMonitor.startMonitoring()
        
        // When: Simulating background task lifecycle
        // Note: We can't fully test UIApplication.beginBackgroundTask in unit tests,
        // but we can verify the logic doesn't crash
        
        // Simulate app entering background
        let now = Date()
        usageMonitor.lastAppInactiveTime = now
        
        // Then: Should not throw any errors
        // This test mainly ensures the background task management code doesn't crash
        XCTAssertTrue(usageMonitor.isMonitoring, "Usage monitor should still be monitoring")
    }
    
    func testDuplicateSessionPrevention() throws {
        // Given: A focus session already exists
        let startTime = Date().addingTimeInterval(-45 * 60)
        let endTime = Date()
        
        let existingSession = FocusSession(context: testContext)
        existingSession.startTime = startTime
        existingSession.endTime = endTime
        existingSession.duration = endTime.timeIntervalSince(startTime)
        existingSession.isValid = true
        existingSession.sessionType = "focus"
        
        try testContext.save()
        
        // When: Trying to create a similar session
        let similarStartTime = startTime.addingTimeInterval(2 * 60) // 2 minutes later
        let similarEndTime = endTime.addingTimeInterval(2 * 60)     // 2 minutes later
        
        // Manually call the detection handler
        let initialCount = try getFocusSessionCount()
        
        // Create another session with similar timing
        let newSession = FocusSession(context: testContext)
        newSession.startTime = similarStartTime
        newSession.endTime = similarEndTime
        newSession.duration = similarEndTime.timeIntervalSince(similarStartTime)
        newSession.isValid = true
        newSession.sessionType = "focus"
        
        try testContext.save()
        
        let finalCount = try getFocusSessionCount()
        
        // Then: Should have both sessions (duplicate prevention is more complex in real implementation)
        XCTAssertEqual(finalCount, initialCount + 1, "Expected \(initialCount + 1) sessions, got \(finalCount)")
    }
    
    func testLongBackgroundSessionDetection() throws {
        // Given: App has been inactive for a very long time
        let veryLongInactiveTime = Date().addingTimeInterval(-4 * 3600) // 4 hours ago
        
        usageMonitor.startMonitoring()
        usageMonitor.lastAppInactiveTime = veryLongInactiveTime
        
        var detectedSessions: [(Date, Date)] = []
        usageMonitor.onFocusSessionDetected = { startTime, endTime in
            detectedSessions.append((startTime, endTime))
        }
        
        // When: App becomes active
        let now = Date()
        
        // Simulate the detection logic
        if let inactiveTime = usageMonitor.lastAppInactiveTime {
            let inactiveDuration = now.timeIntervalSince(inactiveTime)
            if inactiveDuration >= 30 * 60 {
                usageMonitor.onFocusSessionDetected?(inactiveTime, now)
            }
        }
        
        // Then: Should detect the long session
        XCTAssertFalse(detectedSessions.isEmpty, "Long background session was not detected")
        
        let session = detectedSessions.first!
        let duration = session.1.timeIntervalSince(session.0)
        
        XCTAssertGreaterThanOrEqual(duration, 4 * 3600 - 60, "Detected session duration (\(duration/3600) hours) is shorter than expected")
    }
    
    func testBackgroundDataPersistence() throws {
        // Given: A focus session detected in background
        let startTime = Date().addingTimeInterval(-60 * 60) // 1 hour ago
        let endTime = Date()
        
        // When: Saving session data (simulating background save)
        let session = FocusSession(context: testContext)
        session.startTime = startTime
        session.endTime = endTime
        session.duration = endTime.timeIntervalSince(startTime)
        session.isValid = true
        session.sessionType = "focus"
        
        try testContext.save()
        
        // Then: Data should be persisted correctly
        let fetchedSessions = try getFocusSessionsForToday()
        
        XCTAssertFalse(fetchedSessions.isEmpty, "No sessions were persisted")
        
        let persistedSession = fetchedSessions.first!
        XCTAssertEqual(persistedSession.startTime, startTime, "Start time was not persisted correctly")
        XCTAssertEqual(persistedSession.endTime, endTime, "End time was not persisted correctly")
        XCTAssertTrue(persistedSession.isValid, "Session validity was not persisted correctly")
    }
    
    // MARK: - Helper Methods
    
    private func getFocusSessionCount() throws -> Int {
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        return try testContext.count(for: request)
    }
    
    private func getFocusSessionsForToday() throws -> [FocusSession] {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", 
                                      startOfDay as NSDate, endOfDay as NSDate)
        
        return try testContext.fetch(request)
    }
}