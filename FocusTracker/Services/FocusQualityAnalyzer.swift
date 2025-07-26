import Foundation
import CoreData

/// 专注质量分析数据结构
struct FocusQualityMetrics {
    let date: Date
    let deepFocusTime: TimeInterval      // 连续30分钟以上的专注块
    let mediumFocusTime: TimeInterval    // 15-30分钟的中等专注块
    let fragmentedTime: TimeInterval     // 15分钟以下的碎片时间
    let interruptionCount: Int           // 打断次数
    let averageRecoveryTime: TimeInterval // 平均恢复时间
    let focusQualityScore: Double        // 专注质量评分 (0-100)
    let longestFocusStreak: TimeInterval // 最长连续专注时间
}

/// 打断分析数据
struct InterruptionAnalysis {
    let totalInterruptions: Int
    let averageInterruptionDuration: TimeInterval
    let mostCommonInterruptionHour: Int
    let interruptionRecoveryRate: Double // 打断后成功恢复专注的比率
    let interruptionsByType: [String: Int] // 按类型分类的打断次数
}

/// 专注时段分析
struct FocusTimeSlotAnalysis {
    let bestFocusHours: [Int]           // 最佳专注时段
    let worstFocusHours: [Int]          // 最差专注时段
    let morningFocusScore: Double       // 上午专注评分
    let afternoonFocusScore: Double     // 下午专注评分
    let eveningFocusScore: Double       // 晚上专注评分
}

/// 专注质量分析器
class FocusQualityAnalyzer: ObservableObject {
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    /// 分析指定日期的专注质量
    func analyzeFocusQuality(for date: Date) -> FocusQualityMetrics {
        let sessions = getFocusSessions(for: date)
        
        var deepFocusTime: TimeInterval = 0
        var mediumFocusTime: TimeInterval = 0
        var fragmentedTime: TimeInterval = 0
        var longestStreak: TimeInterval = 0
        
        // 分析每个会话的时长类型
        for session in sessions {
            let duration = session.duration
            longestStreak = max(longestStreak, duration)
            
            if duration >= 30 * 60 { // 30分钟以上
                deepFocusTime += duration
            } else if duration >= 15 * 60 { // 15-30分钟
                mediumFocusTime += duration
            } else { // 15分钟以下
                fragmentedTime += duration
            }
        }
        
        // 计算打断次数（基于会话间隔）
        let interruptions = calculateInterruptions(from: sessions)
        let recoveryTime = calculateAverageRecoveryTime(from: sessions)
        
        // 计算专注质量评分
        let qualityScore = calculateFocusQualityScore(
            deepFocus: deepFocusTime,
            mediumFocus: mediumFocusTime,
            fragmented: fragmentedTime,
            interruptions: interruptions.count
        )
        
        return FocusQualityMetrics(
            date: date,
            deepFocusTime: deepFocusTime,
            mediumFocusTime: mediumFocusTime,
            fragmentedTime: fragmentedTime,
            interruptionCount: interruptions.count,
            averageRecoveryTime: recoveryTime,
            focusQualityScore: qualityScore,
            longestFocusStreak: longestStreak
        )
    }
    
    /// 分析打断模式
    func analyzeInterruptions(for date: Date) -> InterruptionAnalysis {
        let sessions = getFocusSessions(for: date)
        let interruptions = calculateInterruptions(from: sessions)
        
        // 分析打断发生的时间段
        var hourlyInterruptions: [Int: Int] = [:]
        for interruption in interruptions {
            let hour = Calendar.current.component(.hour, from: interruption.startTime)
            hourlyInterruptions[hour, default: 0] += 1
        }
        
        let mostCommonHour = hourlyInterruptions.max { $0.value < $1.value }?.key ?? 12
        
        // 计算恢复率（打断后15分钟内重新开始专注的比率）
        let recoveryRate = calculateRecoveryRate(from: interruptions, sessions: sessions)
        
        return InterruptionAnalysis(
            totalInterruptions: interruptions.count,
            averageInterruptionDuration: interruptions.isEmpty ? 0 : 
                interruptions.reduce(0) { $0 + $1.duration } / Double(interruptions.count),
            mostCommonInterruptionHour: mostCommonHour,
            interruptionRecoveryRate: recoveryRate,
            interruptionsByType: categorizeInterruptions(interruptions)
        )
    }
    
    /// 分析最佳专注时段
    func analyzeFocusTimeSlots(for period: DateInterval) -> FocusTimeSlotAnalysis {
        var hourlyFocusScores: [Int: [Double]] = [:]
        
        let calendar = Calendar.current
        var currentDate = period.start
        
        while currentDate < period.end {
            let dayMetrics = analyzeFocusQuality(for: currentDate)
            let sessions = getFocusSessions(for: currentDate)
            
            // 为每个小时计算专注评分
            for hour in 0..<24 {
                let hourSessions = sessions.filter { session in
                    let sessionHour = calendar.component(.hour, from: session.startTime)
                    return sessionHour == hour
                }
                
                let hourScore = calculateHourlyFocusScore(sessions: hourSessions)
                hourlyFocusScores[hour, default: []].append(hourScore)
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? period.end
        }
        
        // 计算每小时的平均评分
        var averageHourlyScores: [Int: Double] = [:]
        for (hour, scores) in hourlyFocusScores {
            averageHourlyScores[hour] = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        }
        
        // 找出最佳和最差时段
        let sortedHours = averageHourlyScores.sorted { $0.value > $1.value }
        let bestHours = Array(sortedHours.prefix(3).map { $0.key })
        let worstHours = Array(sortedHours.suffix(3).map { $0.key })
        
        // 计算时段评分
        let morningScore = (6..<12).compactMap { averageHourlyScores[$0] }.reduce(0, +) / 6
        let afternoonScore = (12..<18).compactMap { averageHourlyScores[$0] }.reduce(0, +) / 6
        let eveningScore = (18..<22).compactMap { averageHourlyScores[$0] }.reduce(0, +) / 4
        
        return FocusTimeSlotAnalysis(
            bestFocusHours: bestHours,
            worstFocusHours: worstHours,
            morningFocusScore: morningScore,
            afternoonFocusScore: afternoonScore,
            eveningFocusScore: eveningScore
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func getFocusSessions(for date: Date) -> [FocusSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "startTime >= %@ AND startTime < %@ AND isValid == YES",
            startOfDay as NSDate, endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.startTime, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching focus sessions: \(error)")
            return []
        }
    }
    
    private func calculateInterruptions(from sessions: [FocusSession]) -> [(startTime: Date, duration: TimeInterval)] {
        var interruptions: [(startTime: Date, duration: TimeInterval)] = []
        
        for i in 0..<sessions.count - 1 {
            let currentSession = sessions[i]
            let nextSession = sessions[i + 1]
            
            let gap = nextSession.startTime.timeIntervalSince(currentSession.endTime ?? currentSession.startTime)
            
            // 如果间隔在5分钟到2小时之间，认为是打断
            if gap > 5 * 60 && gap < 2 * 3600 {
                interruptions.append((
                    startTime: currentSession.endTime ?? currentSession.startTime,
                    duration: gap
                ))
            }
        }
        
        return interruptions
    }
    
    private func calculateAverageRecoveryTime(from sessions: [FocusSession]) -> TimeInterval {
        let interruptions = calculateInterruptions(from: sessions)
        guard !interruptions.isEmpty else { return 0 }
        
        return interruptions.reduce(0) { $0 + $1.duration } / Double(interruptions.count)
    }
    
    private func calculateFocusQualityScore(deepFocus: TimeInterval, mediumFocus: TimeInterval, 
                                          fragmented: TimeInterval, interruptions: Int) -> Double {
        let totalTime = deepFocus + mediumFocus + fragmented
        guard totalTime > 0 else { return 0 }
        
        // 权重：深度专注 70%，中等专注 20%，碎片时间 -10%，打断次数 -20%
        let deepFocusScore = (deepFocus / totalTime) * 70
        let mediumFocusScore = (mediumFocus / totalTime) * 20
        let fragmentedPenalty = (fragmented / totalTime) * 10
        let interruptionPenalty = min(Double(interruptions) * 5, 20) // 最多扣20分
        
        let score = deepFocusScore + mediumFocusScore - fragmentedPenalty - interruptionPenalty
        return max(0, min(100, score))
    }
    
    private func calculateRecoveryRate(from interruptions: [(startTime: Date, duration: TimeInterval)], 
                                     sessions: [FocusSession]) -> Double {
        guard !interruptions.isEmpty else { return 1.0 }
        
        var successfulRecoveries = 0
        
        for interruption in interruptions {
            let recoveryWindow = interruption.startTime.addingTimeInterval(interruption.duration + 15 * 60)
            
            // 检查是否在恢复窗口内有新的专注会话
            let hasRecovery = sessions.contains { session in
                session.startTime >= interruption.startTime.addingTimeInterval(interruption.duration) &&
                session.startTime <= recoveryWindow
            }
            
            if hasRecovery {
                successfulRecoveries += 1
            }
        }
        
        return Double(successfulRecoveries) / Double(interruptions.count)
    }
    
    private func categorizeInterruptions(_ interruptions: [(startTime: Date, duration: TimeInterval)]) -> [String: Int] {
        var categories: [String: Int] = [:]
        
        for interruption in interruptions {
            let duration = interruption.duration
            
            if duration < 10 * 60 { // 10分钟以下
                categories["短暂打断", default: 0] += 1
            } else if duration < 30 * 60 { // 10-30分钟
                categories["中等打断", default: 0] += 1
            } else { // 30分钟以上
                categories["长时间打断", default: 0] += 1
            }
        }
        
        return categories
    }
    
    private func calculateHourlyFocusScore(sessions: [FocusSession]) -> Double {
        guard !sessions.isEmpty else { return 0 }
        
        let totalTime = sessions.reduce(0) { $0 + $1.duration }
        let averageSessionLength = totalTime / Double(sessions.count)
        let sessionCount = sessions.count
        
        // 基于平均会话长度和会话数量计算评分
        let lengthScore = min(averageSessionLength / (45 * 60), 1.0) * 60 // 45分钟为满分
        let consistencyScore = min(Double(sessionCount) / 3.0, 1.0) * 40 // 3个会话为满分
        
        return lengthScore + consistencyScore
    }
}