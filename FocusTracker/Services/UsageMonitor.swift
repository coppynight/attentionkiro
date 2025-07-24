import Foundation
import UIKit
import Combine
import BackgroundTasks
import DeviceActivity
import FamilyControls

/// Protocol defining usage monitoring capabilities
protocol UsageMonitorProtocol {
    func startMonitoring()
    func stopMonitoring()
    var onFocusSessionDetected: ((Date, Date) -> Void)? { get set }
    var onAppUsageDetected: ((AppUsageData) -> Void)? { get set }
    func getCurrentUsageSession() -> AppUsageData?
}

/// Represents app usage data
struct AppUsageData {
    let appIdentifier: String
    let appName: String
    let categoryIdentifier: String
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let interruptionCount: Int
    
    init(appIdentifier: String, appName: String, categoryIdentifier: String, startTime: Date, endTime: Date, interruptionCount: Int = 0) {
        self.appIdentifier = appIdentifier
        self.appName = appName
        self.categoryIdentifier = categoryIdentifier
        self.startTime = startTime
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
        self.interruptionCount = interruptionCount
    }
}

/// Monitors device usage patterns to detect focus sessions and app usage
class UsageMonitor: ObservableObject, UsageMonitorProtocol {
    
    // MARK: - Static Properties
    
    static let backgroundProcessingTaskID = "com.focustracker.app.processing"
    private static var backgroundTaskHandler: ((BGProcessingTask) -> Void)?
    
    // MARK: - Properties
    
    @Published var isMonitoring = false
    @Published var lastScreenOffTime: Date?
    @Published var lastScreenOnTime: Date?
    @Published var lastAppActiveTime: Date?
    @Published var lastAppInactiveTime: Date?
    @Published var currentAppUsage: AppUsageData?
    @Published var todayUsageTime: TimeInterval = 0
    @Published var appUsageSessions: [AppUsageData] = []
    
    var onFocusSessionDetected: ((Date, Date) -> Void)?
    var onAppUsageDetected: ((AppUsageData) -> Void)?
    
    internal let minimumFocusTime: TimeInterval = 30 * 60 // 30 minutes
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // DeviceActivity monitoring
    private var deviceActivityMonitor: DeviceActivityMonitor?
    private var currentAppSession: AppUsageData?
    private var appStartTime: Date?
    private var lastActiveApp: String?
    
    // MARK: - Initialization
    
    init() {
        setupNotificationObservers()
        // Set up the background task handler for this instance
        UsageMonitor.backgroundTaskHandler = { [weak self] task in
            self?.handleBackgroundProcessing(task: task)
        }
    }
    
    // MARK: - Static Methods
    
    static func registerBackgroundTasks() {
        // Register background processing task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundProcessingTaskID, using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else {
                print("UsageMonitor: Failed to cast task to BGProcessingTask")
                task.setTaskCompleted(success: false)
                return
            }
            backgroundTaskHandler?(processingTask)
        }
    }
    
    deinit {
        stopMonitoring()
        endBackgroundTask()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        print("UsageMonitor: Started monitoring device usage")
        
        // Record initial state
        let now = Date()
        lastAppActiveTime = now
        recordScreenEvent(isScreenOn: true)
        
        // Start DeviceActivity monitoring if permission is granted
        startDeviceActivityMonitoring()
        
        // Schedule background processing
        scheduleBackgroundProcessing()
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        stopDeviceActivityMonitoring()
        endBackgroundTask()
        print("UsageMonitor: Stopped monitoring device usage")
    }
    
    func getCurrentUsageSession() -> AppUsageData? {
        return currentAppSession
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        // Monitor app state changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppBecomeActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppWillResignActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)
    }
    

    
    internal func handleAppBecomeActive() {
        guard isMonitoring else { return }
        
        let now = Date()
        lastAppActiveTime = now
        
        // Check if we had a potential focus session while app was inactive
        if let inactiveTime = lastAppInactiveTime {
            let inactiveDuration = now.timeIntervalSince(inactiveTime)
            
            if inactiveDuration >= minimumFocusTime {
                // Detected a potential focus session
                print("UsageMonitor: Detected focus session - Duration: \(Int(inactiveDuration/60)) minutes")
                onFocusSessionDetected?(inactiveTime, now)
            }
        }
        
        recordScreenEvent(isScreenOn: true)
        endBackgroundTask()
    }
    
    private func handleAppWillResignActive() {
        guard isMonitoring else { return }
        
        let now = Date()
        lastAppInactiveTime = now
        recordScreenEvent(isScreenOn: false)
    }
    
    private func handleAppDidEnterBackground() {
        guard isMonitoring else { return }
        
        // Start background task to continue monitoring
        startBackgroundTask()
        
        // Schedule background processing for later
        scheduleBackgroundProcessing()
        
        print("UsageMonitor: App entered background, started background monitoring")
    }
    
    private func handleAppWillEnterForeground() {
        guard isMonitoring else { return }
        
        print("UsageMonitor: App will enter foreground")
        
        // Background task will be ended in handleAppBecomeActive
    }
    
    private func recordScreenEvent(isScreenOn: Bool) {
        let eventType = isScreenOn ? "app_active" : "app_inactive"
        print("UsageMonitor: App event - \(eventType) at \(Date())")
    }
    
    // MARK: - Background Task Management
    
    private func startBackgroundTask() {
        endBackgroundTask() // End any existing background task
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "FocusMonitoring") { [weak self] in
            print("UsageMonitor: Background task expired")
            self?.endBackgroundTask()
        }
        
        print("UsageMonitor: Started background task with ID: \(backgroundTaskID.rawValue)")
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            print("UsageMonitor: Ending background task with ID: \(backgroundTaskID.rawValue)")
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    private func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: UsageMonitor.backgroundProcessingTaskID)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("UsageMonitor: Scheduled background processing task")
        } catch {
            print("UsageMonitor: Failed to schedule background processing: \(error)")
        }
    }
    
    private func handleBackgroundProcessing(task: BGProcessingTask) {
        print("UsageMonitor: Handling background processing task")
        
        // Schedule the next background processing
        scheduleBackgroundProcessing()
        
        task.expirationHandler = {
            print("UsageMonitor: Background processing task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform background processing
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.performBackgroundProcessing()
            task.setTaskCompleted(success: true)
        }
    }
    
    private func performBackgroundProcessing() {
        guard isMonitoring else { return }
        
        let now = Date()
        
        // Check if we have been inactive for a long time and should record a focus session
        if let inactiveTime = lastAppInactiveTime {
            let inactiveDuration = now.timeIntervalSince(inactiveTime)
            
            // If we've been inactive for more than the minimum focus time, 
            // and we haven't recorded this session yet, record it
            if inactiveDuration >= minimumFocusTime {
                print("UsageMonitor: Background processing detected long focus session - Duration: \(Int(inactiveDuration/60)) minutes")
                
                // We'll let the foreground detection handle this when the app becomes active again
                // This is just for logging and potential future enhancements
            }
        }
        
        print("UsageMonitor: Background processing completed")
    }
    
    // MARK: - DeviceActivity Monitoring
    
    private func startDeviceActivityMonitoring() {
        // Check if we have permission
        guard AuthorizationCenter.shared.authorizationStatus == .approved else {
            print("UsageMonitor: DeviceActivity permission not granted")
            return
        }
        
        print("UsageMonitor: Starting DeviceActivity monitoring")
        
        // Create device activity monitor
        deviceActivityMonitor = DeviceActivityMonitor()
        
        // Start monitoring app usage
        startAppUsageTracking()
    }
    
    private func stopDeviceActivityMonitoring() {
        deviceActivityMonitor = nil
        currentAppSession = nil
        appStartTime = nil
        lastActiveApp = nil
        print("UsageMonitor: Stopped DeviceActivity monitoring")
    }
    
    private func startAppUsageTracking() {
        // Simulate app usage tracking since DeviceActivity requires app extensions
        // In a real implementation, this would use DeviceActivityMonitor with proper extensions
        
        // For now, we'll track basic app state changes and simulate app usage data
        simulateAppUsageTracking()
    }
    
    private func simulateAppUsageTracking() {
        // This is a simplified simulation of app usage tracking
        // In a real implementation, DeviceActivity would provide actual app usage data
        
        let timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateSimulatedAppUsage()
        }
        
        // Store timer reference for cleanup
        timer.fire()
    }
    
    private func updateSimulatedAppUsage() {
        guard isMonitoring else { return }
        
        let now = Date()
        
        // Simulate different app usage patterns
        let simulatedApps = [
            ("com.apple.mobilesafari", "Safari", "Productivity"),
            ("com.apple.mobilemail", "Mail", "Productivity"),
            ("com.tencent.xin", "WeChat", "Social"),
            ("com.apple.MobileAddressBook", "Contacts", "Utilities"),
            ("com.apple.mobilenotes", "Notes", "Productivity")
        ]
        
        // Randomly select an app to simulate usage
        if let randomApp = simulatedApps.randomElement() {
            let sessionDuration = TimeInterval.random(in: 30...300) // 30 seconds to 5 minutes
            let startTime = now.addingTimeInterval(-sessionDuration)
            
            let appUsage = AppUsageData(
                appIdentifier: randomApp.0,
                appName: randomApp.1,
                categoryIdentifier: randomApp.2,
                startTime: startTime,
                endTime: now,
                interruptionCount: Int.random(in: 0...3)
            )
            
            // Update current session
            currentAppSession = appUsage
            
            // Add to sessions array
            appUsageSessions.append(appUsage)
            
            // Update today's usage time
            todayUsageTime += sessionDuration
            
            // Notify observers
            onAppUsageDetected?(appUsage)
            
            print("UsageMonitor: Simulated app usage - \(randomApp.1) for \(Int(sessionDuration)) seconds")
        }
    }
    
    private func processAppUsageEvent(appIdentifier: String, appName: String, categoryIdentifier: String, eventType: String) {
        let now = Date()
        
        switch eventType {
        case "app_started":
            // End previous session if exists
            if let currentSession = currentAppSession {
                finalizeAppSession(currentSession, endTime: now)
            }
            
            // Start new session
            appStartTime = now
            lastActiveApp = appIdentifier
            
            print("UsageMonitor: App started - \(appName)")
            
        case "app_ended":
            // End current session
            if let startTime = appStartTime, lastActiveApp == appIdentifier {
                let appUsage = AppUsageData(
                    appIdentifier: appIdentifier,
                    appName: appName,
                    categoryIdentifier: categoryIdentifier,
                    startTime: startTime,
                    endTime: now
                )
                
                finalizeAppSession(appUsage, endTime: now)
            }
            
            appStartTime = nil
            lastActiveApp = nil
            
            print("UsageMonitor: App ended - \(appName)")
            
        default:
            break
        }
    }
    
    private func finalizeAppSession(_ session: AppUsageData, endTime: Date) {
        // Update session with final end time
        let finalSession = AppUsageData(
            appIdentifier: session.appIdentifier,
            appName: session.appName,
            categoryIdentifier: session.categoryIdentifier,
            startTime: session.startTime,
            endTime: endTime,
            interruptionCount: session.interruptionCount
        )
        
        // Only process sessions longer than 5 seconds
        guard finalSession.duration >= 5 else { return }
        
        // Update current session
        currentAppSession = finalSession
        
        // Add to sessions array
        appUsageSessions.append(finalSession)
        
        // Update today's usage time
        todayUsageTime += finalSession.duration
        
        // Notify observers
        onAppUsageDetected?(finalSession)
        
        print("UsageMonitor: Finalized app session - \(finalSession.appName) for \(Int(finalSession.duration)) seconds")
    }
    
    // MARK: - Helper Methods
    
    func getTodayAppUsage() -> [AppUsageData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return appUsageSessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: today)
        }
    }
    
    func getAppUsageBreakdown(for date: Date) -> [String: TimeInterval] {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        let dayUsage = appUsageSessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: targetDay)
        }
        
        var breakdown: [String: TimeInterval] = [:]
        for session in dayUsage {
            breakdown[session.appName, default: 0] += session.duration
        }
        
        return breakdown
    }
    
    func getWeeklyUsageTrend() -> [Date: TimeInterval] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [Date: TimeInterval] = [:]
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            
            let dayUsage = appUsageSessions.filter { session in
                calendar.isDate(session.startTime, inSameDayAs: dayStart)
            }
            
            let totalTime = dayUsage.reduce(0) { $0 + $1.duration }
            weeklyData[dayStart] = totalTime
        }
        
        return weeklyData
    }
}