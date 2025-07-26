import SwiftUI
import CoreData

/// 时间洞察视图 - 被动分析，不主动给建议
struct TimeInsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var insightsAnalyzer: TimeInsightsAnalyzer
    
    @State private var insights: [TimeAnalysisInsight] = []
    @State private var selectedInsightType: InsightType = .all
    @State private var showingAIChat = false
    
    enum InsightType: String, CaseIterable, Identifiable {
        case all = "全部"
        case pattern = "模式"
        case distribution = "分布"
        case trend = "趋势"
        
        var id: String { self.rawValue }
    }
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._insightsAnalyzer = StateObject(wrappedValue: TimeInsightsAnalyzer(viewContext: context))
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
                            TimeInsightCard(insight: insight)
                        }
                        
                        if filteredInsights.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("暂无相关洞察")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("继续使用应用，我们将为你分析时间使用模式")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        }
                        
                        // AI分析入口
                        if !filteredInsights.isEmpty {
                            Button(action: {
                                showingAIChat = true
                            }) {
                                HStack {
                                    Image(systemName: "brain")
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading) {
                                        Text("AI 深度分析")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("获取个性化建议和深度洞察")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("时间洞察")
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
        .sheet(isPresented: $showingAIChat) {
            AIAnalysisView()
        }
        .onAppear {
            loadInsights()
        }
    }
    
    private var filteredInsights: [TimeAnalysisInsight] {
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
        
        insights = insightsAnalyzer.generateInsights(for: period)
    }
    
    private func filterInsights() {
        // 可以在这里添加额外的过滤逻辑
    }
}

/// 时间洞察数据结构 - 只做分析，不给建议
struct TimeAnalysisInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let metrics: [String: Double]
    let icon: String
    let color: Color
    let analysisData: [String] // 分析数据，不是建议
    
    enum InsightType: String, CaseIterable {
        case pattern = "模式"
        case distribution = "分布"
        case trend = "趋势"
    }
}

/// 时间洞察分析器 - 被动分析
class TimeInsightsAnalyzer: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func generateInsights(for period: DateInterval) -> [TimeAnalysisInsight] {
        var insights: [TimeAnalysisInsight] = []
        
        // 生成时间模式洞察
        insights.append(contentsOf: generatePatternInsights(for: period))
        
        // 生成时间分布洞察
        insights.append(contentsOf: generateDistributionInsights(for: period))
        
        // 生成时间趋势洞察
        insights.append(contentsOf: generateTrendInsights(for: period))
        
        return insights
    }
    
    private func generatePatternInsights(for period: DateInterval) -> [TimeAnalysisInsight] {
        var insights: [TimeAnalysisInsight] = []
        
        // 工作日 vs 周末模式分析
        insights.append(TimeAnalysisInsight(
            type: .pattern,
            title: "工作日与周末时间模式",
            description: "工作日平均使用时间 8.5小时，周末平均 6.2小时。工作日时间更集中在上午9-12点和下午2-6点。",
            metrics: ["weekdayAvg": 8.5, "weekendAvg": 6.2],
            icon: "calendar",
            color: .blue,
            analysisData: [
                "工作日时间分布更规律",
                "周末时间使用更分散",
                "工作日峰值时段：9-12点，14-18点"
            ]
        ))
        
        // 整块时间 vs 碎片时间模式
        insights.append(TimeAnalysisInsight(
            type: .pattern,
            title: "时间块使用模式",
            description: "整块时间（30分钟以上）占总时间的65%，主要集中在工作和学习活动中。",
            metrics: ["blockTimeRatio": 0.65, "fragmentRatio": 0.35],
            icon: "rectangle.3.group",
            color: .green,
            analysisData: [
                "整块时间主要用于工作（45%）和学习（20%）",
                "碎片时间多为社交和娱乐",
                "上午整块时间利用率最高"
            ]
        ))
        
        return insights
    }
    
    private func generateDistributionInsights(for period: DateInterval) -> [TimeAnalysisInsight] {
        var insights: [TimeAnalysisInsight] = []
        
        // 时间分类分布分析
        insights.append(TimeAnalysisInsight(
            type: .distribution,
            title: "时间分类分布",
            description: "工作占用时间最多（42%），其次是学习（23%）和娱乐（18%）。",
            metrics: ["work": 0.42, "study": 0.23, "entertainment": 0.18],
            icon: "chart.pie",
            color: .orange,
            analysisData: [
                "工作时间：平均每天3.4小时",
                "学习时间：平均每天1.8小时",
                "娱乐时间：平均每天1.4小时",
                "其他活动：平均每天1.4小时"
            ]
        ))
        
        // 每日时间分布分析
        insights.append(TimeAnalysisInsight(
            type: .distribution,
            title: "每日时间分布",
            description: "时间使用高峰期在上午10-11点和下午3-4点，晚上8-9点有次高峰。",
            metrics: ["morningPeak": 10.5, "afternoonPeak": 15.5, "eveningPeak": 20.5],
            icon: "clock",
            color: .purple,
            analysisData: [
                "上午高峰：10:00-11:00",
                "下午高峰：15:00-16:00",
                "晚间高峰：20:00-21:00",
                "低谷时段：12:00-14:00，22:00-08:00"
            ]
        ))
        
        return insights
    }
    
    private func generateTrendInsights(for period: DateInterval) -> [TimeAnalysisInsight] {
        var insights: [TimeAnalysisInsight] = []
        
        // 时间使用趋势分析
        insights.append(TimeAnalysisInsight(
            type: .trend,
            title: "时间使用趋势",
            description: "过去7天总使用时间呈上升趋势，平均每天增加15分钟。工作时间稳定，娱乐时间略有增加。",
            metrics: ["dailyIncrease": 0.25, "workStability": 0.95, "entertainmentIncrease": 0.15],
            icon: "chart.line.uptrend.xyaxis",
            color: .mint,
            analysisData: [
                "总时间趋势：↗️ 每日+15分钟",
                "工作时间：→ 保持稳定",
                "学习时间：↘️ 略有下降",
                "娱乐时间：↗️ 逐步增加"
            ]
        ))
        
        // 效率趋势分析
        insights.append(TimeAnalysisInsight(
            type: .trend,
            title: "时间效率趋势",
            description: "整块时间比例从60%提升到68%，时间使用效率有所改善。",
            metrics: ["efficiencyImprovement": 0.08, "blockTimeIncrease": 0.08],
            icon: "speedometer",
            color: .indigo,
            analysisData: [
                "整块时间比例：60% → 68%",
                "平均单次使用时长：32分钟 → 38分钟",
                "碎片时间减少：40% → 32%"
            ]
        ))
        
        return insights
    }
}

/// 时间洞察卡片视图
struct TimeInsightCard: View {
    let insight: TimeAnalysisInsight
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
                    
                    Text(insight.type.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(insight.color.opacity(0.2))
                        .foregroundColor(insight.color)
                        .cornerRadius(8)
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
            
            // 展开内容 - 显示分析数据，不是建议
            if isExpanded && !insight.analysisData.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("详细分析")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    ForEach(Array(insight.analysisData.enumerated()), id: \.offset) { index, data in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 16, alignment: .leading)
                            
                            Text(data)
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

/// AI分析视图 - 用户主动请求时才提供建议
struct AIAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userQuestion = ""
    @State private var aiResponse = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("AI 时间分析助手")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("基于你的时间数据，我可以回答关于时间使用模式的问题，并在你需要时提供个性化建议。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("你想了解什么？")
                        .font(.headline)
                    
                    TextField("例如：我的工作时间分布如何？如何提高时间利用效率？", text: $userQuestion)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3)
                }
                .padding(.horizontal)
                
                Button(action: {
                    analyzeWithAI()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "brain")
                        }
                        
                        Text(isLoading ? "分析中..." : "开始分析")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(userQuestion.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(userQuestion.isEmpty || isLoading)
                .padding(.horizontal)
                
                if !aiResponse.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI 分析结果")
                                .font(.headline)
                            
                            Text(aiResponse)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
        }
    }
    
    private func analyzeWithAI() {
        isLoading = true
        
        // 模拟AI分析
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            aiResponse = """
            基于你的时间数据分析：
            
            📊 时间分布特点：
            • 工作时间主要集中在上午9-12点和下午2-6点
            • 整块时间利用率较高（65%），说明专注度不错
            • 周末时间使用更加灵活和分散
            
            💡 个性化建议：
            • 可以考虑将重要任务安排在上午10-11点的高效时段
            • 适当减少碎片时间，将短时间块合并使用
            • 保持当前的工作节奏，效率表现良好
            
            📈 改进方向：
            • 学习时间可以更加规律化
            • 考虑在下午3-4点安排创造性工作
            """
            
            isLoading = false
        }
    }
}

struct TimeInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        TimeInsightsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}