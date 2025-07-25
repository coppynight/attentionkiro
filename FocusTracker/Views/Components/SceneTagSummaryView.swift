import SwiftUI

/// A view that displays a summary of scene tag usage
struct SceneTagSummaryView: View {
    let tagDistribution: [TagDistribution]
    let totalTime: TimeInterval
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("场景标签汇总")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("今日")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if tagDistribution.isEmpty {
                Text("暂无标签数据")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Tag distribution bars
                VStack(spacing: 8) {
                    ForEach(tagDistribution.prefix(6), id: \.tagName) { tag in
                        TagDistributionRowView(
                            tag: tag,
                            totalTime: totalTime
                        )
                    }
                }
                
                // Summary stats
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最常用标签")
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
                        Text("标签覆盖率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        let taggedTime = tagDistribution.reduce(0) { $0 + $1.usageTime }
                        let coverage = totalTime > 0 ? (taggedTime / totalTime) * 100 : 0
                        
                        Text("\(Int(coverage))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(coverage > 80 ? .green : coverage > 50 ? .orange : .red)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Tag Distribution Row View
struct TagDistributionRowView: View {
    let tag: TagDistribution
    let totalTime: TimeInterval
    
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                // Tag indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: tag.color) ?? .blue)
                        .frame(width: 10, height: 10)
                    
                    Text(tag.tagName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Time and percentage
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(tag.usageTime))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(tag.percentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: tag.color) ?? .blue)
                        .frame(
                            width: geometry.size.width * animationProgress * CGFloat(tag.percentage / 100),
                            height: 4
                        )
                        .animation(.easeInOut(duration: 1.0), value: animationProgress)
                }
            }
            .frame(height: 4)
        }
        .onAppear {
            withAnimation {
                animationProgress = 1.0
            }
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

struct SceneTagSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SceneTagSummaryView(
            tagDistribution: [
                TagDistribution(tagName: "工作", color: "#007AFF", usageTime: 2 * 3600, percentage: 40.0, sessionCount: 5),
                TagDistribution(tagName: "学习", color: "#34C759", usageTime: 1.5 * 3600, percentage: 30.0, sessionCount: 3),
                TagDistribution(tagName: "娱乐", color: "#FF9500", usageTime: 1 * 3600, percentage: 20.0, sessionCount: 8),
                TagDistribution(tagName: "社交", color: "#FF2D92", usageTime: 30 * 60, percentage: 10.0, sessionCount: 12),
            ],
            totalTime: 5 * 3600 // 5 hours
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}