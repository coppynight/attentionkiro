import SwiftUI

/// A chart view that displays weekly usage trends
struct WeeklyTrendChart: View {
    let weeklyData: [DailyUsageData]
    let showFocusData: Bool
    
    init(weeklyData: [DailyUsageData], showFocusData: Bool = true) {
        self.weeklyData = weeklyData
        self.showFocusData = showFocusData
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("7天使用趋势")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if showFocusData {
                    HStack(spacing: 12) {
                        // Usage time legend
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text("使用时间")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Focus time legend (if available)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("专注时间")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Chart area
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyData, id: \.date) { dayData in
                    VStack(spacing: 4) {
                        // Bar chart
                        ZStack(alignment: .bottom) {
                            // Usage time bar (background)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.3), .blue],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: calculateBarHeight(dayData.totalUsageTime))
                            
                            // Focus time bar (foreground) if available
                            if showFocusData {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green.opacity(0.6), .green],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(height: calculateBarHeight(dayData.productiveTime))
                            }
                        }
                        
                        // Day label
                        Text(formatDayOfWeek(dayData.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Time label
                        Text(formatTime(dayData.totalUsageTime))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
            
            // Summary statistics
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("周总计")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(totalWeeklyTime))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("日均使用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(averageDailyTime))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var totalWeeklyTime: TimeInterval {
        weeklyData.reduce(0) { $0 + $1.totalUsageTime }
    }
    
    private var averageDailyTime: TimeInterval {
        weeklyData.isEmpty ? 0 : totalWeeklyTime / Double(weeklyData.count)
    }
    
    private func calculateBarHeight(_ duration: TimeInterval) -> CGFloat {
        let maxHeight: CGFloat = 100
        let maxTime = weeklyData.map { $0.totalUsageTime }.max() ?? 1
        
        let ratio = maxTime > 0 ? duration / maxTime : 0
        return max(maxHeight * CGFloat(ratio), 4) // Minimum height of 4
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
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct WeeklyTrendChart_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyTrendChart(
            weeklyData: [
                DailyUsageData(date: Date().addingTimeInterval(-6*24*3600), totalUsageTime: 4*3600, appCount: 12, sessionCount: 25, productiveTime: 2*3600, topApps: []),
                DailyUsageData(date: Date().addingTimeInterval(-5*24*3600), totalUsageTime: 5*3600, appCount: 15, sessionCount: 30, productiveTime: 2.5*3600, topApps: []),
                DailyUsageData(date: Date().addingTimeInterval(-4*24*3600), totalUsageTime: 3*3600, appCount: 10, sessionCount: 20, productiveTime: 1.5*3600, topApps: []),
                DailyUsageData(date: Date().addingTimeInterval(-3*24*3600), totalUsageTime: 6*3600, appCount: 18, sessionCount: 35, productiveTime: 3*3600, topApps: []),
                DailyUsageData(date: Date().addingTimeInterval(-2*24*3600), totalUsageTime: 4.5*3600, appCount: 14, sessionCount: 28, productiveTime: 2.2*3600, topApps: []),
                DailyUsageData(date: Date().addingTimeInterval(-1*24*3600), totalUsageTime: 7*3600, appCount: 20, sessionCount: 40, productiveTime: 3.5*3600, topApps: []),
                DailyUsageData(date: Date(), totalUsageTime: 5.5*3600, appCount: 16, sessionCount: 32, productiveTime: 2.8*3600, topApps: [])
            ]
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}