import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var focusManager: FocusManager
    @StateObject private var tagManager: TagManager
    @StateObject private var timeAnalysisManager: TimeAnalysisManager
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var personalBestRecord: (duration: TimeInterval, date: Date)?
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._tagManager = StateObject(wrappedValue: TagManager(viewContext: context))
        
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
            ScrollView {
                VStack(spacing: 20) {
                    // 专注时间趋势
                    FocusTimeTrendView()
                    
                    // 标签使用分析
                    TagUsageAnalysisView()
                    
                    // 专注时间统计
                    FocusTimeStatsView()
                }
                .padding()
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