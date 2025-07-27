import Foundation

/// FocusIntensityCalculator - 专注强度计算器
/// 基于多种因素计算用户的专注强度，模拟代码质量评分系统
struct FocusIntensityCalculator {
    
    // MARK: - Configuration
    
    private struct Config {
        static let optimalSessionDuration: TimeInterval = 25 * 60 // 25分钟（番茄工作法）
        static let maxSessionDuration: TimeInterval = 90 * 60     // 90分钟
        static let interruptionPenalty: Double = 0.15             // 每次中断的惩罚
        static let recoveryTime: TimeInterval = 5 * 60            // 中断后的恢复时间
        static let fatigueThreshold: TimeInterval = 60 * 60       // 疲劳阈值（1小时）
    }
    
    // MARK: - Public Methods
    
    /// 计算实时专注强度
    /// - Parameters:
    ///   - sessionDuration: 当前会话持续时间
    ///   - interruptionCount: 中断次数
    ///   - timeSinceLastInterruption: 距离上次中断的时间
    ///   - timeOfDay: 当前时间（用于计算生物钟影响）
    /// - Returns: 专注强度 (0.0 - 1.0)
    static func calculateRealTimeFocusIntensity(
        sessionDuration: TimeInterval,
        interruptionCount: Int32,
        timeSinceLastInterruption: TimeInterval,
        timeOfDay: Date = Date()
    ) -> Double {
        
        // 1. 基础专注强度（基于会话持续时间）
        let baseIntensity = calculateBaseIntensity(duration: sessionDuration)
        
        // 2. 中断惩罚
        let interruptionPenalty = calculateInterruptionPenalty(
            count: interruptionCount,
            timeSinceLastInterruption: timeSinceLastInterruption
        )
        
        // 3. 生物钟影响
        let circadianBonus = calculateCircadianRhythmBonus(timeOfDay: timeOfDay)
        
        // 4. 疲劳影响
        let fatigueEffect = calculateFatigueEffect(duration: sessionDuration)
        
        // 综合计算
        let finalIntensity = baseIntensity - interruptionPenalty + circadianBonus - fatigueEffect
        
        return max(0.1, min(1.0, finalIntensity))
    }
    
    /// 计算会话结束时的最终专注强度
    /// - Parameters:
    ///   - sessionData: 会话数据
    /// - Returns: 最终专注强度评分
    static func calculateFinalFocusIntensity(sessionData: SessionAnalysisData) -> Double {
        let realTimeIntensity = calculateRealTimeFocusIntensity(
            sessionDuration: sessionData.totalDuration,
            interruptionCount: Int32(sessionData.interruptions.count),
            timeSinceLastInterruption: sessionData.timeSinceLastInterruption,
            timeOfDay: sessionData.endTime
        )
        
        // 考虑会话完整性
        let completionBonus = calculateCompletionBonus(sessionData: sessionData)
        
        // 考虑专注强度的稳定性
        let stabilityBonus = calculateStabilityBonus(intensityHistory: sessionData.intensityHistory)
        
        let finalScore = realTimeIntensity + completionBonus + stabilityBonus
        
        return max(0.0, min(1.0, finalScore))
    }
    
    /// 计算专注质量等级
    /// - Parameter intensity: 专注强度
    /// - Returns: 专注质量等级
    static func getFocusQuality(intensity: Double) -> FocusQuality {
        switch intensity {
        case 0.9...1.0:
            return .excellent
        case 0.75..<0.9:
            return .good
        case 0.5..<0.75:
            return .fair
        case 0.25..<0.5:
            return .poor
        default:
            return .veryPoor
        }
    }
    
    /// 生成专注强度建议
    /// - Parameter sessionData: 会话数据
    /// - Returns: 改进建议
    static func generateFocusImprovementSuggestions(sessionData: SessionAnalysisData) -> [FocusImprovementSuggestion] {
        var suggestions: [FocusImprovementSuggestion] = []
        
        // 基于中断次数的建议
        if sessionData.interruptions.count > 3 {
            suggestions.append(.reduceInterruptions)
        }
        
        // 基于会话时长的建议
        if sessionData.totalDuration < 10 * 60 {
            suggestions.append(.extendSessionDuration)
        } else if sessionData.totalDuration > Config.maxSessionDuration {
            suggestions.append(.takeBreaks)
        }
        
        // 基于时间段的建议
        let hour = Calendar.current.component(.hour, from: sessionData.startTime)
        if hour < 9 || hour > 17 {
            suggestions.append(.optimizeTimeOfDay)
        }
        
        // 基于专注强度变化的建议
        if let intensityTrend = analyzeIntensityTrend(sessionData.intensityHistory) {
            switch intensityTrend {
            case .declining:
                suggestions.append(.improveEnvironment)
            case .unstable:
                suggestions.append(.establishRoutine)
            case .stable:
                break // 无需建议
            }
        }
        
        return suggestions
    }
    
    // MARK: - Private Methods
    
    /// 计算基础专注强度（基于时间的专注曲线）
    private static func calculateBaseIntensity(duration: TimeInterval) -> Double {
        let minutes = duration / 60.0
        
        // 基于研究的专注强度曲线
        switch minutes {
        case 0..<2:
            // 启动阶段：逐渐进入状态
            return 0.3 + (minutes / 2.0) * 0.3 // 0.3 -> 0.6
            
        case 2..<10:
            // 上升阶段：专注度快速提升
            return 0.6 + ((minutes - 2) / 8.0) * 0.25 // 0.6 -> 0.85
            
        case 10..<25:
            // 黄金时段：保持高专注
            return 0.85 + ((minutes - 10) / 15.0) * 0.1 // 0.85 -> 0.95
            
        case 25..<45:
            // 持续阶段：轻微下降但仍然良好
            return 0.95 - ((minutes - 25) / 20.0) * 0.15 // 0.95 -> 0.8
            
        case 45..<60:
            // 疲劳开始：明显下降
            return 0.8 - ((minutes - 45) / 15.0) * 0.25 // 0.8 -> 0.55
            
        case 60..<90:
            // 疲劳阶段：持续下降
            return 0.55 - ((minutes - 60) / 30.0) * 0.2 // 0.55 -> 0.35
            
        default:
            // 过度疲劳：需要休息
            return max(0.2, 0.35 - ((minutes - 90) / 60.0) * 0.15)
        }
    }
    
    /// 计算中断惩罚
    private static func calculateInterruptionPenalty(count: Int32, timeSinceLastInterruption: TimeInterval) -> Double {
        let basePenalty = Double(count) * Config.interruptionPenalty
        
        // 如果最近有中断，额外惩罚
        let recentInterruptionPenalty = timeSinceLastInterruption < Config.recoveryTime ? 0.1 : 0.0
        
        return basePenalty + recentInterruptionPenalty
    }
    
    /// 计算生物钟奖励
    private static func calculateCircadianRhythmBonus(timeOfDay: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: timeOfDay)
        
        // 基于一般人的生物钟规律
        switch hour {
        case 9...11:
            return 0.1  // 上午黄金时段
        case 14...16:
            return 0.05 // 下午良好时段
        case 19...21:
            return 0.05 // 晚上学习时段
        case 6...8, 12...13:
            return 0.0  // 中性时段
        default:
            return -0.05 // 非最佳时段
        }
    }
    
    /// 计算疲劳影响
    private static func calculateFatigueEffect(duration: TimeInterval) -> Double {
        guard duration > Config.fatigueThreshold else { return 0.0 }
        
        let excessTime = duration - Config.fatigueThreshold
        return min(0.3, excessTime / (60 * 60) * 0.1) // 每小时额外时间减少0.1
    }
    
    /// 计算完成度奖励
    private static func calculateCompletionBonus(sessionData: SessionAnalysisData) -> Double {
        // 如果会话在理想时长范围内完成，给予奖励
        let duration = sessionData.totalDuration
        if duration >= 20 * 60 && duration <= 30 * 60 {
            return 0.05
        }
        return 0.0
    }
    
    /// 计算稳定性奖励
    private static func calculateStabilityBonus(intensityHistory: [FocusIntensityPoint]) -> Double {
        guard intensityHistory.count >= 3 else { return 0.0 }
        
        // 计算专注强度的标准差
        let intensities = intensityHistory.map { $0.intensity }
        let average = intensities.reduce(0, +) / Double(intensities.count)
        let variance = intensities.map { pow($0 - average, 2) }.reduce(0, +) / Double(intensities.count)
        let standardDeviation = sqrt(variance)
        
        // 标准差越小，稳定性越好
        return max(0.0, 0.1 - standardDeviation)
    }
    
    /// 分析专注强度趋势
    private static func analyzeIntensityTrend(_ history: [FocusIntensityPoint]) -> IntensityTrend? {
        guard history.count >= 3 else { return nil }
        
        let recentPoints = Array(history.suffix(3))
        let intensities = recentPoints.map { $0.intensity }
        
        let firstHalf = intensities.prefix(intensities.count / 2)
        let secondHalf = intensities.suffix(intensities.count / 2)
        
        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let difference = secondAvg - firstAvg
        
        if difference < -0.1 {
            return .declining
        } else if abs(difference) > 0.15 {
            return .unstable
        } else {
            return .stable
        }
    }
}

// MARK: - Supporting Types

/// 会话分析数据
struct SessionAnalysisData {
    let startTime: Date
    let endTime: Date
    let totalDuration: TimeInterval
    let interruptions: [SessionInterruption]
    let intensityHistory: [FocusIntensityPoint]
    
    var timeSinceLastInterruption: TimeInterval {
        guard let lastInterruption = interruptions.last else {
            return totalDuration
        }
        return endTime.timeIntervalSince(lastInterruption.timestamp)
    }
}

/// 专注强度趋势
enum IntensityTrend {
    case declining  // 下降
    case unstable   // 不稳定
    case stable     // 稳定
}

/// 专注改进建议
enum FocusImprovementSuggestion: String, CaseIterable {
    case reduceInterruptions = "减少中断，尝试关闭通知或使用专注模式"
    case extendSessionDuration = "延长专注时间，建议至少保持20分钟"
    case takeBreaks = "适当休息，长时间专注会降低效率"
    case optimizeTimeOfDay = "选择更适合的时间段，如上午9-11点"
    case improveEnvironment = "改善专注环境，减少外界干扰"
    case establishRoutine = "建立固定的专注习惯和流程"
    
    var icon: String {
        switch self {
        case .reduceInterruptions: return "🔕"
        case .extendSessionDuration: return "⏱️"
        case .takeBreaks: return "☕"
        case .optimizeTimeOfDay: return "🌅"
        case .improveEnvironment: return "🏠"
        case .establishRoutine: return "📋"
        }
    }
    
    var priority: Int {
        switch self {
        case .reduceInterruptions: return 1
        case .extendSessionDuration: return 2
        case .improveEnvironment: return 3
        case .establishRoutine: return 4
        case .optimizeTimeOfDay: return 5
        case .takeBreaks: return 6
        }
    }
}