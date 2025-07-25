import SwiftUI

/// Provides contextual highlights and tooltips for new features
struct FeatureHighlightView: ViewModifier {
    let feature: HighlightFeature
    @State private var showHighlight = false
    @State private var hasShownHighlight = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                highlightOverlay,
                alignment: feature.alignment
            )
            .onAppear {
                checkAndShowHighlight()
            }
    }
    
    @ViewBuilder
    private var highlightOverlay: some View {
        if showHighlight && !hasShownHighlight {
            FeatureTooltip(
                feature: feature,
                isShowing: $showHighlight
            ) {
                markAsShown()
            }
            .transition(.opacity.combined(with: .scale))
            .zIndex(1000)
        }
    }
    
    private func checkAndShowHighlight() {
        let key = "hasShown_\(feature.id)"
        let hasShown = UserDefaults.standard.bool(forKey: key)
        
        if !hasShown && feature.shouldShow() {
            DispatchQueue.main.asyncAfter(deadline: .now() + feature.delay) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showHighlight = true
                }
            }
        }
    }
    
    private func markAsShown() {
        let key = "hasShown_\(feature.id)"
        UserDefaults.standard.set(true, forKey: key)
        hasShownHighlight = true
        
        withAnimation(.easeOut(duration: 0.3)) {
            showHighlight = false
        }
    }
}

// MARK: - Feature Tooltip

struct FeatureTooltip: View {
    let feature: HighlightFeature
    @Binding var isShowing: Bool
    let onDismiss: () -> Void
    
    @State private var animateContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tooltip content
            VStack(spacing: 12) {
                HStack {
                    if feature.isNew {
                        Text("新功能")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
                
                HStack {
                    Image(systemName: feature.iconName)
                        .font(.title2)
                        .foregroundColor(feature.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(feature.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                
                if let actionTitle = feature.actionTitle {
                    Button(action: {
                        feature.action?()
                        onDismiss()
                    }) {
                        Text(actionTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(feature.color)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            
            // Arrow pointing to the feature
            if feature.showArrow {
                tooltipArrow
            }
        }
        .scaleEffect(animateContent ? 1.0 : 0.8)
        .opacity(animateContent ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
    
    @ViewBuilder
    private var tooltipArrow: some View {
        switch feature.arrowDirection {
        case .up:
            Triangle()
                .fill(Color(.systemBackground))
                .frame(width: 20, height: 10)
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: -1)
        case .down:
            Triangle()
                .fill(Color(.systemBackground))
                .frame(width: 20, height: 10)
                .rotationEffect(.degrees(180))
                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
        case .left:
            Triangle()
                .fill(Color(.systemBackground))
                .frame(width: 10, height: 20)
                .rotationEffect(.degrees(-90))
                .shadow(color: .black.opacity(0.15), radius: 2, x: -1, y: 0)
        case .right:
            Triangle()
                .fill(Color(.systemBackground))
                .frame(width: 10, height: 20)
                .rotationEffect(.degrees(90))
                .shadow(color: .black.opacity(0.15), radius: 2, x: 1, y: 0)
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Highlight Feature Model

struct HighlightFeature {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let isNew: Bool
    let alignment: Alignment
    let arrowDirection: ArrowDirection
    let showArrow: Bool
    let delay: TimeInterval
    let actionTitle: String?
    let action: (() -> Void)?
    let shouldShow: () -> Bool
    
    init(
        id: String,
        title: String,
        description: String,
        iconName: String,
        color: Color = .blue,
        isNew: Bool = true,
        alignment: Alignment = .topTrailing,
        arrowDirection: ArrowDirection = .down,
        showArrow: Bool = true,
        delay: TimeInterval = 1.0,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        shouldShow: @escaping () -> Bool = { true }
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.color = color
        self.isNew = isNew
        self.alignment = alignment
        self.arrowDirection = arrowDirection
        self.showArrow = showArrow
        self.delay = delay
        self.actionTitle = actionTitle
        self.action = action
        self.shouldShow = shouldShow
    }
}

enum ArrowDirection {
    case up, down, left, right
}

// MARK: - View Extension

extension View {
    func featureHighlight(_ feature: HighlightFeature) -> some View {
        self.modifier(FeatureHighlightView(feature: feature))
    }
}

// MARK: - Predefined Features

extension HighlightFeature {
    // Time Analysis Features
    static let timeUsageRing = HighlightFeature(
        id: "time_usage_ring",
        title: "时间使用环形图",
        description: "查看您的时间在不同活动间的分布情况",
        iconName: "chart.pie.fill",
        color: .orange,
        alignment: .top,
        arrowDirection: .down,
        delay: 0.5
    )
    
    static let appBreakdown = HighlightFeature(
        id: "app_breakdown",
        title: "应用使用分析",
        description: "了解您最常使用的应用和使用时长",
        iconName: "apps.iphone",
        color: .blue,
        alignment: .topLeading,
        arrowDirection: .down,
        delay: 1.0
    )
    
    static let sceneTagSummary = HighlightFeature(
        id: "scene_tag_summary",
        title: "场景标签统计",
        description: "按活动类型查看时间分布",
        iconName: "tag.fill",
        color: .purple,
        alignment: .topTrailing,
        arrowDirection: .down,
        delay: 1.5
    )
    
    // Statistics Features
    static let weeklyTrendChart = HighlightFeature(
        id: "weekly_trend_chart",
        title: "增强趋势图表",
        description: "现在包含应用使用数据的综合趋势分析",
        iconName: "chart.line.uptrend.xyaxis",
        color: .green,
        alignment: .top,
        arrowDirection: .down,
        delay: 0.5
    )
    
    static let appUsageRanking = HighlightFeature(
        id: "app_usage_ranking",
        title: "应用使用排行",
        description: "查看您最常使用的应用排名和详细统计",
        iconName: "list.number",
        color: .orange,
        alignment: .topLeading,
        arrowDirection: .down,
        delay: 1.0
    )
    
    static let sceneTagAnalysis = HighlightFeature(
        id: "scene_tag_analysis",
        title: "场景标签分析",
        description: "深入分析不同活动场景的时间使用模式",
        iconName: "chart.bar.doc.horizontal.fill",
        color: .purple,
        alignment: .topTrailing,
        arrowDirection: .down,
        delay: 1.5
    )
    
    // Tags Features
    static let tagManagement = HighlightFeature(
        id: "tag_management",
        title: "智能标签管理",
        description: "创建和管理您的活动标签，获得智能推荐",
        iconName: "tag.circle.fill",
        color: .purple,
        alignment: .top,
        arrowDirection: .down,
        delay: 0.5,
        actionTitle: "了解更多",
        action: {
            // Navigate to tags help or tutorial
        }
    )
    
    static let tagRecommendations = HighlightFeature(
        id: "tag_recommendations",
        title: "智能标签推荐",
        description: "系统会根据应用类型自动推荐合适的标签",
        iconName: "brain.head.profile",
        color: .blue,
        alignment: .topLeading,
        arrowDirection: .down,
        delay: 1.0
    )
    
    // Settings Features
    static let enhancedSettings = HighlightFeature(
        id: "enhanced_settings",
        title: "增强设置选项",
        description: "更多个性化设置选项，包括标签管理和分析偏好",
        iconName: "gearshape.2.fill",
        color: .gray,
        alignment: .top,
        arrowDirection: .down,
        delay: 0.5
    )
}

// MARK: - Feature Highlight Manager

class FeatureHighlightManager: ObservableObject {
    static let shared = FeatureHighlightManager()
    
    @Published var activeHighlights: [HighlightFeature] = []
    @Published var shouldShowHighlights = true
    
    private init() {
        loadHighlightPreferences()
    }
    
    func showFeatureHighlights(for context: HighlightContext) {
        guard shouldShowHighlights else { return }
        
        let features = getFeatures(for: context)
        activeHighlights = features.filter { $0.shouldShow() }
    }
    
    func dismissAllHighlights() {
        activeHighlights.removeAll()
    }
    
    func disableHighlights() {
        shouldShowHighlights = false
        UserDefaults.standard.set(false, forKey: "shouldShowFeatureHighlights")
        dismissAllHighlights()
    }
    
    func enableHighlights() {
        shouldShowHighlights = true
        UserDefaults.standard.set(true, forKey: "shouldShowFeatureHighlights")
    }
    
    func resetHighlights() {
        let keys = [
            "hasShown_time_usage_ring",
            "hasShown_app_breakdown",
            "hasShown_scene_tag_summary",
            "hasShown_weekly_trend_chart",
            "hasShown_app_usage_ranking",
            "hasShown_scene_tag_analysis",
            "hasShown_tag_management",
            "hasShown_tag_recommendations",
            "hasShown_enhanced_settings"
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    private func loadHighlightPreferences() {
        shouldShowHighlights = UserDefaults.standard.object(forKey: "shouldShowFeatureHighlights") as? Bool ?? true
    }
    
    private func getFeatures(for context: HighlightContext) -> [HighlightFeature] {
        switch context {
        case .home:
            return [.timeUsageRing, .appBreakdown, .sceneTagSummary]
        case .statistics:
            return [.weeklyTrendChart, .appUsageRanking, .sceneTagAnalysis]
        case .tags:
            return [.tagManagement, .tagRecommendations]
        case .settings:
            return [.enhancedSettings]
        }
    }
}

enum HighlightContext {
    case home
    case statistics
    case tags
    case settings
}