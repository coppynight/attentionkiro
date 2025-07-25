import SwiftUI

/// A view that provides detailed analysis of scene tag usage patterns
struct SceneTagAnalysisView: View {
    let tagDistribution: [SceneTagData]
    let totalTime: TimeInterval
    let showTrends: Bool
    
    init(tagDistribution: [SceneTagData], totalTime: TimeInterval, showTrends: Bool = true) {
        self.tagDistribution = tagDistribution
        self.totalTime = totalTime
        self.showTrends = showTrends
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("场景分析")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("今日")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if tagDistribution.isEmpty {
                Text("暂无场景标签数据")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Tag distribution chart
                VStack(spacing: 12) {
                    ForEach(tagDistribution.prefix(6), id: \.tagName) { tag in
                        TagAnalysisRowView(
                            tag: tag,
                            totalTime: totalTime,
                            showTrends: showTrends
                        )
                    }
                }
                
                // Analysis insights
                if showTrends {
                    Divider()
                        .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("场景洞察")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        ForEach(generateInsights(), id: \.self) { insight in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.top, 2)
                                
                                Text(insight)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Summary statistics
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("主要场景")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let topTag = tagDistribution.first {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: topTag.color) ?? .blue)
                                    .frame(width: 8, height: 8)
                                
                                Text(topTag.tagName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("场景多样性")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(tagDistribution.count) 个场景")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(diversityColor)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var diversityColor: Color {
        switch tagDistribution.count {
        case 0...2:
            return .red
        case 3...4:
            return .orange
        case 5...6:
            return .green
        default:
            return .blue
        }
    }
    
    private func generateInsights() -> [String] {
        var insights: [String] = []
        
        // Check for dominant tag
        if let topTag = tagDistribution.first, topTag.percentage > 50 {
            insights.append("今天主要专注于\(topTag.tagName)，占用了\(Int(topTag.percentage))%的时间")
        }
        
        // Check for balanced usage
        let balancedTags = tagDistribution.filter { $0.percentage > 15 && $0.percentage < 35 }
        if balancedTags.count >= 3 {
            insights.append("时间分配较为均衡，在多个场景间切换")
        }
        
        // Check for productivity
        let workTags = tagDistribution.filter { $0.tagName == "工作" || $0.tagName == "学习" }
        let workTime = workTags.reduce(0) { $0 + $1.totalTime }
        let workPercentage = totalTime > 0 ? (workTime / totalTime) * 100 : 0
        
        if workPercentage > 60 {
            insights.append("今天的工作/学习时间占比很高，效率不错")
        } else if workPercentage < 20 {
            insights.append("今天的工作/学习时间较少，可以考虑增加专注时间")
        }
        
        // Check for entertainment balance
        let entertainmentTag = tagDistribution.first { $0.tagName == "娱乐" }
        if let entertainment = entertainmentTag, entertainment.percentage > 40 {
            insights.append("娱乐时间较多，注意劳逸结合")
        }
        
        // Check session patterns
        let avgSessionTime = tagDistribution.isEmpty ? 0 : tagDistribution.reduce(0) { $0 + $1.averageSessionTime } / Double(tagDistribution.count)
        if avgSessionTime > 30 * 60 { // 30 minutes
            insights.append("各场景的平均使用时长较长，专注度较好")
        }
        
        return insights.isEmpty ? ["继续保持良好的时间管理习惯"] : insights
    }
}

// MARK: - Tag Analysis Row View
struct TagAnalysisRowView: View {
    let tag: SceneTagData
    let totalTime: TimeInterval
    let showTrends: Bool
    
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Tag indicator with icon
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: tag.color) ?? .blue)
                        .frame(width: 12, height: 12)
                    
                    Image(systemName: getTagIcon(tag.tagName))
                        .font(.caption)
                        .foregroundColor(Color(hex: tag.color) ?? .blue)
                    
                    Text(tag.tagName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Time and percentage
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(tag.totalTime))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(tag.percentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar with animation
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    (Color(hex: tag.color) ?? .blue).opacity(0.6),
                                    Color(hex: tag.color) ?? .blue
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * animationProgress * CGFloat(tag.percentage / 100),
                            height: 6
                        )
                        .animation(.easeInOut(duration: 1.0), value: animationProgress)
                }
            }
            .frame(height: 6)
            
            // Additional statistics if trends are shown
            if showTrends {
                HStack {
                    Text("\(tag.sessionCount) 次使用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("平均 \(formatTime(tag.averageSessionTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.1)) {
                animationProgress = 1.0
            }
        }
    }
    
    private func getTagIcon(_ tagName: String) -> String {
        switch tagName {
        case "工作":
            return "briefcase.fill"
        case "学习":
            return "book.fill"
        case "娱乐":
            return "gamecontroller.fill"
        case "社交":
            return "person.2.fill"
        case "健康":
            return "heart.fill"
        case "购物":
            return "cart.fill"
        case "出行":
            return "car.fill"
        default:
            return "tag.fill"
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



struct SceneTagAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        SceneTagAnalysisView(
            tagDistribution: [
                SceneTagData(tagName: "工作", color: "#007AFF", totalTime: 2*3600, sessionCount: 5, percentage: 40.0, averageSessionTime: 24*60),
                SceneTagData(tagName: "学习", color: "#34C759", totalTime: 1.5*3600, sessionCount: 3, percentage: 30.0, averageSessionTime: 30*60),
                SceneTagData(tagName: "娱乐", color: "#FF9500", totalTime: 1*3600, sessionCount: 8, percentage: 20.0, averageSessionTime: 7.5*60),
                SceneTagData(tagName: "社交", color: "#FF2D92", totalTime: 30*60, sessionCount: 12, percentage: 10.0, averageSessionTime: 2.5*60),
            ],
            totalTime: 5*3600
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}