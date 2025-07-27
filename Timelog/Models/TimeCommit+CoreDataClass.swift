import Foundation
import CoreData

@objc(TimeCommit)
public class TimeCommit: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Generate a unique commit hash based on time and content
    var generatedCommitHash: String {
        guard let createdAt = createdAt else { return UUID().uuidString.prefix(8).lowercased() }
        let timeString = String(Int(createdAt.timeIntervalSince1970))
        let messageHash = commitMessage?.hash ?? 0
        return "\(timeString.suffix(4))\(String(abs(messageHash)).prefix(4))".lowercased()
    }
    
    /// Focus quality based on intensity score
    var focusQuality: FocusQuality {
        switch focusIntensity {
        case 0.8...1.0: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        case 0.2..<0.4: return .poor
        default: return .veryPoor
        }
    }
    
    /// Formatted focus intensity for display
    var formattedFocusIntensity: String {
        return String(format: "%.1f%%", focusIntensity * 100)
    }
    
    /// Formatted quality score for display
    var formattedQualityScore: String {
        return String(format: "%.1f", qualityScore)
    }
    
    /// Check if this is a high-quality commit
    var isHighQuality: Bool {
        return focusIntensity >= 0.7 && interruptionCount <= 2
    }
    
    // MARK: - Convenience Methods
    
    /// Create a new time commit with the given parameters
    static func create(in context: NSManagedObjectContext,
                      timeBlock: TimeBlock,
                      commitMessage: String,
                      focusIntensity: Double = 0.5,
                      interruptionCount: Int32 = 0,
                      isBeautifulMoment: Bool = false) -> TimeCommit {
        let commit = TimeCommit(context: context)
        commit.id = UUID()
        commit.timeBlock = timeBlock
        commit.commitMessage = commitMessage
        commit.focusIntensity = focusIntensity
        commit.interruptionCount = interruptionCount
        commit.isBeautifulMoment = isBeautifulMoment
        commit.createdAt = Date()
        commit.commitHash = commit.generatedCommitHash
        commit.qualityScore = commit.calculateQualityScore()
        return commit
    }
    
    /// Calculate quality score based on focus intensity and interruptions
    func calculateQualityScore() -> Double {
        let baseScore = focusIntensity * 10.0
        let interruptionPenalty = Double(interruptionCount) * 0.5
        let beautifulMomentBonus = isBeautifulMoment ? 2.0 : 0.0
        return max(0.0, min(10.0, baseScore - interruptionPenalty + beautifulMomentBonus))
    }
    
    /// Update the commit with new information
    func updateCommit(message: String? = nil, 
                     focusIntensity: Double? = nil,
                     interruptionCount: Int32? = nil,
                     isBeautifulMoment: Bool? = nil) {
        if let message = message {
            self.commitMessage = message
        }
        if let intensity = focusIntensity {
            self.focusIntensity = intensity
        }
        if let interruptions = interruptionCount {
            self.interruptionCount = interruptions
        }
        if let beautiful = isBeautifulMoment {
            self.isBeautifulMoment = beautiful
        }
        
        // Recalculate quality score
        self.qualityScore = calculateQualityScore()
        
        // Update commit hash if message changed
        if message != nil {
            self.commitHash = generatedCommitHash
        }
    }
}

// MARK: - Focus Quality Enum

enum FocusQuality: String, CaseIterable {
    case excellent = "优秀"
    case good = "良好"
    case fair = "一般"
    case poor = "较差"
    case veryPoor = "很差"
    
    var color: String {
        switch self {
        case .excellent: return "#196127" // GitHub深绿色
        case .good: return "#239a3b"      // GitHub中绿色
        case .fair: return "#7bc96f"      // GitHub浅绿色
        case .poor: return "#c6e48b"      // GitHub很浅绿色
        case .veryPoor: return "#ebedf0"  // GitHub灰色
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "专注度极高，几乎无干扰"
        case .good: return "专注度良好，偶有干扰"
        case .fair: return "专注度一般，有一些干扰"
        case .poor: return "专注度较差，干扰较多"
        case .veryPoor: return "专注度很差，干扰频繁"
        }
    }
}