import Foundation
import CoreData
import Combine
import UIKit

/// LifeCommitManager - 人生提交管理器
/// 负责管理时间块的创建、提交和专注强度计算
/// 将人生时间使用比作Git提交记录的核心服务
@MainActor
class LifeCommitManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentSession: ActiveTimeSession?
    @Published var isTracking: Bool = false
    @Published var sessionStartTime: Date?
    @Published var currentFocusIntensity: Double = 0.0
    @Published var interruptionCount: Int32 = 0
    
    // MARK: - Private Properties
    
    private let viewContext: NSManagedObjectContext
    private let userSettings: UserSettings
    private var focusTimer: Timer?
    private var intensityUpdateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        self.userSettings = UserSettings.getOrCreate(in: viewContext)
        
        setupFocusMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// 开始一个新的时间提交会话
    func startCommitSession(activity: String? = nil) {
        guard !isTracking else {
            print("⚠️ 已有活跃的提交会话正在进行")
            return
        }
        
        let startTime = Date()
        sessionStartTime = startTime
        isTracking = true
        interruptionCount = 0
        currentFocusIntensity = 0.5 // 初始专注强度
        
        // 创建活跃会话
        currentSession = ActiveTimeSession(
            startTime: startTime,
            activity: activity,
            initialFocusIntensity: currentFocusIntensity
        )
        
        // 开始专注强度监控
        startFocusIntensityMonitoring()
        
        print("🚀 开始新的人生提交会话: \(startTime)")
    }
    
    /// 结束当前的时间提交会话并创建提交记录
    func endCommitSession(commitMessage: String, isBeautifulMoment: Bool = false) -> TimeCommit? {
        guard isTracking, 
              let session = currentSession,
              let startTime = sessionStartTime else {
            print("⚠️ 没有活跃的提交会话")
            return nil
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // 停止监控
        stopFocusIntensityMonitoring()
        
        // 创建时间块
        let timeBlock = TimeBlock.create(
            in: viewContext,
            startTime: startTime,
            endTime: endTime,
            activity: session.activity,
            category: session.category
        )
        
        // 创建提交记录
        let commit = timeBlock.addCommit(
            message: commitMessage,
            focusIntensity: currentFocusIntensity,
            interruptionCount: interruptionCount,
            isBeautifulMoment: isBeautifulMoment
        )
        
        // 保存到Core Data
        do {
            try viewContext.save()
            print("✅ 人生提交完成: \(commit.commitHash ?? "unknown") - \(commitMessage)")
        } catch {
            print("❌ 保存提交记录失败: \(error)")
            return nil
        }
        
        // 重置状态
        resetSession()
        
        return commit
    }
    
    /// 暂停当前会话（用于处理中断）
    func pauseSession(reason: String) {
        guard isTracking else { return }
        
        interruptionCount += 1
        currentFocusIntensity = max(0.1, currentFocusIntensity - 0.1) // 降低专注强度
        
        currentSession?.addInterruption(reason: reason, at: Date())
        
        print("⏸️ 会话暂停: \(reason) (中断次数: \(interruptionCount))")
    }
    
    /// 恢复当前会话
    func resumeSession() {
        guard isTracking else { return }
        
        currentSession?.resumeFromInterruption(at: Date())
        
        // 逐渐恢复专注强度
        startFocusRecovery()
        
        print("▶️ 会话恢复")
    }
    
    /// 取消当前会话
    func cancelSession() {
        guard isTracking else { return }
        
        stopFocusIntensityMonitoring()
        resetSession()
        
        print("❌ 会话已取消")
    }
    
    /// 更新当前会话的活动信息
    func updateSessionActivity(_ activity: String, category: String? = nil) {
        currentSession?.activity = activity
        currentSession?.category = category
    }
    
    /// 手动调整专注强度
    func adjustFocusIntensity(_ intensity: Double) {
        currentFocusIntensity = max(0.0, min(1.0, intensity))
        currentSession?.updateFocusIntensity(currentFocusIntensity)
    }
    
    /// 获取当前会话的持续时间
    func getCurrentSessionDuration() -> TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    /// 获取当前会话的格式化持续时间
    func getFormattedSessionDuration() -> String {
        let duration = getCurrentSessionDuration()
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Analytics Methods
    
    /// 计算今日的提交统计
    func getTodayCommitStats() -> DailyCommitStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let request: NSFetchRequest<TimeCommit> = TimeCommit.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", today as NSDate, tomorrow as NSDate)
        
        do {
            let commits = try viewContext.fetch(request)
            return DailyCommitStats(commits: commits)
        } catch {
            print("❌ 获取今日提交统计失败: \(error)")
            return DailyCommitStats(commits: [])
        }
    }
    
    /// 获取最近的提交记录
    func getRecentCommits(limit: Int = 10) -> [TimeCommit] {
        let request: NSFetchRequest<TimeCommit> = TimeCommit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeCommit.createdAt, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("❌ 获取最近提交记录失败: \(error)")
            return []
        }
    }
    
    // MARK: - Private Methods
    
    private func setupFocusMonitoring() {
        // 监听应用状态变化
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.pauseSession(reason: "应用进入后台")
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                if self?.isTracking == true {
                    self?.resumeSession()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startFocusIntensityMonitoring() {
        // 每30秒更新一次专注强度
        intensityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateFocusIntensity()
        }
    }
    
    private func stopFocusIntensityMonitoring() {
        intensityUpdateTimer?.invalidate()
        intensityUpdateTimer = nil
    }
    
    private func updateFocusIntensity() {
        // 基于会话持续时间和中断次数计算专注强度
        let sessionDuration = getCurrentSessionDuration()
        let baseIntensity = calculateBaseIntensity(duration: sessionDuration)
        let interruptionPenalty = Double(interruptionCount) * 0.1
        
        currentFocusIntensity = max(0.1, min(1.0, baseIntensity - interruptionPenalty))
        currentSession?.updateFocusIntensity(currentFocusIntensity)
    }
    
    private func calculateBaseIntensity(duration: TimeInterval) -> Double {
        // 专注强度随时间的变化曲线
        let minutes = duration / 60.0
        
        switch minutes {
        case 0..<5:
            return 0.3 + (minutes / 5.0) * 0.4 // 0.3 -> 0.7
        case 5..<25:
            return 0.7 + ((minutes - 5) / 20.0) * 0.2 // 0.7 -> 0.9
        case 25..<45:
            return 0.9 // 保持高专注
        case 45..<60:
            return 0.9 - ((minutes - 45) / 15.0) * 0.3 // 0.9 -> 0.6
        default:
            return max(0.4, 0.6 - ((minutes - 60) / 60.0) * 0.2) // 逐渐下降
        }
    }
    
    private func startFocusRecovery() {
        // 恢复后逐渐提升专注强度
        let recoveryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isTracking else {
                timer.invalidate()
                return
            }
            
            self.currentFocusIntensity = min(0.8, self.currentFocusIntensity + 0.1)
            
            if self.currentFocusIntensity >= 0.7 {
                timer.invalidate()
            }
        }
        
        // 60秒后自动停止恢复
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            recoveryTimer.invalidate()
        }
    }
    
    private func resetSession() {
        isTracking = false
        sessionStartTime = nil
        currentSession = nil
        currentFocusIntensity = 0.0
        interruptionCount = 0
    }
}

// MARK: - Supporting Types

/// 活跃时间会话
class ActiveTimeSession: ObservableObject {
    let id = UUID()
    let startTime: Date
    var activity: String?
    var category: String?
    var interruptions: [SessionInterruption] = []
    var focusIntensityHistory: [FocusIntensityPoint] = []
    
    init(startTime: Date, activity: String? = nil, initialFocusIntensity: Double = 0.5) {
        self.startTime = startTime
        self.activity = activity
        self.focusIntensityHistory.append(
            FocusIntensityPoint(timestamp: startTime, intensity: initialFocusIntensity)
        )
    }
    
    func addInterruption(reason: String, at timestamp: Date) {
        interruptions.append(SessionInterruption(reason: reason, timestamp: timestamp))
    }
    
    func resumeFromInterruption(at timestamp: Date) {
        if let lastInterruption = interruptions.last {
            lastInterruption.resumeTime = timestamp
        }
    }
    
    func updateFocusIntensity(_ intensity: Double) {
        focusIntensityHistory.append(
            FocusIntensityPoint(timestamp: Date(), intensity: intensity)
        )
    }
    
    var averageFocusIntensity: Double {
        guard !focusIntensityHistory.isEmpty else { return 0.0 }
        let total = focusIntensityHistory.reduce(0.0) { $0 + $1.intensity }
        return total / Double(focusIntensityHistory.count)
    }
}

/// 会话中断记录
class SessionInterruption {
    let reason: String
    let timestamp: Date
    var resumeTime: Date?
    
    init(reason: String, timestamp: Date) {
        self.reason = reason
        self.timestamp = timestamp
    }
    
    var duration: TimeInterval? {
        guard let resumeTime = resumeTime else { return nil }
        return resumeTime.timeIntervalSince(timestamp)
    }
}

/// 专注强度记录点
struct FocusIntensityPoint {
    let timestamp: Date
    let intensity: Double
}

/// 每日提交统计
struct DailyCommitStats {
    let totalCommits: Int
    let totalFocusTime: TimeInterval
    let averageFocusIntensity: Double
    let beautifulMomentsCount: Int
    let totalInterruptions: Int32
    let highQualityCommitsCount: Int
    
    init(commits: [TimeCommit]) {
        self.totalCommits = commits.count
        self.totalFocusTime = commits.compactMap { $0.timeBlock?.duration }.reduce(0, +)
        self.averageFocusIntensity = commits.isEmpty ? 0.0 : commits.reduce(0.0) { $0 + $1.focusIntensity } / Double(commits.count)
        self.beautifulMomentsCount = commits.filter { $0.isBeautifulMoment }.count
        self.totalInterruptions = commits.reduce(0) { $0 + $1.interruptionCount }
        self.highQualityCommitsCount = commits.filter { $0.isHighQuality }.count
    }
    
    var formattedTotalFocusTime: String {
        let hours = Int(totalFocusTime) / 3600
        let minutes = Int(totalFocusTime.truncatingRemainder(dividingBy: 3600)) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    var qualityScore: Double {
        guard totalCommits > 0 else { return 0.0 }
        return (averageFocusIntensity * 0.6) + (Double(highQualityCommitsCount) / Double(totalCommits) * 0.4)
    }
}