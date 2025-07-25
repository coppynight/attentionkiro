import SwiftUI

/// Main onboarding view that guides users through app features
struct OnboardingView: View {
    @ObservedObject private var coordinator = OnboardingCoordinator.shared
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    coordinator.currentOnboardingStep.primaryColor.opacity(0.1),
                    coordinator.currentOnboardingStep.primaryColor.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressView(
                    progress: coordinator.onboardingProgress,
                    currentStep: coordinator.currentOnboardingStep
                )
                .padding(.top, 20)
                
                // Main content
                TabView(selection: $coordinator.currentOnboardingStep) {
                    ForEach(OnboardingStep.allCases) { step in
                        OnboardingStepView(step: step)
                            .tag(step)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: coordinator.currentOnboardingStep)
                
                // Navigation buttons
                OnboardingNavigationView()
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Progress View

struct OnboardingProgressView: View {
    let progress: Double
    let currentStep: OnboardingStep
    
    var body: some View {
        VStack(spacing: 16) {
            // Step indicator dots
            HStack(spacing: 12) {
                ForEach(OnboardingStep.allCases) { step in
                    Circle()
                        .fill(step == currentStep ? currentStep.primaryColor : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .scaleEffect(step == currentStep ? 1.2 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(currentStep.primaryColor)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Step View

struct OnboardingStepView: View {
    let step: OnboardingStep
    @State private var animateFeatures = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)
                
                // Header
                OnboardingHeaderView(step: step)
                
                // Features
                OnboardingFeaturesView(
                    features: step.features,
                    animate: animateFeatures
                )
                
                // Permissions (if any)
                if !step.requiredPermissions.isEmpty {
                    OnboardingPermissionsView(permissions: step.requiredPermissions)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                animateFeatures = true
            }
        }
        .onDisappear {
            animateFeatures = false
        }
    }
}

// MARK: - Header View

struct OnboardingHeaderView: View {
    let step: OnboardingStep
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(step.primaryColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: step.iconName)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(step.primaryColor)
                    .scaleEffect(animateIcon ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateIcon)
            }
            
            // Title and subtitle
            VStack(spacing: 12) {
                Text(step.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(step.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                animateIcon = true
            }
        }
    }
}

// MARK: - Features View

struct OnboardingFeaturesView: View {
    let features: [OnboardingFeature]
    let animate: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(Array(features.enumerated()), id: \.element.title) { index, feature in
                OnboardingFeatureRow(
                    feature: feature,
                    animate: animate,
                    delay: Double(index) * 0.1
                )
            }
        }
    }
}

struct OnboardingFeatureRow: View {
    let feature: OnboardingFeature
    let animate: Bool
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: feature.iconName)
                    .font(.title2)
                    .foregroundColor(feature.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(feature.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if feature.isNew {
                        Text("新功能")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(delay), value: isVisible)
        .onChange(of: animate) { newValue in
            if newValue {
                isVisible = true
            } else {
                isVisible = false
            }
        }
    }
}

// MARK: - Permissions View

struct OnboardingPermissionsView: View {
    let permissions: [OnboardingPermission]
    @State private var requestedPermissions: Set<PermissionType> = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("需要的权限")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                ForEach(permissions, id: \.title) { permission in
                    OnboardingPermissionRow(
                        permission: permission,
                        isRequested: requestedPermissions.contains(permission.permissionType)
                    ) {
                        requestPermission(permission.permissionType)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func requestPermission(_ type: PermissionType) {
        requestedPermissions.insert(type)
        
        switch type {
        case .notifications:
            requestNotificationPermission()
        case .screenTime:
            // Screen Time permission would be requested here
            break
        case .backgroundRefresh:
            // Background refresh is handled in app settings
            break
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                } else {
                    print("Notification permission denied")
                }
            }
        }
    }
}

struct OnboardingPermissionRow: View {
    let permission: OnboardingPermission
    let isRequested: Bool
    let onRequest: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: permission.iconName)
                .font(.title2)
                .foregroundColor(permission.isRequired ? .red : .blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(permission.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if permission.isRequired {
                        Text("必需")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                }
                
                Text(permission.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Button(action: onRequest) {
                if isRequested {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    Text("允许")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
            }
            .disabled(isRequested)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Navigation View

struct OnboardingNavigationView: View {
    @ObservedObject private var coordinator = OnboardingCoordinator.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Primary action button
            Button(action: {
                coordinator.nextStep()
            }) {
                HStack {
                    Text(primaryButtonTitle)
                        .fontWeight(.semibold)
                    
                    if coordinator.currentOnboardingStep != .completion {
                        Image(systemName: "arrow.right")
                            .font(.subheadline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(coordinator.currentOnboardingStep.primaryColor)
                .cornerRadius(12)
            }
            
            // Secondary actions
            HStack(spacing: 24) {
                if coordinator.currentOnboardingStep != .welcome {
                    Button("上一步") {
                        coordinator.previousStep()
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if coordinator.currentOnboardingStep != .completion {
                    Button("跳过") {
                        coordinator.skipStep()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var primaryButtonTitle: String {
        switch coordinator.currentOnboardingStep {
        case .welcome:
            return "开始使用"
        case .completion:
            return "完成设置"
        default:
            return "继续"
        }
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

// MARK: - UserNotifications Import

import UserNotifications