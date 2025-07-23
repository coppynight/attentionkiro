import Foundation
@testable import FocusTracker

// 简化的测试用使用监控器
class TestUsageMonitor: UsageMonitorProtocol {
    var isMonitoring = false
    var onFocusSessionDetected: ((Date, Date) -> Void)?
    
    func startMonitoring() {
        isMonitoring = true
    }
    
    func stopMonitoring() {
        isMonitoring = false
    }
}