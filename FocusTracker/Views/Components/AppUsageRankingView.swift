import SwiftUI

/// A view that displays app usage ranking with detailed statistics
struct AppUsageRankingView: View {
    let appUsageData: [AppUsageStatistics]
    let totalTime: TimeInterval
    let showExtendedStats: Bool
    
    init(appUsageData: [AppUsageStatistics], totalTime: TimeInterval, showExtendedStats: Bool = true) {
        self.appUsageData = appUsageData
        self.totalTime = totalTime
        self.showExtendedStats = showExtendedStats
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("应用使用排行")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("共 \(appUsageData.count) 个应用")
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
                    ForEach(Array(appUsageData.enumerated()), id: \.offset) { index, app in
                        AppRankingRowView(
                            app: app,
                            rank: index + 1,
                            totalTime: totalTime,
                            showExtendedStats: showExtendedStats
                        )
                    }
                }
                
                if showExtendedStats && appUsageData.count > 10 {
                    Button(action: {
                        // Action to show all apps would go here
                    }) {
                        HStack {
                            Text("查看全部应用")
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
                
                // Summary statistics
                if showExtendedStats {
                    Divider()
                        .padding(.vertical, 8)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("最常用应用")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let topApp = appUsageData.first {
                                Text(topApp.appName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("平均使用时长")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            let avgTime = appUsageData.isEmpty ? 0 : totalTime / Double(appUsageData.count)
                            Text(formatTime(avgTime))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }
                }
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
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - App Ranking Row View
struct AppRankingRowView: View {
    let app: AppUsageStatistics
    let rank: Int
    let totalTime: TimeInterval
    let showExtendedStats: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank indicator with medal for top 3
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 24, height: 24)
                    
                    Text("\(rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Text("\(rank)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                }
            }
            
            // App icon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(app.isProductiveApp ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: getIconName(for: app.appIdentifier))
                        .font(.system(size: 16))
                        .foregroundColor(app.isProductiveApp ? .green : .blue)
                )
            
            // App info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(app.appName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if app.isProductiveApp {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                if showExtendedStats {
                    HStack(spacing: 8) {
                        Text("\(app.sessionCount) 次使用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("平均 \(formatTime(app.averageSessionTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("\(app.sessionCount) 次使用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Usage time and percentage
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(app.totalTime))
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
    
    private var rankColor: Color {
        switch rank {
        case 1:
            return .yellow
        case 2:
            return .gray
        case 3:
            return Color.orange
        default:
            return .blue
        }
    }
    
    private func getIconName(for appIdentifier: String) -> String {
        switch appIdentifier {
        case let id where id.contains("wechat") || id.contains("tencent.xin"):
            return "message.fill"
        case let id where id.contains("safari"):
            return "safari.fill"
        case let id where id.contains("mail"):
            return "envelope.fill"
        case let id where id.contains("music"):
            return "music.note"
        case let id where id.contains("video") || id.contains("netflix"):
            return "play.rectangle.fill"
        case let id where id.contains("game"):
            return "gamecontroller.fill"
        case let id where id.contains("map"):
            return "map.fill"
        case let id where id.contains("camera"):
            return "camera.fill"
        case let id where id.contains("photo"):
            return "photo.fill"
        case let id where id.contains("office") || id.contains("microsoft"):
            return "doc.text.fill"
        case let id where id.contains("notes"):
            return "note.text"
        default:
            return "app.fill"
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

struct AppUsageRankingView_Previews: PreviewProvider {
    static var previews: some View {
        AppUsageRankingView(
            appUsageData: [
                AppUsageStatistics(appIdentifier: "com.tencent.xin", appName: "微信", categoryIdentifier: "social", totalTime: 2*3600, sessionCount: 15, averageSessionTime: 8*60, isProductiveApp: false, percentage: 40.0),
                AppUsageStatistics(appIdentifier: "com.apple.mobilesafari", appName: "Safari", categoryIdentifier: "productivity", totalTime: 1.5*3600, sessionCount: 8, averageSessionTime: 11.25*60, isProductiveApp: true, percentage: 30.0),
                AppUsageStatistics(appIdentifier: "com.sina.weibo", appName: "微博", categoryIdentifier: "social", totalTime: 1*3600, sessionCount: 12, averageSessionTime: 5*60, isProductiveApp: false, percentage: 20.0),
                AppUsageStatistics(appIdentifier: "com.netease.cloudmusic", appName: "网易云音乐", categoryIdentifier: "entertainment", totalTime: 30*60, sessionCount: 3, averageSessionTime: 10*60, isProductiveApp: false, percentage: 10.0),
            ],
            totalTime: 5*3600
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}