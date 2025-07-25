import SwiftUI

/// Enhanced error alert view that provides consistent error presentation across the app
struct ErrorAlertView: ViewModifier {
    @ObservedObject private var errorService = ErrorHandlingService.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorService.currentError?.type.displayName ?? "错误",
                isPresented: $errorService.isShowingError,
                presenting: errorService.currentError
            ) { error in
                // Primary action button
                Button("重试") {
                    handleRetryAction(for: error)
                }
                
                // Secondary action button (context-dependent)
                if let secondaryAction = getSecondaryAction(for: error) {
                    Button(secondaryAction.title) {
                        secondaryAction.action()
                    }
                }
                
                // Dismiss button
                Button("确定", role: .cancel) {
                    errorService.dismissError()
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.message)
                    
                    if !error.recoveryAction.isEmpty {
                        Text(error.recoveryAction)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
    }
    
    private func handleRetryAction(for error: AppError) {
        errorService.dismissError()
        
        // Context-specific retry logic
        switch error.context {
        case .focusTracking:
            retryFocusTrackingOperation(error)
        case .tagManagement:
            retryTagManagementOperation(error)
        case .timeAnalysis:
            retryTimeAnalysisOperation(error)
        case .coreData:
            retryCoreDataOperation(error)
        case .notifications:
            retryNotificationOperation(error)
        default:
            // Generic retry - just dismiss the error
            break
        }
    }
    
    private func getSecondaryAction(for error: AppError) -> (title: String, action: () -> Void)? {
        switch error.type {
        case .permissionError:
            return ("打开设置", {
                openAppSettings()
            })
        case .coreDataError:
            return ("重置数据", {
                showDataResetConfirmation()
            })
        case .networkError:
            return ("检查网络", {
                // Could open network settings or show network status
            })
        default:
            return nil
        }
    }
    
    // MARK: - Retry Operations
    
    private func retryFocusTrackingOperation(_ error: AppError) {
        // Retry focus tracking operations
        NotificationCenter.default.post(name: .retryFocusTracking, object: error)
    }
    
    private func retryTagManagementOperation(_ error: AppError) {
        // Retry tag management operations
        NotificationCenter.default.post(name: .retryTagManagement, object: error)
    }
    
    private func retryTimeAnalysisOperation(_ error: AppError) {
        // Retry time analysis operations
        NotificationCenter.default.post(name: .retryTimeAnalysis, object: error)
    }
    
    private func retryCoreDataOperation(_ error: AppError) {
        // Retry Core Data operations
        NotificationCenter.default.post(name: .retryCoreDataOperation, object: error)
    }
    
    private func retryNotificationOperation(_ error: AppError) {
        // Retry notification operations
        NotificationCenter.default.post(name: .retryNotificationOperation, object: error)
    }
    
    // MARK: - Secondary Actions
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func showDataResetConfirmation() {
        // This would typically show another alert or navigate to settings
        NotificationCenter.default.post(name: .showDataResetConfirmation, object: nil)
    }
}

// MARK: - View Extension

extension View {
    /// Applies the error alert modifier to any view
    func errorAlert() -> some View {
        self.modifier(ErrorAlertView())
    }
}

// MARK: - Enhanced Error Toast View

struct ErrorToastView: View {
    let error: AppError
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForErrorType(error.type))
                    .foregroundColor(colorForErrorType(error.type))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(error.type.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(error.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            if !error.recoveryAction.isEmpty {
                Text(error.recoveryAction)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 32)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    private func iconForErrorType(_ type: ErrorType) -> String {
        switch type {
        case .coreDataError:
            return "externaldrive.badge.xmark"
        case .networkError:
            return "wifi.exclamationmark"
        case .validationError:
            return "exclamationmark.triangle"
        case .permissionError:
            return "lock.shield"
        case .dataCorruption:
            return "doc.badge.exclamationmark"
        case .focusTrackingError:
            return "brain.head.profile.badge.exclamationmark"
        case .tagManagementError:
            return "tag.slash"
        case .timeAnalysisError:
            return "chart.bar.xaxis.badge.exclamationmark"
        case .notificationError:
            return "bell.badge.exclamationmark"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    private func colorForErrorType(_ type: ErrorType) -> Color {
        switch type {
        case .coreDataError, .dataCorruption:
            return .red
        case .networkError:
            return .orange
        case .validationError:
            return .yellow
        case .permissionError:
            return .purple
        case .focusTrackingError, .tagManagementError, .timeAnalysisError:
            return .blue
        case .notificationError:
            return .green
        case .unknown:
            return .gray
        }
    }
}

// MARK: - Error Toast Modifier

struct ErrorToastModifier: ViewModifier {
    @ObservedObject private var errorService = ErrorHandlingService.shared
    @State private var showToast = false
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if showToast, let error = errorService.currentError {
                ErrorToastView(error: error, isShowing: $showToast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1000)
                    .onAppear {
                        // Auto-dismiss after 5 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation {
                                showToast = false
                                errorService.dismissError()
                            }
                        }
                    }
            }
        }
        .onReceive(errorService.$isShowingError) { isShowing in
            if isShowing {
                withAnimation(.spring()) {
                    showToast = true
                }
            }
        }
    }
}

extension View {
    /// Shows errors as toast notifications instead of alerts
    func errorToast() -> some View {
        self.modifier(ErrorToastModifier())
    }
}

// MARK: - Error Debug View (for development)

struct ErrorDebugView: View {
    @ObservedObject private var errorService = ErrorHandlingService.shared
    @State private var showingErrorHistory = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("错误调试信息")
                    .font(.headline)
                
                Spacer()
                
                Button("查看历史") {
                    showingErrorHistory = true
                }
                .font(.caption)
            }
            
            let stats = errorService.getErrorStatistics()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("总错误数: \(stats.totalErrors)")
                
                if let mostCommonType = stats.mostCommonType {
                    Text("最常见错误: \(mostCommonType.displayName)")
                }
                
                if let mostCommonContext = stats.mostCommonContext {
                    Text("最常见场景: \(mostCommonContext.displayName)")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Button("清除历史") {
                errorService.clearErrorHistory()
            }
            .font(.caption)
            .foregroundColor(.red)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .sheet(isPresented: $showingErrorHistory) {
            ErrorHistoryView()
        }
    }
}

// MARK: - Error History View

struct ErrorHistoryView: View {
    @ObservedObject private var errorService = ErrorHandlingService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(errorService.errorHistory.reversed()) { error in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(error.type.displayName)
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(formatTimestamp(error.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(error.message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("场景: \(error.context.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !error.recoveryAction.isEmpty {
                            Text("建议: \(error.recoveryAction)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("错误历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let retryFocusTracking = Notification.Name("retryFocusTracking")
    static let retryTagManagement = Notification.Name("retryTagManagement")
    static let retryTimeAnalysis = Notification.Name("retryTimeAnalysis")
    static let retryCoreDataOperation = Notification.Name("retryCoreDataOperation")
    static let retryNotificationOperation = Notification.Name("retryNotificationOperation")
    static let showDataResetConfirmation = Notification.Name("showDataResetConfirmation")
}