import Foundation
import CoreData
import Combine
import UserNotifications

/// Statistics for focus data
struct FocusStatistics {
    let totalFocusTime: TimeInterval
    let sessionCount: Int
    let longestSession: TimeInterval
    let averageSession: TimeInterval
}

/// Daily focus data for trends
struct DailyFocusData {
    let date: Date
    let totalFocusTime: TimeInterval
    let sessionCount: Int
}

/// Protocol defining focus management capabilities
protocol FocusManagerProtocol {
    func startMonitoring()
    func stopMonitoring()
    func getCurrentFocusSession() -> FocusSession?
    func getFocusStatistics(for date: Date) -> FocusStatistics
    func getWeeklyTrend() -> [DailyFocusData]
}

/// Manages focus session detection, validation, and storage
class FocusManager: ObservableObject, FocusManagerProtocol {
    
    // MARK: - Published Properties
    
    @Published var currentSession: FocusSession?
    @Published var todaysFocusTime: TimeInterval = 0
    @Published var isInFocusMode: Bool = false
    @Published var isMonitoring: Bool = false
    
    // MARK: - Private Properties
    
    private let usageMonitor: UsageMonitor
    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    @MainActor private let notificationManager = NotificationManager.shared
    
    // MARK: - Initialization
    
    init(usageMonitor: UsageMonitor, viewContext: NSManagedObjectContext) {
        self.usageMonitor = usageMonitor
        self.viewContext = viewContext
        
        setupUsageMonitorCallbacks()
        calculateTodaysFocusTime()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        usageMonitor.startMonitoring()
        print("FocusManager: Started focus monitoring")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        usageMonitor.stopMonitoring()
        print("FocusManager: Stopped focus monitoring")
    }
    
    func getCurrentFocusSession() -> FocusSession? {
        return currentSession
    }
    
    func getFocusStatistics(for date: Date) -> FocusStatistics {
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
            print("FocusManager: Error fetching focus statistics - \(error)")
            return FocusStatistics(totalFocusTime: 0, sessionCount: 0, longestSession: 0, averageSession: 0)
        }
    }
    
    func getWeeklyTrend() -> [DailyFocusData] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [DailyFocusData] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let stats = getFocusStatistics(for: date)
            
            weeklyData.append(DailyFocusData(
                date: date,
                totalFocusTime: stats.totalFocusTime,
                sessionCount: stats.sessionCount
            ))
        }
        
        return weeklyData.reversed()
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func sendBasicEncouragementIfNeeded(for session: FocusSession) async {
        let duration = session.duration
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        // Send encouragement for sessions longer than 1 hour
        if duration >= 3600 { // 1 hour
            let message = "太棒了！你刚刚完成了一个 \(hours)小时\(minutes)分钟的专注时段！"
            await notificationManager.sendEncouragementNotification(message: message)
        }
        // Send encouragement for first session of the day
        else if isFirstSessionOfDay() {
            let message = "很好的开始！你今天的第一个专注时段已完成，继续保持！"
            await notificationManager.sendEncouragementNotification(message: message)
        }
        // Send encouragement for sessions during typical break times
        else if isSessionDuringBreakTime(session.startTime) {
            let message = "在休息时间也能保持专注，你的自律性很强！"
            await notificationManager.sendEncouragementNotification(message: message)
        }
        
        // Check daily goal achievement
        let today = Date()
        let stats = getFocusStatistics(for: today)
        let userSettings = getUserSettings()
        
        // If this session helped achieve the daily goal, send a goal achievement notification
        if stats.totalFocusTime >= userSettings.dailyFocusGoal && 
           (stats.totalFocusTime - session.duration) < userSettings.dailyFocusGoal {
            await notificationManager.sendGoalAchievedNotification(
                focusTime: stats.totalFocusTime,
                goal: userSettings.dailyFocusGoal
            )
        }
    }
    
    private func isFirstSessionOfDay() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@ AND isValid == YES", 
                                      today as NSDate, tomorrow as NSDate)
        request.fetchLimit = 1
        
        do {
            let sessions = try viewContext.fetch(request)
            return sessions.count <= 1 // Current session is the first or only one
        } catch {
            return false
        }
    }
    
    private func isSessionDuringBreakTime(_ startTime: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startTime)
        
        // Consider lunch time (12-14) and evening (18-20) as typical break times
        return (hour >= 12 && hour < 14) || (hour >= 18 && hour < 20)
    }
    
    private func setupUsageMonitorCallbacks() {
        usageMonitor.onFocusSessionDetected = { [weak self] startTime, endTime in
            self?.handleFocusSessionDetected(startTime: startTime, endTime: endTime)
        }
    }
    
    private func handleFocusSessionDetected(startTime: Date, endTime: Date) {
        let duration = endTime.timeIntervalSince(startTime)
        
        // Check if we already have a session for this time period to avoid duplicates
        if isDuplicateSession(startTime: startTime, endTime: endTime) {
            print("FocusManager: Duplicate session detected, skipping")
            return
        }
        
        // Create new focus session
        let focusSession = FocusSession(context: viewContext)
        focusSession.startTime = startTime
        focusSession.endTime = endTime
        focusSession.duration = duration
        focusSession.sessionType = "focus"
        focusSession.isValid = validateFocusSession(startTime: startTime, endTime: endTime, duration: duration)
        
        // Save to Core Data with background context if needed
        let contextToUse = Thread.isMainThread ? viewContext : viewContext
        
        contextToUse.perform {
            do {
                try contextToUse.save()
                print("FocusManager: Saved focus session - Duration: \(Int(duration/60)) minutes, Valid: \(focusSession.isValid)")
                
                // Update today's focus time if session is valid
                if focusSession.isValid {
                    DispatchQueue.main.async {
                        self.calculateTodaysFocusTime()
                        
                        // Send basic encouragement for good focus sessions
                        Task { @MainActor in
                            await self.sendBasicEncouragementIfNeeded(for: focusSession)
                            await self.notificationManager.checkAndSendSmartNotifications(viewContext: self.viewContext)
                        }
                    }
                }
            } catch {
                print("FocusManager: Error saving focus session - \(error)")
            }
        }
    }
    
    private func isDuplicateSession(startTime: Date, endTime: Date) -> Bool {
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        
        // Check for sessions that overlap with the new session
        let startBuffer: TimeInterval = 5 * 60 // 5 minutes buffer
        let endBuffer: TimeInterval = 5 * 60   // 5 minutes buffer
        
        let bufferedStartTime = startTime.addingTimeInterval(-startBuffer)
        let bufferedEndTime = endTime.addingTimeInterval(endBuffer)
        
        request.predicate = NSPredicate(format: "startTime >= %@ AND endTime <= %@", 
                                      bufferedStartTime as NSDate, bufferedEndTime as NSDate)
        request.fetchLimit = 1
        
        do {
            let existingSessions = try viewContext.fetch(request)
            return !existingSessions.isEmpty
        } catch {
            print("FocusManager: Error checking for duplicate sessions - \(error)")
            return false
        }
    }
    
    private func validateFocusSession(startTime: Date, endTime: Date, duration: TimeInterval) -> Bool {
        // Basic validation: minimum 30 minutes
        let minimumFocusTime: TimeInterval = 30 * 60
        
        guard duration >= minimumFocusTime else {
            print("FocusManager: Session too short - \(Int(duration/60)) minutes")
            return false
        }
        
        // Sleep time filtering: exclude sessions during sleep hours
        if isInSleepTime(startTime: startTime, endTime: endTime) {
            print("FocusManager: Session during sleep time - excluded")
            return false
        }
        
        return true
    }
    
    private func isInSleepTime(startTime: Date, endTime: Date) -> Bool {
        // Get user settings for sleep time configuration
        let userSettings = getUserSettings()
        
        // Check if session overlaps with sleep time
        if userSettings.isWithinSleepTime(startTime) || userSettings.isWithinSleepTime(endTime) {
            return true
        }
        
        // Check if session spans across sleep time
        let sessionDuration = endTime.timeIntervalSince(startTime)
        
        // If session is longer than 8 hours, it likely spans sleep time
        if sessionDuration > 8 * 3600 {
            return true
        }
        
        // Check if session overlaps with lunch break
        if userSettings.isWithinLunchBreak(startTime) || userSettings.isWithinLunchBreak(endTime) {
            return true
        }
        
        return false
    }
    
    private func getUserSettings() -> UserSettings {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try viewContext.fetch(request)
            if let userSettings = settings.first {
                return userSettings
            } else {
                // Create default settings if none exist
                let defaultSettings = UserSettings.createDefaultSettings(in: viewContext)
                try viewContext.save()
                return defaultSettings
            }
        } catch {
            print("FocusManager: Error fetching user settings - \(error)")
            // Return default settings in case of error
            return UserSettings.createDefaultSettings(in: viewContext)
        }
    }
    
    func calculateTodaysFocusTime() {
        let today = Date()
        let stats = getFocusStatistics(for: today)
        
        DispatchQueue.main.async {
            self.todaysFocusTime = stats.totalFocusTime
        }
    }
    
    func validateSession(startTime: Date, endTime: Date, duration: TimeInterval) -> Bool {
        return validateFocusSession(startTime: startTime, endTime: endTime, duration: duration)
    }
}