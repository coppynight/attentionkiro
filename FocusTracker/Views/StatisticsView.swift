import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var focusManager: FocusManager
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var personalBestRecord: (duration: TimeInterval, date: Date)?
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "7天"
        case month = "30天"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Weekly trend chart
                    WeeklyTrendChartView()
                    
                    // Personal best record
                    PersonalBestView(personalBest: personalBestRecord)
                    
                    // Focus sessions history
                    FocusSessionsHistoryView()
                }
                .padding()
            }
            .navigationTitle("专注统计")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("时间范围", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
        .onAppear {
            loadPersonalBestRecord()
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

// MARK: - Weekly Trend Chart View
struct WeeklyTrendChartView: View {
    @EnvironmentObject private var focusManager: FocusManager
    @State private var weeklyData: [DailyFocusData] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("专注趋势")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // 使用简单的条形图实现，兼容所有iOS版本
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyData, id: \.date) { day in
                    VStack {
                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: calculateBarHeight(day.totalFocusTime))
                        
                        // Day label
                        Text(formatDayOfWeek(day.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 200)
            .padding(.top, 20)
            
            // Legend
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                
                Text("专注时间")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("总计: \(formatTotalTime(totalFocusTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            weeklyData = focusManager.getWeeklyTrend()
        }
    }
    
    private var totalFocusTime: TimeInterval {
        weeklyData.reduce(0) { $0 + $1.totalFocusTime }
    }
    
    private func calculateBarHeight(_ duration: TimeInterval) -> CGFloat {
        let maxHeight: CGFloat = 160
        let maxHours: Double = 8 // Assuming 8 hours is the max
        
        let hours = duration / 3600
        let ratio = min(hours / maxHours, 1.0)
        
        return max(maxHeight * CGFloat(ratio), 10) // Minimum height of 10
    }
    
    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func formatTotalTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)小时 \(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

// MARK: - Personal Best View
struct PersonalBestView: View {
    var personalBest: (duration: TimeInterval, date: Date)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("个人最佳记录")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let bestRecord = personalBest {
                HStack(spacing: 20) {
                    // Trophy icon
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "trophy.fill")
                            .font(.title)
                            .foregroundColor(.yellow)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatTime(bestRecord.duration))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("创建于 \(formatDate(bestRecord.date))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            } else {
                HStack {
                    Image(systemName: "hourglass")
                        .foregroundColor(.secondary)
                    
                    Text("暂无专注记录")
                        .foregroundColor(.secondary)
                        .italic()
                    
                    Spacer()
                }
                .padding(.vertical, 10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)小时 \(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Focus Sessions History View
struct FocusSessionsHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FocusSession.startTime, ascending: false)],
        predicate: NSPredicate(format: "isValid == YES"),
        animation: .default)
    private var focusSessions: FetchedResults<FocusSession>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("专注时段历史")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(focusSessions.count)个记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if focusSessions.isEmpty {
                Text("暂无专注记录")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(focusSessions.prefix(15)), id: \.objectID) { session in
                        DetailedSessionRowView(session: session)
                    }
                }
                
                if focusSessions.count > 15 {
                    Button(action: {
                        // Action to view all sessions would go here
                    }) {
                        Text("查看全部记录")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Detailed Session Row View
struct DetailedSessionRowView: View {
    let session: FocusSession
    
    var body: some View {
        HStack {
            // Date column
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(session.startTime))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(formatTime(session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 100, alignment: .leading)
            
            Divider()
                .padding(.horizontal, 8)
            
            // Duration column
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDuration(session.duration))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let endTime = session.endTime {
                    Text("结束于 \(formatTime(endTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status indicator
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)小时 \(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(FocusManager(
                usageMonitor: UsageMonitor(),
                viewContext: PersistenceController.preview.container.viewContext
            ))
    }
}