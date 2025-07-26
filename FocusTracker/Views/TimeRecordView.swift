import SwiftUI
import CoreData

struct TimeRecordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var focusManager: FocusManager
    @StateObject private var timeRecordManager: TimeRecordManager
    
    @State private var selectedTimeRange: TimeRange = .today
    @State private var showingTimeDetail = false
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case today = "今天"
        case week = "本周"
        case month = "本月"
        
        var id: String { self.rawValue }
    }
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._timeRecordManager = StateObject(wrappedValue: TimeRecordManager(viewContext: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 时间范围选择器
                    Picker("时间范围", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // 时间总览
                    TimeOverviewCard(timeRange: selectedTimeRange, showingTimeDetail: $showingTimeDetail)
                    
                    // 整块时间 vs 碎片时间
                    TimeBlockAnalysisCard(timeRange: selectedTimeRange)
                    
                    // 时间分类记录
                    TimeCategoryCard(timeRange: selectedTimeRange)
                    
                    // 时间分布图表
                    TimeDistributionChart(timeRange: selectedTimeRange)
                }
                .padding()
            }
            .navigationTitle("时间记录")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingTimeDetail) {
            TimeDetailView(timeRange: selectedTimeRange)
        }
        .onAppear {
            timeRecordManager.startMonitoring()
        }
    }
}

// MARK: - Time Overview Card
struct TimeOverviewCard: View {
    let timeRange: TimeRecordView.TimeRange
    @EnvironmentObject private var focusManager: FocusManager
    @State private var totalTime: TimeInterval = 0
    @State private var sessionCount: Int = 0
    @Binding var showingTimeDetail: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(timeRangeTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 30) {
                VStack(alignment: .leading) {
                    Text("总时间")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(totalTime))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading) {
                    Text("记录次数")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(sessionCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: {
                    showingTimeDetail = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("查看明细")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            loadTimeData()
        }
        .onChange(of: timeRange) { _ in
            loadTimeData()
        }
    }
    
    private var timeRangeTitle: String {
        switch timeRange {
        case .today: return "今日时间记录"
        case .week: return "本周时间记录"
        case .month: return "本月时间记录"
        }
    }
    
    private func loadTimeData() {
        let calendar = Calendar.current
        let now = Date()
        
        let (startDate, endDate): (Date, Date)
        switch timeRange {
        case .today:
            startDate = calendar.startOfDay(for: now)
            endDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        case .week:
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            startDate = weekStart
            endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        case .month:
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            startDate = monthStart
            endDate = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        }
        
        // 这里应该从数据库获取实际数据
        // 暂时使用模拟数据
        totalTime = 8 * 3600 // 8小时
        sessionCount = 15
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

// MARK: - Time Block Analysis Card
struct TimeBlockAnalysisCard: View {
    let timeRange: TimeRecordView.TimeRange
    @State private var blockTimeData: TimeBlockData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("时间块分析")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let data = blockTimeData {
                VStack(spacing: 12) {
                    TimeBlockRow(
                        title: "整块时间",
                        subtitle: "连续30分钟以上",
                        time: data.blockTime,
                        color: .green,
                        icon: "rectangle.fill"
                    )
                    
                    TimeBlockRow(
                        title: "中等时间块",
                        subtitle: "15-30分钟",
                        time: data.mediumTime,
                        color: .orange,
                        icon: "rectangle.fill"
                    )
                    
                    TimeBlockRow(
                        title: "碎片时间",
                        subtitle: "15分钟以下",
                        time: data.fragmentTime,
                        color: .red,
                        icon: "rectangle.split.3x1.fill"
                    )
                }
            } else {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 100)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            loadBlockData()
        }
        .onChange(of: timeRange) { _ in
            loadBlockData()
        }
    }
    
    private func loadBlockData() {
        // 模拟数据
        blockTimeData = TimeBlockData(
            blockTime: 4 * 3600,      // 4小时整块时间
            mediumTime: 2 * 3600,     // 2小时中等时间
            fragmentTime: 1.5 * 3600  // 1.5小时碎片时间
        )
    }
}

struct TimeBlockData {
    let blockTime: TimeInterval
    let mediumTime: TimeInterval
    let fragmentTime: TimeInterval
}

struct TimeBlockRow: View {
    let title: String
    let subtitle: String
    let time: TimeInterval
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
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

// MARK: - Time Category Card
struct TimeCategoryCard: View {
    let timeRange: TimeRecordView.TimeRange
    @State private var categoryData: [TimeCategoryData] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("时间分类")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if categoryData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("暂无分类数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 100)
            } else {
                VStack(spacing: 12) {
                    ForEach(categoryData, id: \.name) { category in
                        TimeCategoryRow(category: category)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            loadCategoryData()
        }
        .onChange(of: timeRange) { _ in
            loadCategoryData()
        }
    }
    
    private func loadCategoryData() {
        // 模拟数据
        categoryData = [
            TimeCategoryData(name: "工作", time: 6 * 3600, color: .blue, sessionCount: 8),
            TimeCategoryData(name: "学习", time: 2 * 3600, color: .green, sessionCount: 3),
            TimeCategoryData(name: "娱乐", time: 1.5 * 3600, color: .orange, sessionCount: 5),
            TimeCategoryData(name: "社交", time: 1 * 3600, color: .pink, sessionCount: 4)
        ]
    }
}

struct TimeCategoryData {
    let name: String
    let time: TimeInterval
    let color: Color
    let sessionCount: Int
}

struct TimeCategoryRow: View {
    let category: TimeCategoryData
    
    var body: some View {
        HStack {
            Circle()
                .fill(category.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(category.sessionCount) 次记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatTime(category.time))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
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

// MARK: - Time Distribution Chart
struct TimeDistributionChart: View {
    let timeRange: TimeRecordView.TimeRange
    @State private var hourlyData: [HourlyTimeData] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("时间分布")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if hourlyData.isEmpty {
                Text("暂无分布数据")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(height: 100)
            } else {
                // 改进的时间分布图
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(hourlyData, id: \.hour) { data in
                            VStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(intensityColor(data.intensity))
                                    .frame(width: 12, height: max(CGFloat(data.intensity * 50), 2))
                                
                                Text("\(data.hour)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(height: 70)
                
                HStack {
                    Text("0时")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("12时")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("23时")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            loadHourlyData()
        }
        .onChange(of: timeRange) { _ in
            loadHourlyData()
        }
    }
    
    private func loadHourlyData() {
        // 模拟24小时数据，工作时间强度更高
        hourlyData = (0..<24).map { hour in
            let intensity: Double
            switch hour {
            case 9...11, 14...17: // 工作时间高峰
                intensity = Double.random(in: 0.6...1.0)
            case 8, 12, 13, 18...20: // 中等活跃时间
                intensity = Double.random(in: 0.3...0.7)
            default: // 其他时间较低
                intensity = Double.random(in: 0.0...0.4)
            }
            return HourlyTimeData(hour: hour, intensity: intensity)
        }
    }
    
    private func intensityColor(_ intensity: Double) -> Color {
        switch intensity {
        case 0.7...1.0:
            return .red.opacity(0.8)
        case 0.4..<0.7:
            return .orange.opacity(0.8)
        case 0.1..<0.4:
            return .blue.opacity(0.6)
        default:
            return .gray.opacity(0.3)
        }
    }
}

struct HourlyTimeData {
    let hour: Int
    let intensity: Double // 0.0 to 1.0
}

// MARK: - Time Record Manager
class TimeRecordManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    // 应用到分类的映射规则
    private let appCategoryMapping: [String: String] = [
        // 工作类应用
        "Xcode": "工作",
        "Terminal": "工作",
        "Slack": "工作",
        "Microsoft Word": "工作",
        "Excel": "工作",
        "PowerPoint": "工作",
        "Keynote": "工作",
        "Numbers": "工作",
        "Pages": "工作",
        "Visual Studio Code": "工作",
        "IntelliJ IDEA": "工作",
        
        // 学习类应用
        "Books": "学习",
        "Kindle": "学习",
        "Coursera": "学习",
        "Duolingo": "学习",
        "Khan Academy": "学习",
        "Udemy": "学习",
        "Notion": "学习",
        "Obsidian": "学习",
        
        // 娱乐类应用
        "YouTube": "娱乐",
        "Netflix": "娱乐",
        "Spotify": "娱乐",
        "Apple Music": "娱乐",
        "Steam": "娱乐",
        "Epic Games": "娱乐",
        "Twitch": "娱乐",
        
        // 社交类应用
        "WeChat": "社交",
        "WhatsApp": "社交",
        "Twitter": "社交",
        "Instagram": "社交",
        "Facebook": "社交",
        "Discord": "社交",
        "Telegram": "社交",
        
        // 浏览器类应用
        "Safari": "浏览",
        "Chrome": "浏览",
        "Firefox": "浏览",
        "Edge": "浏览"
    ]
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func startMonitoring() {
        // 开始时间记录监控
        print("TimeRecordManager: Started time recording")
    }
    
    func stopMonitoring() {
        // 停止时间记录监控
        print("TimeRecordManager: Stopped time recording")
    }
    
    /// 根据应用名称获取分类
    func getCategoryForApp(_ appName: String) -> String {
        return appCategoryMapping[appName] ?? "其他"
    }
    
    /// 获取所有应用分类映射
    func getAllAppMappings() -> [String: String] {
        return appCategoryMapping
    }
    
    /// 更新应用分类映射（用户自定义）
    func updateAppCategory(_ appName: String, category: String) {
        // 这里可以保存用户的自定义映射到 Core Data
        // 实现用户自定义分类逻辑
        print("Updated \(appName) to category: \(category)")
    }
}

struct TimeRecordView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let focusManager = FocusManager(
            usageMonitor: UsageMonitor(),
            viewContext: context
        )
        
        TimeRecordView()
            .environment(\.managedObjectContext, context)
            .environmentObject(focusManager)
    }
}