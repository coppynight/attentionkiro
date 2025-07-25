import SwiftUI
import Combine

/// Coordinates the onboarding experience for new and existing users
class OnboardingCoordinator: ObservableObject {
    static let shared = OnboardingCoordinator()
    
    // MARK: - Published Properties
    
    @Published var shouldShowOnboarding: Bool = false
    @Published var currentOnboardingStep: OnboardingStep = .welcome
    @Published var hasCompletedInitialOnboarding: Bool = false
    @Published var hasSeenNewFeatures: Bool = false
    @Published var onboardingProgress: Double = 0.0
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // UserDefaults keys
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let hasSeenNewFeaturesKey = "hasSeenNewFeatures_v2.0"
    private let appVersionKey = "lastSeenAppVersion"
    
    // MARK: - Initialization
    
    private init() {
        loadOnboardingState()
        checkForNewFeatures()
    }
    
    // MARK: - Public Methods
    
    /// Starts the onboarding flow
    func startOnboarding() {
        currentOnboardingStep = .welcome
        shouldShowOnboarding = true
        updateProgress()
    }
    
    /// Advances to the next onboarding step
    func nextStep() {
        switch currentOnboardingStep {
        case .welcome:
            currentOnboardingStep = .focusTracking
        case .focusTracking:
            currentOnboardingStep = .timeAnalysis
        case .timeAnalysis:
            currentOnboardingStep = .sceneTags
        case .sceneTags:
            currentOnboardingStep = .notifications
        case .notifications:
            currentOnboardingStep = .completion
        case .completion:
            completeOnboarding()
        }
        updateProgress()
    }
    
    /// Goes back to the previous onboarding step
    func previousStep() {
        switch currentOnboardingStep {
        case .welcome:
            break // Can't go back from welcome
        case .focusTracking:
            currentOnboardingStep = .welcome
        case .timeAnalysis:
            currentOnboardingStep = .focusTracking
        case .sceneTags:
            currentOnboardingStep = .timeAnalysis
        case .notifications:
            currentOnboardingStep = .sceneTags
        case .completion:
            currentOnboardingStep = .notifications
        }
        updateProgress()
    }
    
    /// Skips the current onboarding step
    func skipStep() {
        nextStep()
    }
    
    /// Completes the onboarding process
    func completeOnboarding() {
        hasCompletedInitialOnboarding = true
        shouldShowOnboarding = false
        
        userDefaults.set(true, forKey: hasCompletedOnboardingKey)
        userDefaults.set(getCurrentAppVersion(), forKey: appVersionKey)
        
        // Send completion analytics
        sendOnboardingCompletionAnalytics()
    }
    
    /// Shows new features introduction for existing users
    func showNewFeaturesIntroduction() {
        currentOnboardingStep = .timeAnalysis // Start with new features
        shouldShowOnboarding = true
        updateProgress()
    }
    
    /// Marks new features as seen
    func markNewFeaturesAsSeen() {
        hasSeenNewFeatures = true
        userDefaults.set(true, forKey: hasSeenNewFeaturesKey)
    }
    
    /// Resets onboarding state (for testing/debugging)
    func resetOnboarding() {
        hasCompletedInitialOnboarding = false
        hasSeenNewFeatures = false
        shouldShowOnboarding = false
        currentOnboardingStep = .welcome
        
        userDefaults.removeObject(forKey: hasCompletedOnboardingKey)
        userDefaults.removeObject(forKey: hasSeenNewFeaturesKey)
        userDefaults.removeObject(forKey: appVersionKey)
    }
    
    // MARK: - Private Methods
    
    private func loadOnboardingState() {
        hasCompletedInitialOnboarding = userDefaults.bool(forKey: hasCompletedOnboardingKey)
        hasSeenNewFeatures = userDefaults.bool(forKey: hasSeenNewFeaturesKey)
        
        // Show onboarding for new users
        if !hasCompletedInitialOnboarding {
            shouldShowOnboarding = true
        }
    }
    
    private func checkForNewFeatures() {
        let currentVersion = getCurrentAppVersion()
        let lastSeenVersion = userDefaults.string(forKey: appVersionKey) ?? "1.0"
        
        // If user has completed initial onboarding but hasn't seen new features
        if hasCompletedInitialOnboarding && !hasSeenNewFeatures && isNewerVersion(currentVersion, than: lastSeenVersion) {
            // Show new features introduction
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showNewFeaturesIntroduction()
            }
        }
    }
    
    private func updateProgress() {
        let totalSteps = OnboardingStep.allCases.count
        let currentStepIndex = OnboardingStep.allCases.firstIndex(of: currentOnboardingStep) ?? 0
        onboardingProgress = Double(currentStepIndex) / Double(totalSteps - 1)
    }
    
    private func getCurrentAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private func isNewerVersion(_ version1: String, than version2: String) -> Bool {
        return version1.compare(version2, options: .numeric) == .orderedDescending
    }
    
    private func sendOnboardingCompletionAnalytics() {
        // In a real app, you might send this to analytics service
        print("📊 Onboarding completed")
    }
}

// MARK: - Onboarding Steps

enum OnboardingStep: String, CaseIterable, Identifiable {
    case welcome = "welcome"
    case focusTracking = "focus_tracking"
    case timeAnalysis = "time_analysis"
    case sceneTags = "scene_tags"
    case notifications = "notifications"
    case completion = "completion"
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .welcome:
            return "欢迎使用专注追踪"
        case .focusTracking:
            return "专注时间追踪"
        case .timeAnalysis:
            return "时间使用分析"
        case .sceneTags:
            return "场景标签管理"
        case .notifications:
            return "智能通知提醒"
        case .completion:
            return "设置完成"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome:
            return "让我们一起开始您的专注之旅"
        case .focusTracking:
            return "记录和分析您的专注时间"
        case .timeAnalysis:
            return "深入了解您的时间使用模式"
        case .sceneTags:
            return "为不同活动添加标签分类"
        case .notifications:
            return "获得个性化的专注提醒"
        case .completion:
            return "您已准备好开始使用所有功能"
        }
    }
    
    var iconName: String {
        switch self {
        case .welcome:
            return "hand.wave.fill"
        case .focusTracking:
            return "brain.head.profile"
        case .timeAnalysis:
            return "chart.bar.fill"
        case .sceneTags:
            return "tag.fill"
        case .notifications:
            return "bell.fill"
        case .completion:
            return "checkmark.circle.fill"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .welcome:
            return .blue
        case .focusTracking:
            return .green
        case .timeAnalysis:
            return .orange
        case .sceneTags:
            return .purple
        case .notifications:
            return .red
        case .completion:
            return .blue
        }
    }
}

// MARK: - Onboarding Data Models

struct OnboardingFeature {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let isNew: Bool
}

extension OnboardingStep {
    var features: [OnboardingFeature] {
        switch self {
        case .welcome:
            return [
                OnboardingFeature(
                    title: "专注追踪",
                    description: "记录您的专注时间和效率",
                    iconName: "timer",
                    color: .blue,
                    isNew: false
                ),
                OnboardingFeature(
                    title: "时间分析",
                    description: "深入分析您的时间使用模式",
                    iconName: "chart.bar",
                    color: .orange,
                    isNew: true
                ),
                OnboardingFeature(
                    title: "智能标签",
                    description: "为不同活动自动分类标记",
                    iconName: "tag",
                    color: .purple,
                    isNew: true
                )
            ]
            
        case .focusTracking:
            return [
                OnboardingFeature(
                    title: "自动检测",
                    description: "智能识别您的专注状态",
                    iconName: "eye",
                    color: .green,
                    isNew: false
                ),
                OnboardingFeature(
                    title: "时长验证",
                    description: "确保专注时段达到有效标准",
                    iconName: "checkmark.shield",
                    color: .blue,
                    isNew: false
                ),
                OnboardingFeature(
                    title: "目标设定",
                    description: "设置每日专注时间目标",
                    iconName: "target",
                    color: .red,
                    isNew: false
                )
            ]
            
        case .timeAnalysis:
            return [
                OnboardingFeature(
                    title: "使用统计",
                    description: "查看详细的应用使用时间统计",
                    iconName: "chart.pie",
                    color: .orange,
                    isNew: true
                ),
                OnboardingFeature(
                    title: "趋势分析",
                    description: "了解您的时间使用趋势变化",
                    iconName: "chart.line.uptrend.xyaxis",
                    color: .blue,
                    isNew: true
                ),
                OnboardingFeature(
                    title: "效率洞察",
                    description: "获得个性化的效率提升建议",
                    iconName: "lightbulb",
                    color: .yellow,
                    isNew: true
                )
            ]
            
        case .sceneTags:
            return [
                OnboardingFeature(
                    title: "智能推荐",
                    description: "根据应用类型自动推荐标签",
                    iconName: "brain",
                    color: .purple,
                    isNew: true
                ),
                OnboardingFeature(
                    title: "自定义标签",
                    description: "创建符合您需求的个性化标签",
                    iconName: "plus.circle",
                    color: .green,
                    isNew: true
                ),
                OnboardingFeature(
                    title: "分类统计",
                    description: "按标签查看时间分布统计",
                    iconName: "chart.bar.doc.horizontal",
                    color: .orange,
                    isNew: true
                )
            ]
            
        case .notifications:
            return [
                OnboardingFeature(
                    title: "专注提醒",
                    description: "在合适的时间提醒您开始专注",
                    iconName: "bell.badge",
                    color: .red,
                    isNew: false
                ),
                OnboardingFeature(
                    title: "休息建议",
                    description: "智能建议休息时间和方式",
                    iconName: "moon",
                    color: .indigo,
                    isNew: false
                ),
                OnboardingFeature(
                    title: "成就通知",
                    description: "庆祝您的专注成就和里程碑",
                    iconName: "trophy",
                    color: .yellow,
                    isNew: false
                )
            ]
            
        case .completion:
            return [
                OnboardingFeature(
                    title: "开始使用",
                    description: "所有功能已准备就绪",
                    iconName: "play.circle",
                    color: .green,
                    isNew: false
                ),
                OnboardingFeature(
                    title: "探索更多",
                    description: "在使用中发现更多实用功能",
                    iconName: "safari",
                    color: .blue,
                    isNew: false
                ),
                OnboardingFeature(
                    title: "获得帮助",
                    description: "随时在设置中查看帮助信息",
                    iconName: "questionmark.circle",
                    color: .gray,
                    isNew: false
                )
            ]
        }
    }
}

// MARK: - Onboarding Permissions

struct OnboardingPermission {
    let title: String
    let description: String
    let iconName: String
    let isRequired: Bool
    let permissionType: PermissionType
}

enum PermissionType {
    case notifications
    case screenTime
    case backgroundRefresh
}

extension OnboardingStep {
    var requiredPermissions: [OnboardingPermission] {
        switch self {
        case .notifications:
            return [
                OnboardingPermission(
                    title: "通知权限",
                    description: "允许应用发送专注提醒和成就通知",
                    iconName: "bell.fill",
                    isRequired: false,
                    permissionType: .notifications
                ),
                OnboardingPermission(
                    title: "后台刷新",
                    description: "允许应用在后台更新专注状态",
                    iconName: "arrow.clockwise",
                    isRequired: true,
                    permissionType: .backgroundRefresh
                )
            ]
        default:
            return []
        }
    }
}