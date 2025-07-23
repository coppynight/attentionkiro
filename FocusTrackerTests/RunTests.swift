import Foundation
@testable import FocusTracker

// Simple test runner that can be called from anywhere
class RunTests {
    static func execute() {
        print("🧪 Running Core Functionality Tests...")
        
        let tests = CoreFunctionalityTests()
        
        do {
            try tests.setUpWithError()
            
            // Focus Session Detection Tests
            print("Testing Focus Session Detection...")
            try tests.testFocusSessionDetection()
            print("✅ testFocusSessionDetection passed")
            
            try tests.testShortSessionsNotDetected()
            print("✅ testShortSessionsNotDetected passed")
            
            try tests.testSessionDuringSleepTime()
            print("✅ testSessionDuringSleepTime passed")
            
            // Data Storage Tests
            print("\nTesting Data Storage and Retrieval...")
            try tests.testFocusSessionStorage()
            print("✅ testFocusSessionStorage passed")
            
            try tests.testUserSettingsStorage()
            print("✅ testUserSettingsStorage passed")
            
            try tests.testFocusStatisticsCalculation()
            print("✅ testFocusStatisticsCalculation passed")
            
            try tests.testWeeklyTrendGeneration()
            print("✅ testWeeklyTrendGeneration passed")
            
            // UI Interaction Tests
            print("\nTesting Basic UI Interactions...")
            try tests.testTodaysFocusTimeCalculation()
            print("✅ testTodaysFocusTimeCalculation passed")
            
            try tests.testMonitoringStateTracking()
            print("✅ testMonitoringStateTracking passed")
            
            try tests.tearDownWithError()
            
            print("\n🎉 All Core Functionality Tests Passed!")
            
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }
}