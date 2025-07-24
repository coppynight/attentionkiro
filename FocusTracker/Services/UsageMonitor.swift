import Foundation
import UIKit
import Combine
import BackgroundTasks

/// Protocol defining usage monitoring capabilities
protocol UsageMonitorProtocol {
    func startMonitoring()
    func stopMonitoring()
    var onFocusSessionDetected: ((Date, Date) -> Void)? { get set }
}

/// Monitors device usage patterns to detect focus sessions
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
    
    var onFocusSessionDetected: ((Date, Date) -> Void)?
    
    internal let minimumFocusTime: TimeInterval = 30 * 60 // 30 minutes
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
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
        
        // Schedule background processing
        scheduleBackgroundProcessing()
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        endBackgroundTask()
        print("UsageMonitor: Stopped monitoring device usage")
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
}