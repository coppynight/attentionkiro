import SwiftUI
import CoreData

/// InsightsView - 智能分析洞察界面
/// 展示LifeAnalyzer生成的各种分析报告和优化建议
struct InsightsView: View {
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State Objects
    
    @StateObject private var lifeAnalyzer: LifeAnalyzer
    
    // MARK: - State Variables
    
    @State private var selectedAnalysisType: AnalysisType = .daily
    @State private var selectedDate = Date()
    @State private var dailyReport: DailyAnalysisReport?
    @State private var weeklyReport: WeeklyAnalysisReport?
    @State private var patternAnalysis: UsagePatternAnalysis?
    @State private var showingDetailSheet = false
    @State private var selectedSuggestion: OptimizationSuggestion?
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self._lifeAnalyzer = StateObject(wrappedValue: LifeAnalyzer(viewContext: viewContext))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 分析类型选择器
                analysisTypeSelector
                
                // 主要内容
                ScrollView {
                    VStack(spacing: 20) {
                        // 分析内容
                        switch selectedAnalysisType {
                        case .daily:
                            dailyAnalysisSection
                        case .weekly:
                            weeklyAnalysisSection
                        case .comprehensive:
                            comprehensiveAnalysisSection
                        }
                        
                        // 优化建议
                        suggestionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("智能洞察")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刷新") {
                        refreshAnalysis()
                    }
                    .disabled(lifeAnalyzer.isAnalyzing)
                }
            }
        }
        .sheet(item: $selectedSuggestion) { suggestion in
            SuggestionDetailSheet(suggestion: suggestion) {
                selectedSuggestion = nil
            }
        }
        .onAppear {
            refreshAnalysis()
        }
    }
    
    // MARK: - View Components
    
    /// 分析类型选择器
    private var analysisTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach([AnalysisType.daily, .weekly, .comprehensive], id: \.self) { type in
                    Button(action: {
                        selectedAnalysisType = type
                        refreshAnalysis()
                    }) {
                        Text(type.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedAnalysisType == type ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedAnalysisType == type ? Color.blue : Color(.systemGray5))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    /// 每日分析区域
    private var dailyAnalysisSection: some View {
        Group {
            if lifeAnalyzer.isAnalyzing {
                analysisLoadingView
            } else if let report = dailyReport {
                VStack(spacing: 16) {
                    // 日期选择
                    datePickerSection
                    
                    // 总体评分卡片
                    overallScoreCard(report: report)
                    
                    // 基础统计
                    basicStatsCard(stats: report.basicStats)
                    
                    // 专注分析
                    focusAnalysisCard(analysis: report.focusAnalysis)
                    
                    // 标签分析
                    tagAnalysisCard(analysis: report.tagAnalysis)
                }
            } else {
                emptyAnalysisView
            }
        }
    }
    
    /// 每周分析区域
    private var weeklyAnalysisSection: some View {
        Group {
            if lifeAnalyzer.isAnalyzing {
                analysisLoadingView
            } else if let report = weeklyReport {
                VStack(spacing: 16) {
                    // 周统计卡片
                    weeklyStatsCard(stats: report.weeklyStats)
                    
                    // 趋势分析
                    trendAnalysisCard(trends: report.trendAnalysis)
                    
                    // 模式识别
                    if !report.patterns.isEmpty {
                        patternsCard(patterns: report.patterns)
                    }
                }
            } else {
                emptyAnalysisView
            }
        }
    }
    
    /// 综合分析区域
    private var comprehensiveAnalysisSection: some View {
        Group {
            if lifeAnalyzer.isAnalyzing {
                analysisLoadingView
            } else if let analysis = patternAnalysis {
                VStack(spacing: 16) {
                    // 时间模式
                    timePatternCard(patterns: analysis.timePatterns)
                    
                    // 活动模式
                    activityPatternCard(patterns: analysis.activityPatterns)
                    
                    // 专注模式
                    focusPatternCard(patterns: analysis.focusPatterns)
                    
                    // 异常检测
                    if !analysis.anomalies.isEmpty {
                        anomaliesCard(anomalies: analysis.anomalies)
                    }
                }
            } else {
                emptyAnalysisView
            }
        }
    }
    
    /// 建议区域
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("优化建议")
                .font(.headline)
                .fontWeight(.semibold)
            
            let suggestions = getCurrentSuggestions()
            
            if suggestions.isEmpty {
                Text("暂无建议")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                    SuggestionCard(suggestion: suggestion) {
                        selectedSuggestion = suggestion
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 日期选择器
    private var datePickerSection: some View {
        HStack {
            Button(action: {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                refreshAnalysis()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: selectedDate) { _ in
                    refreshAnalysis()
                }
            
            Spacer()
            
            Button(action: {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                refreshAnalysis()
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    /// 总体评分卡片
    private func overallScoreCard(report: DailyAnalysisReport) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("今日评分")
                    .font(.headline)
                Spacer()
                Text(report.scoreGrade)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(gradeColor(report.scoreGrade))
            }
            
            ProgressView(value: report.overallScore)
                .progressViewStyle(LinearProgressViewStyle(tint: gradeColor(report.scoreGrade)))
                .scaleEffect(y: 2)
            
            Text(String(format: "%.1f%%", report.overallScore * 100))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 基础统计卡片
    private func basicStatsCard(stats: DailyBasicStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基础统计")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatItem(title: "时间块", value: "\(stats.totalBlocks)", icon: "square.grid.3x3", color: .blue)
                StatItem(title: "总时长", value: stats.formattedTotalDuration, icon: "clock", color: .green)
                StatItem(title: "标记率", value: String(format: "%.1f%%", stats.taggingRate * 100), icon: "tag", color: .orange)
                StatItem(title: "美好时刻", value: "\(stats.beautifulMoments)", icon: "sparkles", color: .yellow)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 专注分析卡片
    private func focusAnalysisCard(analysis: DailyFocusAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("专注分析")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("平均强度")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", analysis.averageIntensity * 100))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("峰值时间")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(analysis.formattedPeakTime ?? "无")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            // 专注强度分布
            if !analysis.focusDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("强度分布")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(FocusIntensityRange.allCases, id: \.self) { range in
                        let count = analysis.focusDistribution[range] ?? 0
                        if count > 0 {
                            HStack {
                                Circle()
                                    .fill(Color(hex: range.color))
                                    .frame(width: 8, height: 8)
                                Text(range.rawValue)
                                    .font(.caption)
                                Spacer()
                                Text("\(count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 标签分析卡片
    private func tagAnalysisCard(analysis: DailyTagAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("标签分析")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("最常用标签")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(analysis.mostUsedTag ?? "无")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("标签种类")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(analysis.uniqueTagsUsed)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 每周统计卡片
    private func weeklyStatsCard(stats: WeeklyStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周统计")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatItem(title: "总时长", value: stats.formattedTotalDuration, icon: "clock", color: .blue)
                StatItem(title: "日均时长", value: stats.formattedAverageDailyDuration, icon: "calendar", color: .green)
                StatItem(title: "活跃天数", value: "\(stats.activeDays)/7", icon: "checkmark.circle", color: .orange)
                StatItem(title: "一致性", value: String(format: "%.1f%%", stats.consistency * 100), icon: "chart.line.uptrend.xyaxis", color: .purple)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 趋势分析卡片
    private func trendAnalysisCard(trends: WeeklyTrendAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("趋势分析")
                .font(.headline)
            
            VStack(spacing: 8) {
                TrendRow(title: "时长趋势", trend: trends.durationTrend)
                TrendRow(title: "专注趋势", trend: trends.focusTrend)
                TrendRow(title: "活动趋势", trend: trends.activityTrend)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 模式卡片
    private func patternsCard(patterns: [WeeklyPattern]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("识别模式")
                .font(.headline)
            
            ForEach(Array(patterns.enumerated()), id: \.offset) { index, pattern in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pattern.type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(pattern.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", pattern.confidence * 100))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
                
                if index < patterns.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 时间模式卡片
    private func timePatternCard(patterns: TimePatternAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间模式")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("最活跃时段")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(patterns.mostActiveTimeOfDay)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("峰值时间")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(patterns.peakHour != nil ? "\(patterns.peakHour!):00" : "无")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 活动模式卡片
    private func activityPatternCard(patterns: ActivityPatternAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("活动模式")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("主要类别")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(patterns.dominantCategory ?? "无")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("多样性")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(patterns.diversityLevel)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 专注模式卡片
    private func focusPatternCard(patterns: FocusPatternAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("专注模式")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("最佳专注时间")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(patterns.bestFocusHour != nil ? "\(patterns.bestFocusHour!):00" : "无")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("专注稳定性")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(patterns.focusStability)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 异常卡片
    private func anomaliesCard(anomalies: [UsageAnomaly]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("异常检测")
                .font(.headline)
            
            ForEach(Array(anomalies.enumerated()), id: \.offset) { index, anomaly in
                HStack {
                    Circle()
                        .fill(Color(hex: anomaly.severity.color))
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(anomaly.type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(anomaly.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(anomaly.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                if index < anomalies.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 加载视图
    private var analysisLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView(value: lifeAnalyzer.analysisProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .scaleEffect(y: 2)
            
            Text("分析中...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.0f%%", lifeAnalyzer.analysisProgress * 100))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    /// 空分析视图
    private var emptyAnalysisView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("暂无分析数据")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("开始记录时间来获得智能洞察")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func refreshAnalysis() {
        Task {
            switch selectedAnalysisType {
            case .daily:
                dailyReport = await lifeAnalyzer.generateDailyAnalysis(for: selectedDate)
            case .weekly:
                let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
                weeklyReport = await lifeAnalyzer.generateWeeklyAnalysis(for: weekStart)
            case .comprehensive:
                patternAnalysis = await lifeAnalyzer.analyzeUsagePatterns(days: 30)
            }
        }
    }
    
    private func getCurrentSuggestions() -> [OptimizationSuggestion] {
        switch selectedAnalysisType {
        case .daily:
            return dailyReport?.suggestions ?? []
        case .weekly:
            return weeklyReport?.suggestions ?? []
        case .comprehensive:
            return []
        }
    }
    
    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A+", "A": return .green
        case "B+", "B": return .blue
        case "C+", "C": return .orange
        default: return .red
        }
    }
}

// MARK: - Supporting Views

/// 统计项目组件
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

/// 趋势行组件
struct TrendRow: View {
    let title: String
    let trend: TrendDirection
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(Color(hex: trend.color))
                
                Text(trend.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: trend.color))
            }
        }
    }
}

/// 建议卡片组件
struct SuggestionCard: View {
    let suggestion: OptimizationSuggestion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(suggestion.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(suggestion.priority.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: suggestion.priority.color))
                            .cornerRadius(8)
                        
                        Text(String(format: "%.0f%%", suggestion.confidence * 100))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !suggestion.actionItems.isEmpty {
                    Text("• \(suggestion.actionItems.first ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

/// 建议详情弹窗
struct SuggestionDetailSheet: View {
    let suggestion: OptimizationSuggestion
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // 建议信息
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(suggestion.type.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(12)
                        
                        Spacer()
                        
                        Text(suggestion.priority.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: suggestion.priority.color))
                            .cornerRadius(12)
                    }
                    
                    Text(suggestion.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(suggestion.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // 行动建议
                if !suggestion.actionItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("行动建议")
                            .font(.headline)
                        
                        ForEach(Array(suggestion.actionItems.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                
                                Text(item)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                
                // 置信度
                VStack(alignment: .leading, spacing: 8) {
                    Text("建议置信度")
                        .font(.headline)
                    
                    HStack {
                        ProgressView(value: suggestion.confidence)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(y: 2)
                        
                        Text(String(format: "%.0f%%", suggestion.confidence * 100))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("优化建议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions

extension AnalysisType {
    var displayName: String {
        switch self {
        case .daily: return "每日分析"
        case .weekly: return "每周分析"
        case .comprehensive: return "综合分析"
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView(viewContext: PersistenceController.preview.container.viewContext)
    }
}