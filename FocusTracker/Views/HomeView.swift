import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var focusManager: FocusManager
    @StateObject private var tagManager: TagManager
    @StateObject private var timeAnalysisManager: TimeAnalysisManager
    @State private var todaysUsageTime: TimeInterval = 0
    @State private var todaysTagDistribution: [TagDistribution] = []
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FocusSession.startTime, ascending: false)],
        animation: .default)
    private var focusSessions: FetchedResults<FocusSession>
    
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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 专注时间概览
                    FocusTimeOverviewCard()
                    
                    // 今日标签分布
                    TodayTagDistributionCard()
                    
                    // 时间使用洞察
                    TimeInsightsCard()
                }
                .padding()
            }
            .navigationTitle("我的时间")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            timeAnalysisManager.startMonitoring()
            updateTodaysData()
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateTodaysData() {
        todaysUsageTime = timeAnalysisManager.todaysUsageTime
        todaysTagDistribution = tagManager.getTagDistribution(for: Date())
    }
}

// MARK: - Focus Time Overview Card
struct FocusTimeOverviewCard: View {
    @EnvironmentObject private var focusManager: FocusManager
    @Environment(\.managedObjectContext) private var viewContext
    @State private var dailyGoal: TimeInterval = 2 * 60 * 60 // Default 2 hours
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("今日专注时间")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Focus Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: min(focusManager.todaysFocusTime / dailyGoal, 1.0))
                    .stroke(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: focusManager.todaysFocusTime)
                
                // Center content
                VStack(spacing: 4) {
                    Text(formatTime(focusManager.todaysFocusTime))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("/ \(formatTime(dailyGoal))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Goal status message
            HStack {
                Image(systemName: goalStatusIcon)
                    .foregroundColor(goalStatusColor)
                
                Text(goalStatusMessage)
                    .font(.subheadline)
                    .foregroundColor(goalStatusColor)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            loadDailyGoal()
        }
    }
    
    private func loadDailyGoal() {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try viewContext.fetch(request)
            if let userSettings = settings.first {
                dailyGoal = userSettings.dailyFocusGoal
            }
        } catch {
            print("Error loading daily goal: \(error)")
        }
    }
    
    private var goalStatusIcon: String {
        if focusManager.todaysFocusTime >= dailyGoal {
            return "checkmark.circle.fill"
        } else if focusManager.todaysFocusTime >= dailyGoal * 0.5 {
            return "clock.fill"
        } else {
            return "target"
        }
    }
    
    private var goalStatusColor: Color {
        if focusManager.todaysFocusTime >= dailyGoal {
            return .green
        } else if focusManager.todaysFocusTime >= dailyGoal * 0.5 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var goalStatusMessage: String {
        if focusManager.todaysFocusTime >= dailyGoal {
            return "今日目标已达成！"
        } else if focusManager.todaysFocusTime >= dailyGoal * 0.5 {
            return "已完成一半目标，继续加油！"
        } else {
            let remaining = dailyGoal - focusManager.todaysFocusTime
            return "还需 \(formatTime(remaining)) 达成目标"
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

// MARK: - Today Tag Distribution Card
struct TodayTagDistributionCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var tagManager: TagManager
    @State private var tagDistribution: [TagDistribution] = []
    @State private var totalTaggedTime: TimeInterval = 0
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._tagManager = StateObject(wrappedValue: TagManager(viewContext: context))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("今日时间分类")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if tagDistribution.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("暂无标签分类数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(tagDistribution.prefix(4)), id: \.tagName) { distribution in
                        TagDistributionRow(distribution: distribution, totalTime: totalTaggedTime)
                    }
                    
                    if tagDistribution.count > 4 {
                        HStack {
                            Text("还有 \(tagDistribution.count - 4) 个标签")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            loadTodayTagDistribution()
        }
    }
    
    private func loadTodayTagDistribution() {
        tagDistribution = tagManager.getTagDistribution(for: Date())
        totalTaggedTime = tagDistribution.reduce(0) { $0 + $1.usageTime }
    }
}

struct TagDistributionRow: View {
    let distribution: TagDistribution
    let totalTime: TimeInterval
    
    var body: some View {
        HStack(spacing: 12) {
            // 标签颜色指示器
            Circle()
                .fill(tagColor)
                .frame(width: 12, height: 12)
            
            // 标签信息
            VStack(alignment: .leading, spacing: 2) {
                Text(distribution.tagName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(distribution.sessionCount) 次使用")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 时间和百分比
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(distribution.usageTime))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\(Int(percentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var tagColor: Color {
        // 根据标签类型返回不同颜色
        switch distribution.tagName {
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
    
    private var percentage: Double {
        guard totalTime > 0 else { return 0 }
        return (distribution.usageTime / totalTime) * 100
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



// MARK: - Time Insights Card
struct TimeInsightsCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var focusManager: FocusManager
    @State private var insights: [TimeInsight] = []
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("时间洞察")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if insights.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("继续使用以获得时间洞察")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(insights, id: \.id) { insight in
                        InsightRow(insight: insight)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            generateInsights()
        }
    }
    
    private func generateInsights() {
        // 生成基于专注时间的简单洞察
        var newInsights: [TimeInsight] = []
        
        // 获取今日专注时间
        let todaysFocusTime = focusManager.todaysFocusTime
        let hours = Int(todaysFocusTime) / 3600
        let minutes = Int(todaysFocusTime.truncatingRemainder(dividingBy: 3600)) / 60
        
        if todaysFocusTime > 0 {
            if hours > 0 {
                newInsights.append(TimeInsight(
                    id: "focus_time",
                    icon: "brain.head.profile",
                    title: "今日已专注 \(hours) 小时 \(minutes) 分钟",
                    description: "保持专注，继续加油！",
                    color: .green
                ))
            } else if minutes > 0 {
                newInsights.append(TimeInsight(
                    id: "focus_time",
                    icon: "brain.head.profile",
                    title: "今日已专注 \(minutes) 分钟",
                    description: "良好的开始！",
                    color: .green
                ))
            }
        } else {
            newInsights.append(TimeInsight(
                id: "no_focus",
                icon: "target",
                title: "今日还未开始专注",
                description: "开始您的第一个专注时段吧",
                color: .blue
            ))
        }
        
        // 获取本周专注统计
        let weeklyData = focusManager.getWeeklyTrend()
        let weeklyTotal = weeklyData.reduce(0) { $0 + $1.totalFocusTime }
        let weeklyHours = Int(weeklyTotal) / 3600
        
        if weeklyHours > 0 {
            newInsights.append(TimeInsight(
                id: "weekly_focus",
                icon: "calendar",
                title: "本周已专注 \(weeklyHours) 小时",
                description: "专注习惯正在养成",
                color: .orange
            ))
        }
        
        insights = newInsights
    }
}

struct TimeInsight {
    let id: String
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct InsightRow: View {
    let insight: TimeInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundColor(insight.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}



// 测试代码已移至FocusTrackerTests目标

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let focusManager = FocusManager(
            usageMonitor: UsageMonitor(),
            viewContext: context
        )
        
        HomeView()
            .environment(\.managedObjectContext, context)
            .environmentObject(focusManager)
    }
}