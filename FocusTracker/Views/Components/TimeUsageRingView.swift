import SwiftUI

/// A ring view that displays time usage distribution across different scene tags
struct TimeUsageRingView: View {
    let totalTime: TimeInterval
    let sceneBreakdown: [TagDistribution]
    let goal: TimeInterval
    
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 12)
                .frame(width: 160, height: 160)
            
            // Scene tag rings
            ForEach(sceneBreakdown.indices, id: \.self) { index in
                Circle()
                    .trim(from: startAngle(for: index), to: endAngle(for: index))
                    .stroke(
                        Color(hex: sceneBreakdown[index].color) ?? .blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(animationProgress)
                    .animation(.easeInOut(duration: 1.0).delay(Double(index) * 0.1), value: animationProgress)
            }
            
            // Center content
            VStack(spacing: 4) {
                Text(formatTime(totalTime))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("今日使用时间")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if goal > 0 {
                    Text("\(Int((totalTime / goal) * 100))%")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            withAnimation {
                animationProgress = 1.0
            }
        }
    }
    
    private func startAngle(for index: Int) -> CGFloat {
        let previousTime = sceneBreakdown.prefix(index).reduce(0) { $0 + $1.usageTime }
        return totalTime > 0 ? CGFloat(previousTime / totalTime) : 0
    }
    
    private func endAngle(for index: Int) -> CGFloat {
        let currentTime = sceneBreakdown.prefix(index + 1).reduce(0) { $0 + $1.usageTime }
        return totalTime > 0 ? CGFloat(currentTime / totalTime) : 0
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



struct TimeUsageRingView_Previews: PreviewProvider {
    static var previews: some View {
        TimeUsageRingView(
            totalTime: 4 * 3600 + 30 * 60, // 4.5 hours
            sceneBreakdown: [
                TagDistribution(tagName: "工作", color: "#007AFF", usageTime: 2 * 3600, percentage: 44.4, sessionCount: 3),
                TagDistribution(tagName: "学习", color: "#34C759", usageTime: 1.5 * 3600, percentage: 33.3, sessionCount: 2),
                TagDistribution(tagName: "娱乐", color: "#FF9500", usageTime: 1 * 3600, percentage: 22.2, sessionCount: 4)
            ],
            goal: 8 * 3600 // 8 hours
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}