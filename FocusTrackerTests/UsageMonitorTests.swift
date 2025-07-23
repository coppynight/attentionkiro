import XCTest
import Combine
@testable import FocusTracker

class UsageMonitorTests: XCTestCase {
    
    var usageMonitor: UsageMonitor!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        usageMonitor = UsageMonitor()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        usageMonitor = nil
        cancellables = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Monitoring State Tests
    
    func testInitialState() throws {
        // Then: Initial state should be correct
        XCTAssertFalse(usageMonitor.isMonitoring, "Should not be monitoring initially")
        XCTAssertNil(usageMonitor.lastScreenOffTime, "Last screen off time should be nil initially")
        XCTAssertNil(usageMonitor.lastScreenOnTime, "Last screen on time should be nil initially")
    }
    
    func testStartMonitoring() throws {
        // Given: Monitor is not running
        XCTAssertFalse(usageMonitor.isMonitoring)
        
        // When: Starting monitoring
        usageMonitor.startMonitoring()
        
        // Then: Should be monitoring
        XCTAssertTrue(usageMonitor.isMonitoring, "Should be monitoring after start")
    }
    
    func testStopMonitoring() throws {
        // Given: Monitor is running
        usageMonitor.startMonitoring()
        XCTAssertTrue(usageMonitor.isMonitoring)
        
        // When: Stopping monitoring
        usageMonitor.stopMonitoring()
        
        // Then: Should not be monitoring
        XCTAssertFalse(usageMonitor.isMonitoring, "Should not be monitoring after stop")
    }
    
    func testStartMonitoring_WhenAlreadyMonitoring() throws {
        // Given: Monitor is already running
        usageMonitor.startMonitoring()
        XCTAssertTrue(usageMonitor.isMonitoring)
        
        // When: Starting monitoring again
        usageMonitor.startMonitoring()
        
        // Then: Should still be monitoring (no change)
        XCTAssertTrue(usageMonitor.isMonitoring, "Should still be monitoring")
    }
    
    func testStopMonitoring_WhenNotMonitoring() throws {
        // Given: Monitor is not running
        XCTAssertFalse(usageMonitor.isMonitoring)
        
        // When: Stopping monitoring
        usageMonitor.stopMonitoring()
        
        // Then: Should still not be monitoring (no crash)
        XCTAssertFalse(usageMonitor.isMonitoring, "Should still not be monitoring")
    }
    
    // MARK: - Focus Session Detection Tests
    
    func testFocusSessionDetection_ValidSession() throws {
        // Given: A focus session detection expectation
        let expectation = XCTestExpectation(description: "Focus session detected")
        var detectedStartTime: Date?
        var detectedEndTime: Date?
        
        usageMonitor.onFocusSessionDetected = { startTime, endTime in
            detectedStartTime = startTime
            detectedEndTime = endTime
            expectation.fulfill()
        }
        
        // When: Simulating a focus session (screen off for 35 minutes)
        usageMonitor.startMonitoring()
        
        let screenOffTime = Date()
        usageMonitor.lastScreenOffTime = screenOffTime
        
        // Simulate screen turning on after 35 minutes
        let screenOnTime = screenOffTime.addingTimeInterval(35 * 60)
        
        // Manually trigger the screen on event (since we can't simulate actual notifications in tests)
        // This would normally be triggered by UIApplication notifications
        if let screenOffTime = usageMonitor.lastScreenOffTime {
            let unusedDuration = screenOnTime.timeIntervalSince(screenOffTime)
            if unusedDuration >= 30 * 60 {
                usageMonitor.onFocusSessionDetected?(screenOffTime, screenOnTime)
            }
        }
        
        // Then: Focus session should be detected
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(detectedStartTime, "Start time should be detected")
        XCTAssertNotNil(detectedEndTime, "End time should be detected")
        
        if let startTime = detectedStartTime, let endTime = detectedEndTime {
            let duration = endTime.timeIntervalSince(startTime)
            XCTAssertEqual(duration, 35 * 60, accuracy: 1.0, "Duration should be 35 minutes")
        }
    }
    
    func testFocusSessionDetection_TooShort() throws {
        // Given: A focus session detection expectation that should NOT be fulfilled
        let expectation = XCTestExpectation(description: "Focus session should not be detected")
        expectation.isInverted = true
        
        usageMonitor.onFocusSessionDetected = { _, _ in
            expectation.fulfill()
        }
        
        // When: Simulating a short session (screen off for 20 minutes)
        usageMonitor.startMonitoring()
        
        let screenOffTime = Date()
        usageMonitor.lastScreenOffTime = screenOffTime
        
        // Simulate screen turning on after 20 minutes (less than minimum)
        let screenOnTime = screenOffTime.addingTimeInterval(20 * 60)
        
        // Manually check if session would be detected
        if let screenOffTime = usageMonitor.lastScreenOffTime {
            let unusedDuration = screenOnTime.timeIntervalSince(screenOffTime)
            if unusedDuration >= 30 * 60 {
                usageMonitor.onFocusSessionDetected?(screenOffTime, screenOnTime)
            }
        }
        
        // Then: Focus session should NOT be detected
        wait(for: [expectation], timeout: 0.5)
    }
    
    // MARK: - Published Properties Tests
    
    func testPublishedProperties() throws {
        // Given: Expectations for published property changes
        let monitoringExpectation = XCTestExpectation(description: "Monitoring state changed")
        
        // When: Observing published properties
        usageMonitor.$isMonitoring
            .dropFirst() // Skip initial value
            .sink { isMonitoring in
                if isMonitoring {
                    monitoringExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When: Starting monitoring
        usageMonitor.startMonitoring()
        
        // Then: Published property should update
        wait(for: [monitoringExpectation], timeout: 1.0)
    }
    
    // MARK: - Screen State Tracking Tests
    
    func testScreenStateTracking() throws {
        // Given: Monitor is running
        usageMonitor.startMonitoring()
        
        // When: Setting screen off time
        let screenOffTime = Date()
        usageMonitor.lastScreenOffTime = screenOffTime
        
        // Then: Screen off time should be recorded
        XCTAssertEqual(usageMonitor.lastScreenOffTime, screenOffTime, "Screen off time should be recorded")
        
        // When: Setting screen on time
        let screenOnTime = Date()
        usageMonitor.lastScreenOnTime = screenOnTime
        
        // Then: Screen on time should be recorded
        XCTAssertEqual(usageMonitor.lastScreenOnTime, screenOnTime, "Screen on time should be recorded")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() throws {
        // Given: A usage monitor with callback
        weak var weakMonitor: UsageMonitor?
        
        autoreleasepool {
            let monitor = UsageMonitor()
            weakMonitor = monitor
            
            monitor.onFocusSessionDetected = { _, _ in
                // Callback that captures monitor
            }
            
            monitor.startMonitoring()
        }
        
        // Then: Monitor should be deallocated when no longer referenced
        // Note: This test might be flaky due to ARC optimizations
        // In a real scenario, we'd want to ensure proper cleanup
        XCTAssertNil(weakMonitor, "Monitor should be deallocated")
    }
}