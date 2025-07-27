import SwiftUI
import CoreData

/// HeatmapView - 人生贡献图主界面
/// GitHub风格的热力图展示，显示用户的时间投入模式
struct HeatmapView: View {
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State Objects
    
    @StateObject private var heatmapEngine: HeatmapEngine
    @StateObject private var beautifulMomentManager: BeautifulMomentManager
    
    // MARK: - State Variables
    
    @State private var selectedDate = Date()
    @State private var selectedTimeRange: HeatmapTimeRange = .thisWeek
    @State private var selectedGridBlock: HeatmapGridBlock?
    @State private var showingDatePicker = false
    @State private var showingDetailSheet = false
    @State private var heatmapData: [Date: HeatmapData] = [:]
    @State private var isLoading = false
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self._heatmapEngine = StateObject(wrappedValue: HeatmapEngine(viewContext: viewContext))
        self._beautifulMomentManager = StateObject(wrappedValue: BeautifulMomentManager(viewContext: viewContext))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 时间范围选择器
                timeRangeSelector
                
                // 热力图主体
                ScrollView {
                    VStack(spacing: 20) {
                        // 日期导航
                        dateNavigationSection
                        
                        // 热力图网格
                        heatmapGridSection
                        
                        // 强度图例
                        intensityLegendSection
                        
                        // 统计信息
                        statisticsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("人生贡献图")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("今天") {
                        selectedDate = Date()
                        loadHeatmapData()
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetailSheet) {
            if let selectedBlock = selectedGridBlock {
                HeatmapDetailSheet(
                    gridBlock: selectedBlock,
                    onDismiss: { showingDetailSheet = false }
                )
            }
        }
        .onAppear {
            loadHeatmapData()
        }
        .onChange(of: selectedTimeRange) { _ in
            loadHeatmapData()
        }
    }
    
    // MARK: - View Components
    
    /// 时间范围选择器
    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HeatmapTimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedTimeRange = range
                    }) {
                        Text(range.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTimeRange == range ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTimeRange == range ? Color.green : Color(.systemGray5))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    /// 日期导航区域
    private var dateNavigationSection: some View {
        HStack {
            Button(action: {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                loadHeatmapData()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button(action: {
                showingDatePicker = true
            }) {
                VStack(spacing: 4) {
                    Text(selectedDate, style: .date)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(dayOfWeekString(for: selectedDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(
                    selectedDate: $selectedDate,
                    onDismiss: { 
                        showingDatePicker = false
                        loadHeatmapData()
                    }
                )
            }
            
            Spacer()
            
            Button(action: {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                loadHeatmapData()
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
    
    /// 热力图网格区域
    private var heatmapGridSection: some View {
        VStack(spacing: 12) {
            // 时间轴标签
            timeAxisLabels
            
            // 热力图网格
            if isLoading {
                ProgressView("生成热力图中...")
                    .frame(height: 200)
            } else {
                HeatmapGrid(
                    heatmapData: getCurrentDayHeatmapData(),
                    onBlockTapped: { block in
                        selectedGridBlock = block
                        showingDetailSheet = true
                    }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 时间轴标签
    private var timeAxisLabels: some View {
        HStack {
            ForEach(0..<24, id: \.self) { hour in
                if hour % 4 == 0 {
                    Text("\(hour):00")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    /// 强度图例区域
    private var intensityLegendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("专注强度图例")
                .font(.headline)
            
            HStack(spacing: 16) {
                Text("少")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(HeatmapEngine.IntensityLevel.allCases, id: \.self) { level in
                        Rectangle()
                            .fill(Color(hex: level.color))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                    }
                }
                
                Text("多")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 美好时刻图例
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color(hex: "#FFD700"))
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                    
                    Text("美好时刻")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 统计信息区域
    private var statisticsSection: some View {
        let stats = getCurrentDayStats()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("今日统计")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    title: "活跃率",
                    value: String(format: "%.1f%%", stats.activityRate * 100),
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "活跃块数",
                    value: "\(stats.activeBlocks)",
                    icon: "square.grid.3x3.fill",
                    color: .green
                )
                
                StatCard(
                    title: "美好时刻",
                    value: "\(stats.beautifulMomentBlocks)",
                    icon: "sparkles",
                    color: .yellow
                )
                
                StatCard(
                    title: "平均强度",
                    value: String(format: "%.1f%%", stats.averageIntensity * 100),
                    icon: "gauge.medium",
                    color: .orange
                )
            }
            
            if let peakTime = stats.formattedPeakTime {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("专注高峰: \(peakTime)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func loadHeatmapData() {
        isLoading = true
        
        Task {
            let dateRange = selectedTimeRange.dateRange(from: selectedDate)
            let data = await heatmapEngine.generateHeatmapData(from: dateRange.start, to: dateRange.end)
            
            await MainActor.run {
                self.heatmapData = data
                self.isLoading = false
            }
        }
    }
    
    private func getCurrentDayHeatmapData() -> HeatmapData? {
        let calendar = Calendar.current
        let dayKey = calendar.startOfDay(for: selectedDate)
        return heatmapData[dayKey]
    }
    
    private func getCurrentDayStats() -> HeatmapDayStats {
        return getCurrentDayHeatmapData()?.stats ?? HeatmapDayStats(
            totalBlocks: 96,
            activeBlocks: 0,
            beautifulMomentBlocks: 0,
            averageIntensity: 0.0,
            peakIntensity: 0.0,
            peakTime: nil,
            intensityDistribution: [:],
            activeHours: 0,
            totalActiveDuration: 0
        )
    }
    
    private func dayOfWeekString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

enum HeatmapTimeRange: String, CaseIterable {
    case today = "今天"
    case thisWeek = "本周"
    case thisMonth = "本月"
    case thisYear = "今年"
    
    var displayName: String {
        return self.rawValue
    }
    
    func dateRange(from date: Date) -> DateInterval {
        let calendar = Calendar.current
        
        switch self {
        case .today:
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return DateInterval(start: startOfDay, end: endOfDay)
            
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)!.start
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
            return DateInterval(start: startOfWeek, end: endOfWeek)
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: date)!.start
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            return DateInterval(start: startOfMonth, end: endOfMonth)
            
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: date)!.start
            let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear)!
            return DateInterval(start: startOfYear, end: endOfYear)
        }
    }
}

// MARK: - Preview

struct HeatmapView_Previews: PreviewProvider {
    static var previews: some View {
        HeatmapView(viewContext: PersistenceController.preview.container.viewContext)
    }
}