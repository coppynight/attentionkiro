import Foundation
import XCTest
@testable import FocusTracker

/// Simple test runner for manual execution of unit tests
/// This is a temporary solution until proper test target is configured
class TestRunner {
    
    static func runAllTests() {
        print("🧪 Starting FocusTracker Unit Tests...")
        print("=" * 50)
        
        var totalTests = 0
        var passedTests = 0
        var failedTests = 0
        
        // Run FocusManager Tests
        print("\n📱 Running FocusManager Tests...")
        let focusManagerResults = runFocusManagerTests()
        totalTests += focusManagerResults.total
        passedTests += focusManagerResults.passed
        failedTests += focusManagerResults.failed
        
        // Run UsageMonitor Tests
        print("\n📊 Running UsageMonitor Tests...")
        let usageMonitorResults = runUsageMonitorTests()
        totalTests += usageMonitorResults.total
        passedTests += usageMonitorResults.passed
        failedTests += usageMonitorResults.failed
        
        // Run Core Data Model Tests
        print("\n💾 Running Core Data Model Tests...")
        let coreDataResults = runCoreDataModelTests()
        totalTests += coreDataResults.total
        passedTests += coreDataResults.passed
        failedTests += coreDataResults.failed
        
        // Run Core Functionality Tests
        print("\n🔍 Running Core Functionality Tests...")
        let coreFunctionalityResults = runCoreFunctionalityTests()
        totalTests += coreFunctionalityResults.total
        passedTests += coreFunctionalityResults.passed
        failedTests += coreFunctionalityResults.failed
        
        // Run Background Detection Tests
        print("\n📱 Running Background Detection Tests...")
        let backgroundDetectionResults = runBackgroundDetectionTests()
        totalTests += backgroundDetectionResults.total
        passedTests += backgroundDetectionResults.passed
        failedTests += backgroundDetectionResults.failed
        
        // Print Summary
        print("\n" + "=" * 50)
        print("📋 Test Summary:")
        print("   Total Tests: \(totalTests)")
        print("   ✅ Passed: \(passedTests)")
        print("   ❌ Failed: \(failedTests)")
        print("   📊 Success Rate: \(passedTests * 100 / max(totalTests, 1))%")
        
        if failedTests == 0 {
            print("\n🎉 All tests passed!")
        } else {
            print("\n⚠️  Some tests failed. Please review the output above.")
        }
    }
    
    private static func runFocusManagerTests() -> TestResults {
        let testSuite = FocusManagerTests()
        var results = TestResults()
        
        do {
            try testSuite.setUpWithError()
            
            // Run individual tests
            results.add(runTest("Add Focus Session") {
                try testSuite.testAddFocusSession()
            })
            
            results.add(runTest("Core Functionality") {
                try testSuite.testCoreFunctionality()
            })
            
            try testSuite.tearDownWithError()
            
        } catch {
            print("❌ Failed to setup FocusManager tests: \(error)")
            results.failed += 1
        }
        
        return results
    }
    
    private static func runUsageMonitorTests() -> TestResults {
        let testSuite = UsageMonitorTests()
        var results = TestResults()
        
        do {
            try testSuite.setUpWithError()
            
            // Run individual tests
            results.add(runTest("Initial State") {
                try testSuite.testInitialState()
            })
            
            results.add(runTest("Start Monitoring") {
                try testSuite.testStartMonitoring()
            })
            
            results.add(runTest("Stop Monitoring") {
                try testSuite.testStopMonitoring()
            })
            
            results.add(runTest("Start Monitoring When Already Monitoring") {
                try testSuite.testStartMonitoring_WhenAlreadyMonitoring()
            })
            
            results.add(runTest("Stop Monitoring When Not Monitoring") {
                try testSuite.testStopMonitoring_WhenNotMonitoring()
            })
            
            results.add(runTest("Focus Session Detection - Valid Session") {
                try testSuite.testFocusSessionDetection_ValidSession()
            })
            
            results.add(runTest("Focus Session Detection - Too Short") {
                try testSuite.testFocusSessionDetection_TooShort()
            })
            
            results.add(runTest("Screen State Tracking") {
                try testSuite.testScreenStateTracking()
            })
            
            try testSuite.tearDownWithError()
            
        } catch {
            print("❌ Failed to setup UsageMonitor tests: \(error)")
            results.failed += 1
        }
        
        return results
    }
    
    private static func runCoreDataModelTests() -> TestResults {
        let testSuite = CoreDataModelTests()
        var results = TestResults()
        
        do {
            try testSuite.setUpWithError()
            
            // Run individual tests
            results.add(runTest("FocusSession Creation") {
                try testSuite.testFocusSession_Creation()
            })
            
            results.add(runTest("FocusSession Formatted Duration") {
                try testSuite.testFocusSession_FormattedDuration()
            })
            
            results.add(runTest("FocusSession Is Active") {
                try testSuite.testFocusSession_IsActive()
            })
            
            results.add(runTest("FocusSession Current Duration") {
                try testSuite.testFocusSession_CurrentDuration()
            })
            
            results.add(runTest("FocusSession End Session") {
                try testSuite.testFocusSession_EndSession()
            })
            
            results.add(runTest("FocusSession End Session Already Ended") {
                try testSuite.testFocusSession_EndSession_AlreadyEnded()
            })
            
            results.add(runTest("FocusSession Validate Session") {
                try testSuite.testFocusSession_ValidateSession()
            })
            
            results.add(runTest("UserSettings Creation") {
                try testSuite.testUserSettings_Creation()
            })
            
            results.add(runTest("UserSettings Formatted Daily Goal") {
                try testSuite.testUserSettings_FormattedDailyGoal()
            })
            
            results.add(runTest("UserSettings Sleep Duration Hours") {
                try testSuite.testUserSettings_SleepDurationHours()
            })
            
            results.add(runTest("UserSettings Is Within Sleep Time") {
                try testSuite.testUserSettings_IsWithinSleepTime()
            })
            
            results.add(runTest("UserSettings Is Within Lunch Break") {
                try testSuite.testUserSettings_IsWithinLunchBreak()
            })
            
            results.add(runTest("UserSettings Is Within Lunch Break Disabled") {
                try testSuite.testUserSettings_IsWithinLunchBreak_Disabled()
            })
            
            results.add(runTest("UserSettings Create Default Settings") {
                try testSuite.testUserSettings_CreateDefaultSettings()
            })
            
            results.add(runTest("FocusSession Persistence") {
                try testSuite.testFocusSession_Persistence()
            })
            
            results.add(runTest("UserSettings Persistence") {
                try testSuite.testUserSettings_Persistence()
            })
            
            try testSuite.tearDownWithError()
            
        } catch {
            print("❌ Failed to setup CoreDataModel tests: \(error)")
            results.failed += 1
        }
        
        return results
    }
    
    private static func runCoreFunctionalityTests() -> TestResults {
        let testSuite = CoreFunctionalityTests()
        var results = TestResults()
        
        do {
            try testSuite.setUpWithError()
            
            // Run individual tests
            results.add(runTest("Focus Session Detection") {
                try testSuite.testFocusSessionDetection()
            })
            
            results.add(runTest("Short Sessions Not Detected") {
                try testSuite.testShortSessionsNotDetected()
            })
            
            results.add(runTest("Session During Sleep Time") {
                try testSuite.testSessionDuringSleepTime()
            })
            
            results.add(runTest("Focus Session Storage") {
                try testSuite.testFocusSessionStorage()
            })
            
            results.add(runTest("User Settings Storage") {
                try testSuite.testUserSettingsStorage()
            })
            
            results.add(runTest("Focus Statistics Calculation") {
                try testSuite.testFocusStatisticsCalculation()
            })
            
            results.add(runTest("Weekly Trend Generation") {
                try testSuite.testWeeklyTrendGeneration()
            })
            
            results.add(runTest("Today's Focus Time Calculation") {
                try testSuite.testTodaysFocusTimeCalculation()
            })
            
            results.add(runTest("Monitoring State Tracking") {
                try testSuite.testMonitoringStateTracking()
            })
            
            try testSuite.tearDownWithError()
            
        } catch {
            print("❌ Failed to setup Core Functionality tests: \(error)")
            results.failed += 1
        }
        
        return results
    }
    
    private static func runBackgroundDetectionTests() -> TestResults {
        let testSuite = BackgroundDetectionTests()
        var results = TestResults()
        
        do {
            try testSuite.setUpWithError()
            
            // Run individual tests
            results.add(runTest("App State Transition Detection") {
                try testSuite.testAppStateTransitionDetection()
            })
            
            results.add(runTest("Background Task Management") {
                try testSuite.testBackgroundTaskManagement()
            })
            
            results.add(runTest("Duplicate Session Prevention") {
                try testSuite.testDuplicateSessionPrevention()
            })
            
            results.add(runTest("Long Background Session Detection") {
                try testSuite.testLongBackgroundSessionDetection()
            })
            
            results.add(runTest("Background Data Persistence") {
                try testSuite.testBackgroundDataPersistence()
            })
            
            try testSuite.tearDownWithError()
            
        } catch {
            print("❌ Failed to setup Background Detection tests: \(error)")
            results.failed += 1
        }
        
        return results
    }
    
    private static func runTest(_ testName: String, test: () throws -> Void) -> TestResult {
        do {
            try test()
            print("   ✅ \(testName)")
            return .passed
        } catch {
            print("   ❌ \(testName) - \(error)")
            return .failed
        }
    }
}

// MARK: - Helper Types

struct TestResults {
    var total: Int = 0
    var passed: Int = 0
    var failed: Int = 0
    
    mutating func add(_ result: TestResult) {
        total += 1
        switch result {
        case .passed:
            passed += 1
        case .failed:
            failed += 1
        }
    }
}

enum TestResult {
    case passed
    case failed
}

// MARK: - String Extension

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - Test Execution Entry Point

/// Uncomment the line below to run tests manually
// TestRunner.runAllTests()