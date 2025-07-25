import Foundation
@testable import FocusTracker

// 简化的测试用使用监控器
class TestUsageMonitor: UsageMonitor {
    
    override init() {
        super.init()
    }
    
    override func startMonitoring() {
        isMonitoring = true
    }
    
    override func stopMonitoring() {
        isMonitoring = false
    }
    
    override func getCurrentUsageSession() -> AppUsageData? {
        return nil
    }
    
    // Helper method for testing
    func simulateFocusSession(startTime: Date, endTime: Date) {
        onFocusSessionDetected?(startTime, endTime)
    }
    
    func simulateAppUsage(_ data: AppUsageData) {
        onAppUsageDetected?(data)
    }
}