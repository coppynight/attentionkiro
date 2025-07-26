import SwiftUI
import CoreData

/// 专注洞察和建议视图
struct FocusInsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var focusQualityAnalyzer: FocusQualityAnalyzer
    @StateObject private var insightsGenerator: FocusInsightsGenerator
    
    @State private var insights: [FocusInsight] = []
    @State private var selectedInsightType: InsightType = .all
    
    enum InsightType: String, CaseIterable, Identifiable {
        case all = "全部"
        case quality = "质量"
        case interruption = "打断"
        case timeSlot = "时段"
        case suggestion = "建议"
        
        var id: String { self.rawValue }
    }
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._focusQualityAnalyzer = StateObject(wrappedValue: FocusQualityAnalyzer(viewContext: context))
        self._insightsGenerator = StateObject(wrappedValue: FocusInsightsGenerator(viewContext: context))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 洞察类型选择器
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(InsightType.allCases) { type in
                            Button(action: {
                                selectedInsightType = type
                                filterInsights()
                            }) {
                                Text(type.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedInsightType == type ? 
                                        Color.blue : Color(.systemGray5)
                                    )
                                    .foregroundColor(
                                        selectedInsightType == type ? 
                                        .white : .primary
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                
                // 洞察列表
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredInsights, id: \.id) { insight in
                            FocusInsightCard(insight: insight)
                        }
                        
                        if filteredInsights.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("暂无相关洞察")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("继续使用应用，我们将为你生成个性化的专注洞察")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("专注洞察")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刷新") {
                        loadInsights()
                    }
                    .font(.subheadline)
                }
            }
        }
        .onAppear {
            loadInsights()
        }
    }
    
    private var filteredInsights: [FocusInsight] {
        if selectedInsightType == .all {
            return insights
        } else {
            return insights.filter { $0.type.rawValue == selectedInsightType.rawValue }
        }
    }
    
    private func loadInsights() {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let period = DateInterval(start: weekAgo, end: today)
        
        insights = insightsGenerator.generateInsights(for: period)
    }
    
    private func filterInsights() {
        // 可以在这里添加额外的过滤逻辑
    }
}

/// 专注洞察数据结构
struct FocusInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let impact: ImpactLevel
    let actionable: Bool
    let suggestions: [String]
    let metrics: [String: Double]
    let icon: String
    let color: Color
    
    enum InsightType: String, CaseIterable {
        case quality = "质量"
        case interruption = "打断"
        case timeSlot = "时段"
        case suggestion = "建议"
    }
    
    enum ImpactLevel: String, CaseIterable {
        case high = "高"
        case medium = "中"
        case low = "低"
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
    }
}

/// 专注洞察生成器
class FocusInsightsGenerator: ObservableObject {
    private let viewContext: NSManagedObjectContext
    private let focusQualityAnalyzer: FocusQualityAnalyzer
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        self.focusQualityAnalyzer = FocusQualityAnalyzer(viewContext: viewContext)
    }
    
    func generateInsights(for period: DateInterval) -> [FocusInsight] {
        var insights: [FocusInsight] = []
        
        // 分析期间内的数据
        let calendar = Calendar.current
        var currentDate = period.start
        var dailyMetrics: [FocusQualityMetrics] = []
        var dailyInterruptions: [InterruptionAnalysis] = []
        
        while currentDate < period.end {
            let metrics = focusQualityAnalyzer.analyzeFocusQuality(for: currentDate)
            let interruptions = focusQualityAnalyzer.analyzeInterruptions(for: currentDate)
            
            dailyMetrics.append(metrics)
            dailyInterruptions.append(interruptions)
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? period.end
        }
        
        // 生成质量相关洞察
        insights.append(contentsOf: generateQualityInsights(from: dailyMetrics))
        
        // 生成打断相关洞察
        insights.append(contentsOf: generateInterruptionInsights(from: dailyInterruptions))
        
        // 生成时段相关洞察
        let timeSlotAnalysis = focusQualityAnalyzer.analyzeFocusTimeSlots(for: period)
        insights.append(contentsOf: generateTimeSlotInsights(from: timeSlotAnalysis))
        
        // 生成建议
        insights.append(contentsOf: generateSuggestions(from: dailyMetrics, interruptions: dailyInterruptions))
        
        return insights.sorted { $0.impact.rawValue < $1.impact.rawValue }
    }
    
    private func generateQualityInsights(from metrics: [FocusQualityMetrics]) -> [FocusInsight] {
        var insights: [FocusInsight] = []
        
        let averageScore = metrics.reduce(0) { $0 + $1.focusQualityScore } / Double(metrics.count)
        let totalDeepFocus = metrics.reduce(0) { $0 + $1.deepFocusTime }
        let totalFragmented = metrics.reduce(0) { $0 + $1.fragmentedTime }
        
        // 专注质量趋势分析
        if averageScore < 50 {
            insights.append(FocusInsight(
                type: .quality,
                title: "专注质量需要改善",
                description: "你的平均专注质量评分为 \(Int(averageScore)) 分，低于建议水平。主要问题是碎片时间过多。",
                impact: .high,
                actionable: true,
                suggestions: [
                    "尝试将短时间的专注会话合并为更长的时间块",
                    "在开始专注前关闭不必要的通知",
                    "使用番茄工作法来提高专注持续性"
                ],
                metrics: ["averageScore": averageScore],
                icon: "exclamationmark.triangle",
                color: .red
            ))
        } else if averageScore > 80 {
            insights.append(FocusInsight(
                type: .quality,
                title: "专注质量优秀",
                description: "你的平均专注质量评分为 \(Int(averageScore)) 分，表现优秀！继续保持这种良好的专注习惯。",
                impact: .low,
                actionable: false,
                suggestions: ["继续保持当前的专注策略"],
                metrics: ["averageScore": averageScore],
                icon: "star.fill",
                color: .green
            ))
        }
        
        // 深度专注时间分析
        let deepFocusHours = totalDeepFocus / 3600
        if deepFocusHours < 2 {
            insights.append(FocusInsight(
                type: .quality,
                title: "深度专注时间不足",
                description: "本周深度专注时间仅 \(String(format: "%.1f", deepFocusHours)) 小时，建议增加长时间的专注会话。",
                impact: .medium,
                actionable: true,
                suggestions: [
                    "每天安排至少一个45分钟以上的专注时段",
                    "选择一天中精力最充沛的时间进行深度工作",
                    "创造无干扰的工作环境"
                ],
                metrics: ["deepFocusHours": deepFocusHours],
                icon: "brain.head.profile",
                color: .blue
            ))
        }
        
        return insights
    }
    
    private func generateInterruptionInsights(from interruptions: [InterruptionAnalysis]) -> [FocusInsight] {
        var insights: [FocusInsight] = []
        
        let totalInterruptions = interruptions.reduce(0) { $0 + $1.totalInterruptions }
        let averageRecoveryRate = interruptions.reduce(0) { $0 + $1.interruptionRecoveryRate } / Double(interruptions.count)
        
        // 打断频率分析
        if totalInterruptions > 20 {
            insights.append(FocusInsight(
                type: .interruption,
                title: "打断次数过多",
                description: "本周共被打断 \(totalInterruptions) 次，频繁的打断严重影响专注效果。",
                impact: .high,
                actionable: true,
                suggestions: [
                    "在专注时间关闭手机通知",
                    "告知同事你的专注时间段",
                    "使用专注模式或勿扰模式",
                    "选择相对安静的工作环境"
                ],
                metrics: ["totalInterruptions": Double(totalInterruptions)],
                icon: "bell.slash",
                color: .red
            ))
        }
        
        // 恢复率分析
        if averageRecoveryRate < 0.6 {
            insights.append(FocusInsight(
                type: .interruption,
                title: "专注恢复能力需提升",
                description: "被打断后的恢复率仅 \(Int(averageRecoveryRate * 100))%，需要提高重新进入专注状态的能力。",
                impact: .medium,
                actionable: true,
                suggestions: [
                    "被打断后立即记录当前进度",
                    "设置5分钟的重新专注缓冲时间",
                    "练习快速进入专注状态的技巧"
                ],
                metrics: ["recoveryRate": averageRecoveryRate],
                icon: "arrow.clockwise",
                color: .orange
            ))
        }
        
        return insights
    }
    
    private func generateTimeSlotInsights(from analysis: FocusTimeSlotAnalysis) -> [FocusInsight] {
        var insights: [FocusInsight] = []
        
        // 找出最佳时段
        let bestScore = max(analysis.morningFocusScore, analysis.afternoonFocusScore, analysis.eveningFocusScore)
        var bestTimeSlot = ""
        
        if analysis.morningFocusScore == bestScore {
            bestTimeSlot = "上午"
        } else if analysis.afternoonFocusScore == bestScore {
            bestTimeSlot = "下午"
        } else {
            bestTimeSlot = "晚上"
        }
        
        insights.append(FocusInsight(
            type: .timeSlot,
            title: "最佳专注时段：\(bestTimeSlot)",
            description: "你在\(bestTimeSlot)的专注效果最好，评分为 \(Int(bestScore)) 分。建议在这个时段安排重要工作。",
            impact: .low,
            actionable: true,
            suggestions: [
                "将最重要的任务安排在\(bestTimeSlot)",
                "在最佳时段避免会议和其他干扰",
                "保护好你的黄金专注时间"
            ],
            metrics: ["bestScore": bestScore],
            icon: "clock.badge.checkmark",
            color: .green
        ))
        
        // 分析需要改进的时段
        let worstScore = min(analysis.morningFocusScore, analysis.afternoonFocusScore, analysis.eveningFocusScore)
        if worstScore < 40 {
            var worstTimeSlot = ""
            if analysis.morningFocusScore == worstScore {
                worstTimeSlot = "上午"
            } else if analysis.afternoonFocusScore == worstScore {
                worstTimeSlot = "下午"
            } else {
                worstTimeSlot = "晚上"
            }
            
            insights.append(FocusInsight(
                type: .timeSlot,
                title: "\(worstTimeSlot)专注效果较差",
                description: "\(worstTimeSlot)的专注评分仅 \(Int(worstScore)) 分，可以考虑调整这个时段的工作安排。",
                impact: .medium,
                actionable: true,
                suggestions: [
                    "在\(worstTimeSlot)安排轻松的任务",
                    "分析影响\(worstTimeSlot)专注的因素",
                    "尝试在这个时段进行短暂休息"
                ],
                metrics: ["worstScore": worstScore],
                icon: "clock.badge.exclamationmark",
                color: .orange
            ))
        }
        
        return insights
    }
    
    private func generateSuggestions(from metrics: [FocusQualityMetrics], interruptions: [InterruptionAnalysis]) -> [FocusInsight] {
        var insights: [FocusInsight] = []
        
        // 基于整体数据生成个性化建议
        let totalFocusTime = metrics.reduce(0) { $0 + $1.deepFocusTime + $1.mediumFocusTime + $1.fragmentedTime }
        let averageQuality = metrics.reduce(0) { $0 + $1.focusQualityScore } / Double(metrics.count)
        
        if totalFocusTime < 10 * 3600 { // 少于10小时
            insights.append(FocusInsight(
                type: .suggestion,
                title: "增加专注时间",
                description: "本周总专注时间较少，建议逐步增加每日的专注时长。",
                impact: .medium,
                actionable: true,
                suggestions: [
                    "设定每日最低专注时间目标",
                    "使用时间块规划法安排专注时间",
                    "从短时间开始，逐步延长专注时长"
                ],
                metrics: ["totalHours": totalFocusTime / 3600],
                icon: "plus.circle",
                color: .blue
            ))
        }
        
        if averageQuality > 70 {
            insights.append(FocusInsight(
                type: .suggestion,
                title: "保持优秀习惯",
                description: "你的专注习惯很好！可以考虑挑战更高的目标。",
                impact: .low,
                actionable: true,
                suggestions: [
                    "尝试更长时间的深度专注会话",
                    "分享你的专注技巧给他人",
                    "设定更具挑战性的专注目标"
                ],
                metrics: ["averageQuality": averageQuality],
                icon: "trophy",
                color: .gold
            ))
        }
        
        return insights
    }
}

/// 专注洞察卡片视图
struct FocusInsightCard: View {
    let insight: FocusInsight
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行
            HStack {
                Image(systemName: insight.icon)
                    .font(.title2)
                    .foregroundColor(insight.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(insight.type.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(insight.color.opacity(0.2))
                            .foregroundColor(insight.color)
                            .cornerRadius(8)
                        
                        Text(insight.impact.rawValue + "影响")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(insight.impact.color.opacity(0.2))
                            .foregroundColor(insight.impact.color)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // 描述
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(isExpanded ? nil : 2)
            
            // 展开内容
            if isExpanded && !insight.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("建议行动")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    ForEach(Array(insight.suggestions.enumerated()), id: \.offset) { index, suggestion in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 16, alignment: .leading)
                            
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

struct FocusInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        FocusInsightsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}