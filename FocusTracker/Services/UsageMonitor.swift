import Foundation
import UIKit
import Combine

/// Protocol defining usage monitoring capabilities
protocol UsageMonitorProtocol {
    func startMonitoring()
    func stopMonitoring()
    var onFocusSessionDetected: ((Date, Date) -> Void)? { get set }
}

/// Monitors device usage patterns to detect focus sessions
class UsageMonitor: ObservableObject, UsageMonitorProtocol {
    
    // MARK: - Properties
    
    @Published var isMonitoring = false
    @Published var lastScreenOffTime: Date?
    @Published var lastScreenOnTime: Date?
    
    var onFocusSessionDetected: ((Date, Date) -> Void)?
    
    private let minimumFocusTime: TimeInterval = 30 * 60 // 30 minutes
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupNotificationObservers()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        print("UsageMonitor: Started monitoring device usage")
        
        // Record initial state
        recordScreenEvent(isScreenOn: !UIApplication.shared.isIdleTimerDisabled)
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        print("UsageMonitor: Stopped monitoring device usage")
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        // Monitor app state changes as proxy for screen state
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleScreenOn()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleScreenOff()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleScreenOff()
            }
            .store(in: &cancellables)
    }
    
    private func handleScreenOn() {
        guard isMonitoring else { return }
        
        let now = Date()
        
        // Check if we had a potential focus session
        if let screenOffTime = lastScreenOffTime {
            let unusedDuration = now.timeIntervalSince(screenOffTime)
            
            if unusedDuration >= minimumFocusTime {
                // Detected a potential focus session
                print("UsageMonitor: Detected focus session - Duration: \(Int(unusedDuration/60)) minutes")
                onFocusSessionDetected?(screenOffTime, now)
            }
        }
        
        lastScreenOnTime = now
        recordScreenEvent(isScreenOn: true)
    }
    
    private func handleScreenOff() {
        guard isMonitoring else { return }
        
        let now = Date()
        lastScreenOffTime = now
        recordScreenEvent(isScreenOn: false)
    }
    
    private func recordScreenEvent(isScreenOn: Bool) {
        let eventType = isScreenOn ? "screen_on" : "screen_off"
        print("UsageMonitor: Screen event - \(eventType) at \(Date())")
    }
}