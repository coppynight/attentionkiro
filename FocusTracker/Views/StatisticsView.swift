import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var focusManager: FocusManager
    @StateObject private var tagManager: TagManager
    @StateObject private var timeAnalysisManager: TimeAnalysisManager
    @StateObject private var focusQualityAnalyzer: FocusQualityAnalyzer
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var personalBestRecord: (duration: TimeInterval, date: Date)?
    @State private var selectedAnalysisTab: AnalysisTab = .overview
    
    enum AnalysisTab: String, CaseIterable, Identifiable {
        case overview = "概览"
        case quality = "专注质量"
        case interruptions = "打断分析"
        case timeSlots = "时段分析"
        
        var id: String { self.rawValue }
    }
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._tagManager = StateObject(wrappedValue: TagManager(viewContext: context))
        self._focusQualityAnalyzer = StateObject(wrappedValue: FocusQualityAnalyzer(viewContext: context))
        
        // Initialize TimeAnalysisManager with dependencies
        let focusManager = FocusManager(
            usageMonitor: UsageMonitor(),
            viewContext: context
        )
        let tagManager = TagManager(viewContext: context)
        self._timeAnalysisManager = StateObject(wrappedValue: TimeAnalysisManager(
            viewContext: context,
            focusManager: focusManager,
            tagManager: tagManager
        ))
    }
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "7天"
        case month = "30天"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 分析标签选择器
                Picker("分析类型", selection: $selectedAnalysisTab) {
                    ForEach(AnalysisTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedAnalysisTab {
                        case .overview:
                            // 原有的概览视图
                            FocusTimeTrendView()
                            TagUsageAnalysisView()
                            FocusTimeStatsView()
                            
                        case .quality:
                            // 专注质量分析
                            FocusQualityView()
                            
                        case .interruptions:
                            // 打断分析
                            InterruptionAnalysisView()
                            
                        case .timeSlots:
                            // 时段分析
                            TimeSlotAnalysisView()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("时间分析")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadPersonalBestRecord()
            timeAnalysisManager.startMonitoring()
        }
    }
    
    private func loadPersonalBestRecord() {
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.predicate = NSPredicate(format: "isValid == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.duration, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let bestSession = results.first {
                personalBestRecord = (bestSession.duration, bestSession.startTime)
            }
        } catch {
            print("Error fetching personal best record: \(error)")
        }
    }
}

// MARK: - Focus Time Trend View
struct FocusTimeTrendView: View {
    @EnvironmentObject private var focusManager: FocusManager
    @State private var weeklyData: [DailyFocusData] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("7天专注趋势")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if weeklyData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("暂无足够数据显示趋势")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            } else {
                // 简化的条形图
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weeklyData, id: \.date) { day in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                                .frame(height: calculateBarHeight(day.totalFocusTime))
                            
                            Text(formatDayOfWeek(day.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100)
                
                HStack {
                    Text("平均每日: \(formatTime(averageDailyTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("本周总计: \(formatTime(totalWeeklyTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            loadWeeklyData()
        }
    }
    
    private var averageDailyTime: TimeInterval {
        guard !weeklyData.isEmpty else { return 0 }
        return weeklyData.reduce(0) { $0 + $1.totalFocusTime } / Double(weeklyData.count)
    }
    
    private var totalWeeklyTime: TimeInterval {
        weeklyData.reduce(0) { $0 + $1.totalFocusTime }
    }
    
    private func calculateBarHeight(_ duration: TimeInterval) -> CGFloat {
        let maxHeight: CGFloat = 80
        guard !weeklyData.isEmpty else { return 4 }
        let maxTime = weeklyData.max(by: { $0.totalFocusTime < $1.totalFocusTime })?.totalFocusTime ?? 1
        guard maxTime > 0 else { return 4 }
        let ratio = duration / maxTime
        return max(maxHeight * CGFloat(ratio), 4)
    }
    
    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func loadWeeklyData() {
        weeklyData = focusManager.getWeeklyTrend()
    }
}

// 使用TimeAnalysisManager中的DailyUsageData

// MARK: - Tag Usage Analysis View
struct TagUsageAnalysisView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var tagManager: TagManager
    @State private var weeklyTagData: [WeeklyTagData] = []
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._tagManager = StateObject(wrappedValue: TagManager(viewContext: context))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("标签使用分析")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if weeklyTagData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("暂无标签使用数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(weeklyTagData.prefix(5), id: \.tagName) { tagData in
                        WeeklyTagRow(tagData: tagData)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            loadWeeklyTagData()
        }
    }
    
    private func loadWeeklyTagData() {
        let calendar = Calendar.current
        let today = Date()
        
        // 获取本周的标签分布数据
        var tagTotals: [String: TimeInterval] = [:]
        var tagCounts: [String: Int] = [:]
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let dayDistribution = tagManager.getTagDistribution(for: date)
            
            for distribution in dayDistribution {
                let tagName = distribution.tagName
                tagTotals[tagName, default: 0] += distribution.usageTime
                tagCounts[tagName, default: 0] += distribution.sessionCount
            }
        }
        
        // 转换为WeeklyTagData数组并排序
        weeklyTagData = tagTotals.map { (tagName, totalTime) in
            WeeklyTagData(
                tagName: tagName,
                totalTime: totalTime,
                sessionCount: tagCounts[tagName] ?? 0,
                averageDailyTime: totalTime / 7
            )
        }.sorted { $0.totalTime > $1.totalTime }
    }
}

struct WeeklyTagData {
    let tagName: String
    let totalTime: TimeInterval
    let sessionCount: Int
    let averageDailyTime: TimeInterval
}

struct WeeklyTagRow: View {
    let tagData: WeeklyTagData
    
    var body: some View {
        HStack(spacing: 12) {
            // 标签颜色指示器
            Circle()
                .fill(tagColor)
                .frame(width: 12, height: 12)
            
            // 标签信息
            VStack(alignment: .leading, spacing: 2) {
                Text(tagData.tagName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("平均每日 \(formatTime(tagData.averageDailyTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 本周总时间
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(tagData.totalTime))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\(tagData.sessionCount) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var tagColor: Color {
        // 根据标签类型返回不同颜色
        switch tagData.tagName {
        case "工作":
            return .blue
        case "学习":
            return .green
        case "娱乐":
            return .orange
        case "社交":
            return .pink
        case "健康":
            return .red
        case "购物":
            return .purple
        case "出行":
            return .cyan
        default:
            return .gray
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// 移除了应用使用相关功能

// MARK: - Focus Time Stats View
struct FocusTimeStatsView: View {
    @EnvironmentObject private var focusManager: FocusManager
    @State private var personalBest: (duration: TimeInterval, date: Date)?
    @State private var weeklyFocusTime: TimeInterval = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("专注时间统计")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // 今日专注时间
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Text("今日专注")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(formatTime(focusManager.todaysFocusTime))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                // 本周专注时间
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("本周专注")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(formatTime(weeklyFocusTime))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                // 个人最佳记录
                if let best = personalBest {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        Text("最佳记录")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formatTime(best.duration))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            loadFocusStats()
        }
    }
    
    private func loadFocusStats() {
        // 加载本周专注时间
        let weeklyData = focusManager.getWeeklyTrend()
        weeklyFocusTime = weeklyData.reduce(0) { $0 + $1.totalFocusTime }
        
        // 加载个人最佳记录
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.predicate = NSPredicate(format: "isValid == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.duration, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let results = try PersistenceController.shared.container.viewContext.fetch(request)
            if let bestSession = results.first {
                personalBest = (bestSession.duration, bestSession.startTime)
            }
        } catch {
            print("Error fetching personal best record: \(error)")
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}



// MARK: - Focus Quality View
struct FocusQualityView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var focusQualityAnalyzer: FocusQualityAnalyzer
    @State private var todayMetrics: FocusQualityMetrics?
    @State private var weeklyMetrics: [FocusQualityMetrics] = []
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._focusQualityAnalyzer = StateObject(wrappedValue: FocusQualityAnalyzer(viewContext: context))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 今日专注质量概览
            if let metrics = todayMetrics {
                VStack(alignment: .leading, spacing: 16) {
                    Text("今日专注质量")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // 质量评分
                    HStack {
                        VStack(alignment: .leading) {
                            Text("专注质量评分")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(metrics.focusQualityScore))")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(qualityScoreColor(metrics.focusQualityScore))
                        }
                        
                        Spacer()
                        
                        // 质量评分环形图
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(metrics.focusQualityScore / 100))
                                .stroke(qualityScoreColor(metrics.focusQualityScore), 
                                       style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                        }
                    }
                    
                    // 时间分布
                    VStack(spacing: 12) {
                        FocusTimeBreakdownRow(
                            title: "深度专注",
                            time: metrics.deepFocusTime,
                            color: .green,
                            icon: "brain.head.profile"
                        )
                        
                        FocusTimeBreakdownRow(
                            title: "中等专注",
                            time: metrics.mediumFocusTime,
                            color: .orange,
                            icon: "clock"
                        )
                        
                        FocusTimeBreakdownRow(
                            title: "碎片时间",
                            time: metrics.fragmentedTime,
                            color: .red,
                            icon: "timer"
                        )
                    }
                    
                    // 打断信息
                    HStack {
                        VStack(alignment: .leading) {
                            Text("打断次数")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(metrics.interruptionCount)")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("最长专注")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatTime(metrics.longestFocusStreak))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            
            // 7天专注质量趋势
            VStack(alignment: .leading, spacing: 16) {
                Text("7天质量趋势")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if weeklyMetrics.isEmpty {
                    Text("暂无足够数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(height: 100)
                } else {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(weeklyMetrics, id: \.date) { dayMetrics in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(qualityScoreColor(dayMetrics.focusQualityScore))
                                    .frame(height: CGFloat(dayMetrics.focusQualityScore))
                                
                                Text(formatDayOfWeek(dayMetrics.date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 120)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .onAppear {
            loadQualityMetrics()
        }
    }
    
    private func loadQualityMetrics() {
        let today = Date()
        todayMetrics = focusQualityAnalyzer.analyzeFocusQuality(for: today)
        
        // 加载7天数据
        let calendar = Calendar.current
        weeklyMetrics = (0..<7).compactMap { i in
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return nil }
            return focusQualityAnalyzer.analyzeFocusQuality(for: date)
        }.reversed()
    }
    
    private func qualityScoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100:
            return .green
        case 60..<80:
            return .orange
        case 40..<60:
            return .yellow
        default:
            return .red
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

struct FocusTimeBreakdownRow: View {
    let title: String
    let time: TimeInterval
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(formatTime(time))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Interruption Analysis View
struct InterruptionAnalysisView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var focusQualityAnalyzer: FocusQualityAnalyzer
    @State private var todayAnalysis: InterruptionAnalysis?
    @State private var weeklyInterruptions: [Int] = []
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._focusQualityAnalyzer = StateObject(wrappedValue: FocusQualityAnalyzer(viewContext: context))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 今日打断分析
            if let analysis = todayAnalysis {
                VStack(alignment: .leading, spacing: 16) {
                    Text("今日打断分析")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // 打断统计
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(analysis.totalInterruptions)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("总打断次数")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(Int(analysis.interruptionRecoveryRate * 100))%")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("恢复率")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(analysis.mostCommonInterruptionHour):00")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("高发时段")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 打断类型分布
                    if !analysis.interruptionsByType.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("打断类型分布")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(Array(analysis.interruptionsByType.keys.sorted()), id: \.self) { type in
                                HStack {
                                    Text(type)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Text("\(analysis.interruptionsByType[type] ?? 0) 次")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            
            // 7天打断趋势
            VStack(alignment: .leading, spacing: 16) {
                Text("7天打断趋势")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if weeklyInterruptions.isEmpty {
                    Text("暂无足够数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(height: 100)
                } else {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(Array(weeklyInterruptions.enumerated()), id: \.offset) { index, count in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(interruptionColor(count))
                                    .frame(height: max(CGFloat(count * 10), 4))
                                
                                Text(dayLabel(for: index))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 120)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .onAppear {
            loadInterruptionAnalysis()
        }
    }
    
    private func loadInterruptionAnalysis() {
        let today = Date()
        todayAnalysis = focusQualityAnalyzer.analyzeInterruptions(for: today)
        
        // 加载7天打断数据
        let calendar = Calendar.current
        weeklyInterruptions = (0..<7).map { i in
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return 0 }
            let analysis = focusQualityAnalyzer.analyzeInterruptions(for: date)
            return analysis.totalInterruptions
        }.reversed()
    }
    
    private func interruptionColor(_ count: Int) -> Color {
        switch count {
        case 0...2:
            return .green
        case 3...5:
            return .orange
        default:
            return .red
        }
    }
    
    private func dayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let today = Date()
        guard let date = calendar.date(byAdding: .day, value: -(6-index), to: today) else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Time Slot Analysis View
struct TimeSlotAnalysisView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var focusQualityAnalyzer: FocusQualityAnalyzer
    @State private var timeSlotAnalysis: FocusTimeSlotAnalysis?
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._focusQualityAnalyzer = StateObject(wrappedValue: FocusQualityAnalyzer(viewContext: context))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 时段评分
            if let analysis = timeSlotAnalysis {
                VStack(alignment: .leading, spacing: 16) {
                    Text("时段专注评分")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        TimeSlotScoreRow(
                            title: "上午 (6:00-12:00)",
                            score: analysis.morningFocusScore,
                            icon: "sunrise"
                        )
                        
                        TimeSlotScoreRow(
                            title: "下午 (12:00-18:00)",
                            score: analysis.afternoonFocusScore,
                            icon: "sun.max"
                        )
                        
                        TimeSlotScoreRow(
                            title: "晚上 (18:00-22:00)",
                            score: analysis.eveningFocusScore,
                            icon: "moon"
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // 最佳和最差时段
                VStack(alignment: .leading, spacing: 16) {
                    Text("专注时段分析")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("最佳时段")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            ForEach(analysis.bestFocusHours, id: \.self) { hour in
                                Text("\(hour):00-\(hour+1):00")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("需改进时段")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            ForEach(analysis.worstFocusHours, id: \.self) { hour in
                                Text("\(hour):00-\(hour+1):00")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
        }
        .onAppear {
            loadTimeSlotAnalysis()
        }
    }
    
    private func loadTimeSlotAnalysis() {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let period = DateInterval(start: weekAgo, end: today)
        
        timeSlotAnalysis = focusQualityAnalyzer.analyzeFocusTimeSlots(for: period)
    }
}

struct TimeSlotScoreRow: View {
    let title: String
    let score: Double
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(scoreColor(score))
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(Int(score))")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(scoreColor(score))
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 70...100:
            return .green
        case 40..<70:
            return .orange
        default:
            return .red
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let focusManager = FocusManager(
            usageMonitor: UsageMonitor(),
            viewContext: context
        )
        
        StatisticsView()
            .environment(\.managedObjectContext, context)
            .environmentObject(focusManager)
    }
}