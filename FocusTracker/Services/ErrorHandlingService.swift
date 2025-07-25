import Foundation
import SwiftUI
import Combine

/// Centralized error handling service for consistent error management across the app
class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    // MARK: - Published Properties
    
    @Published var currentError: AppError?
    @Published var isShowingError: Bool = false
    @Published var errorHistory: [AppError] = []
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let maxErrorHistoryCount = 50
    
    // MARK: - Initialization
    
    private init() {
        setupErrorObservers()
    }
    
    // MARK: - Public Methods
    
    /// Reports an error to the centralized error handling system
    func reportError(_ error: AppError) {
        DispatchQueue.main.async {
            self.currentError = error
            self.isShowingError = true
            self.addToHistory(error)
            
            // Log error for debugging
            self.logError(error)
            
            // Send analytics if needed
            self.sendErrorAnalytics(error)
        }
    }
    
    /// Reports a generic error and converts it to AppError
    func reportError(_ error: Error, context: ErrorContext = .general) {
        let appError = AppError.from(error, context: context)
        reportError(appError)
    }
    
    /// Dismisses the current error
    func dismissError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.isShowingError = false
        }
    }
    
    /// Clears error history
    func clearErrorHistory() {
        DispatchQueue.main.async {
            self.errorHistory.removeAll()
        }
    }
    
    /// Gets error statistics for debugging
    func getErrorStatistics() -> ErrorStatistics {
        let totalErrors = errorHistory.count
        let errorsByType = Dictionary(grouping: errorHistory) { $0.type }
        let errorsByContext = Dictionary(grouping: errorHistory) { $0.context }
        
        let mostCommonType = errorsByType.max { $0.value.count < $1.value.count }?.key
        let mostCommonContext = errorsByContext.max { $0.value.count < $1.value.count }?.key
        
        return ErrorStatistics(
            totalErrors: totalErrors,
            errorsByType: errorsByType.mapValues { $0.count },
            errorsByContext: errorsByContext.mapValues { $0.count },
            mostCommonType: mostCommonType,
            mostCommonContext: mostCommonContext,
            recentErrors: Array(errorHistory.suffix(10))
        )
    }
    
    // MARK: - Private Methods
    
    private func setupErrorObservers() {
        // Observe Core Data errors
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { [weak self] notification in
                if let error = notification.userInfo?["error"] as? Error {
                    self?.reportError(error, context: .coreData)
                }
            }
            .store(in: &cancellables)
        
        // Observe network errors (if applicable)
        NotificationCenter.default.publisher(for: .networkError)
            .sink { [weak self] notification in
                if let error = notification.userInfo?["error"] as? Error {
                    self?.reportError(error, context: .network)
                }
            }
            .store(in: &cancellables)
    }
    
    private func addToHistory(_ error: AppError) {
        errorHistory.append(error)
        
        // Limit history size
        if errorHistory.count > maxErrorHistoryCount {
            errorHistory.removeFirst(errorHistory.count - maxErrorHistoryCount)
        }
    }
    
    private func logError(_ error: AppError) {
        print("🚨 AppError: [\(error.context)] \(error.type) - \(error.localizedDescription)")
        if let underlyingError = error.underlyingError {
            print("   Underlying: \(underlyingError.localizedDescription)")
        }
        print("   Timestamp: \(error.timestamp)")
        print("   Recovery: \(error.recoveryAction)")
    }
    
    private func sendErrorAnalytics(_ error: AppError) {
        // In a real app, you might send this to analytics service
        // For now, we'll just log it
        print("📊 Error Analytics: \(error.type) in \(error.context)")
    }
}

// MARK: - AppError Definition

/// Comprehensive error type for the FocusTracker app
struct AppError: Error, Identifiable, Equatable {
    let id = UUID()
    let type: ErrorType
    let context: ErrorContext
    let message: String
    let recoveryAction: String
    let underlyingError: Error?
    let timestamp: Date
    
    init(
        type: ErrorType,
        context: ErrorContext,
        message: String,
        recoverySuggestion: String,
        underlyingError: Error? = nil
    ) {
        self.type = type
        self.context = context
        self.message = message
        self.recoveryAction = recoverySuggestion
        self.underlyingError = underlyingError
        self.timestamp = Date()
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Creates an AppError from a generic Error
    static func from(_ error: Error, context: ErrorContext) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        let errorType: ErrorType
        let message: String
        let recovery: String
        
        switch error {
        case is DecodingError:
            errorType = .dataCorruption
            message = "数据格式错误"
            recovery = "请重启应用或重置数据"
            
        case let nsError as NSError where nsError.domain == NSCocoaErrorDomain:
            errorType = .coreDataError
            message = "数据存储错误"
            recovery = "请检查存储空间并重试"
            
        case _ as URLError:
            errorType = .networkError
            message = "网络连接错误"
            recovery = "请检查网络连接并重试"
            
        default:
            errorType = .unknown
            message = error.localizedDescription
            recovery = "请重试或联系支持"
        }
        
        return AppError(
            type: errorType,
            context: context,
            message: message,
            recoverySuggestion: recovery,
            underlyingError: error
        )
    }
}

// MARK: - Error Types and Contexts

enum ErrorType: String, CaseIterable {
    case coreDataError = "core_data_error"
    case networkError = "network_error"
    case validationError = "validation_error"
    case permissionError = "permission_error"
    case dataCorruption = "data_corruption"
    case focusTrackingError = "focus_tracking_error"
    case tagManagementError = "tag_management_error"
    case timeAnalysisError = "time_analysis_error"
    case notificationError = "notification_error"
    case unknown = "unknown_error"
    
    var displayName: String {
        switch self {
        case .coreDataError:
            return "数据存储错误"
        case .networkError:
            return "网络错误"
        case .validationError:
            return "数据验证错误"
        case .permissionError:
            return "权限错误"
        case .dataCorruption:
            return "数据损坏"
        case .focusTrackingError:
            return "专注追踪错误"
        case .tagManagementError:
            return "标签管理错误"
        case .timeAnalysisError:
            return "时间分析错误"
        case .notificationError:
            return "通知错误"
        case .unknown:
            return "未知错误"
        }
    }
}

enum ErrorContext: String, CaseIterable {
    case general = "general"
    case coreData = "core_data"
    case network = "network"
    case focusTracking = "focus_tracking"
    case tagManagement = "tag_management"
    case timeAnalysis = "time_analysis"
    case userInterface = "user_interface"
    case notifications = "notifications"
    case settings = "settings"
    
    var displayName: String {
        switch self {
        case .general:
            return "通用"
        case .coreData:
            return "数据存储"
        case .network:
            return "网络"
        case .focusTracking:
            return "专注追踪"
        case .tagManagement:
            return "标签管理"
        case .timeAnalysis:
            return "时间分析"
        case .userInterface:
            return "用户界面"
        case .notifications:
            return "通知"
        case .settings:
            return "设置"
        }
    }
}

// MARK: - Error Statistics

struct ErrorStatistics {
    let totalErrors: Int
    let errorsByType: [ErrorType: Int]
    let errorsByContext: [ErrorContext: Int]
    let mostCommonType: ErrorType?
    let mostCommonContext: ErrorContext?
    let recentErrors: [AppError]
}

// MARK: - LocalizedError Conformance

extension AppError: LocalizedError {
    var errorDescription: String? {
        return message
    }
    
    var recoverySuggestion: String? {
        return recoveryAction
    }
    
    var failureReason: String? {
        return "\(type.displayName) in \(context.displayName)"
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let networkError = Notification.Name("networkError")
    static let coreDataError = Notification.Name("coreDataError")
    static let focusTrackingError = Notification.Name("focusTrackingError")
}

// MARK: - Convenience Error Creation Methods

extension AppError {
    // Focus Tracking Errors
    static func focusSessionCreationFailed(_ underlyingError: Error? = nil) -> AppError {
        return AppError(
            type: .focusTrackingError,
            context: .focusTracking,
            message: "无法创建专注时段",
            recoverySuggestion: "请检查存储空间并重试",
            underlyingError: underlyingError
        )
    }
    
    static func focusSessionValidationFailed(_ reason: String) -> AppError {
        return AppError(
            type: .validationError,
            context: .focusTracking,
            message: "专注时段验证失败: \(reason)",
            recoverySuggestion: "请确保专注时段符合最小时长要求"
        )
    }
    
    // Tag Management Errors
    static func tagCreationFailed(_ reason: String) -> AppError {
        return AppError(
            type: .tagManagementError,
            context: .tagManagement,
            message: "无法创建标签: \(reason)",
            recoverySuggestion: "请检查标签名称是否重复或包含无效字符"
        )
    }
    
    static func tagDeletionFailed(_ reason: String) -> AppError {
        return AppError(
            type: .tagManagementError,
            context: .tagManagement,
            message: "无法删除标签: \(reason)",
            recoverySuggestion: "默认标签无法删除，请选择自定义标签"
        )
    }
    
    // Time Analysis Errors
    static func timeAnalysisCalculationFailed(_ underlyingError: Error? = nil) -> AppError {
        return AppError(
            type: .timeAnalysisError,
            context: .timeAnalysis,
            message: "时间分析计算失败",
            recoverySuggestion: "请重新加载数据或重启应用",
            underlyingError: underlyingError
        )
    }
    
    // Core Data Errors
    static func coreDataSaveFailed(_ underlyingError: Error) -> AppError {
        return AppError(
            type: .coreDataError,
            context: .coreData,
            message: "数据保存失败",
            recoverySuggestion: "请检查存储空间并重试",
            underlyingError: underlyingError
        )
    }
    
    static func coreDataFetchFailed(_ underlyingError: Error) -> AppError {
        return AppError(
            type: .coreDataError,
            context: .coreData,
            message: "数据获取失败",
            recoverySuggestion: "请重新加载数据",
            underlyingError: underlyingError
        )
    }
    
    // Permission Errors
    static func notificationPermissionDenied() -> AppError {
        return AppError(
            type: .permissionError,
            context: .notifications,
            message: "通知权限被拒绝",
            recoverySuggestion: "请在设置中启用通知权限"
        )
    }
    
    // Validation Errors
    static func invalidTimeRange() -> AppError {
        return AppError(
            type: .validationError,
            context: .general,
            message: "时间范围无效",
            recoverySuggestion: "请选择有效的时间范围"
        )
    }
    
    static func invalidUserInput(_ field: String) -> AppError {
        return AppError(
            type: .validationError,
            context: .userInterface,
            message: "\(field)输入无效",
            recoverySuggestion: "请检查输入格式并重试"
        )
    }
}