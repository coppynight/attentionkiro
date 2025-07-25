import SwiftUI

/// Data structure for app usage breakdown information
struct AppUsageBreakdownData {
    let appName: String
    let appIdentifier: String
    let usageTime: TimeInterval
    let percentage: Double
    let sessionCount: Int
    let iconName: String?
}

/// A view that displays the breakdown of app usage time
struct AppBreakdownView: View {
    let appUsageData: [AppUsageBreakdownData]
    let totalTime: TimeInterval
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("应用使用分布")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("今日")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if appUsageData.isEmpty {
                Text("暂无应用使用数据")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(appUsageData.prefix(5).enumerated()), id: \.offset) { index, app in
                        AppUsageRowView(
                            app: app,
                            rank: index + 1,
                            totalTime: totalTime
                        )
                    }
                }
                
                if appUsageData.count > 5 {
                    Button(action: {
                        // Action to show all apps would go here
                    }) {
                        HStack {
                            Text("查看全部 \(appUsageData.count) 个应用")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - App Usage Row View
struct AppUsageRowView: View {
    let app: AppUsageBreakdownData
    let rank: Int
    let totalTime: TimeInterval
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank indicator
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .center)
            
            // App icon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: app.iconName ?? "app.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                )
            
            // App info
            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(app.sessionCount) 次使用")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Usage time and percentage
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(app.usageTime))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(Int(app.percentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
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

struct AppBreakdownView_Previews: PreviewProvider {
    static var previews: some View {
        AppBreakdownView(
            appUsageData: [
                AppUsageBreakdownData(appName: "微信", appIdentifier: "com.tencent.xin", usageTime: 2 * 3600, percentage: 40.0, sessionCount: 15, iconName: "message.fill"),
                AppUsageBreakdownData(appName: "Safari", appIdentifier: "com.apple.mobilesafari", usageTime: 1.5 * 3600, percentage: 30.0, sessionCount: 8, iconName: "safari.fill"),
                AppUsageBreakdownData(appName: "微博", appIdentifier: "com.sina.weibo", usageTime: 1 * 3600, percentage: 20.0, sessionCount: 12, iconName: "globe"),
                AppUsageBreakdownData(appName: "网易云音乐", appIdentifier: "com.netease.cloudmusic", usageTime: 30 * 60, percentage: 10.0, sessionCount: 3, iconName: "music.note"),
            ],
            totalTime: 5 * 3600 // 5 hours
        )
        .padding()
    }
}