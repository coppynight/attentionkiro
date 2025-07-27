import SwiftUI
import Combine

/// LiveSessionMonitor - 实时会话监控组件
/// 显示当前会话的详细状态，包括专注强度、时间进度等
struct LiveSessionMonitor: View {
    
    // MARK: - Properties
    
    @ObservedObject var commitManager: LifeCommitManager
    
    // MARK: - State
    
    @State private var currentTime = Date()
    @State private var timer: Timer?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            if commitManager.isTracking {
                // 会话进度环
                sessionProgressRing
                
                // 详细信息
                sessionDetails
                
                // 专注强度历史图表
                focusIntensityChart
                
                // 中断信息
                if commitManager.interruptionCount > 0 {
                    interruptionInfo
                }
            } else {
                // 未开始状态
                idleState
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - View Components
    
    /// 会话进度环
    private var sessionProgressRing: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)
                .frame(width: 120, height: 120)
            
            // 进度圆环
            Circle()
                .trim(from: 0, to: progressPercentage)
                .stroke(
                    LinearGradient(
                        colors: [focusIntensityColor, focusIntensityColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progressPercentage)
            
            // 中心内容
            VStack(spacing: 4) {
                Text(commitManager.getFormattedSessionDuration())
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                
                Text("\(Int(commitManager.currentFocusIntensity * 100))%")
                    .font(.caption)
                    .foregroundColor(focusIntensityColor)
                    .fontWeight(.semibold)
            }
        }
    }
    
    /// 会话详细信息
    private var sessionDetails: some View {
        VStack(spacing: 12) {
            // 当前活动
            if let session = commitManager.currentSession, let activity = session.activity {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.blue)
                    Text(activity)
                        .font(.headline)
                    Spacer()
                }
            }
            
            // 状态指标
            HStack(spacing: 20) {
                StatusIndicator(
                    title: "专注强度",
                    value: String(format: "%.0f%%", commitManager.currentFocusIntensity * 100),
                    color: focusIntensityColor,
                    icon: "gauge.medium"
                )
                
                StatusIndicator(
                    title: "质量等级",
                    value: focusQuality.rawValue,
                    color: Color(hex: focusQuality.color),
                    icon: "star.fill"
                )
                
                StatusIndicator(
                    title: "中断次数",
                    value: "\(commitManager.interruptionCount)",
                    color: commitManager.interruptionCount > 0 ? .orange : .green,
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 专注强度历史图表
    private var focusIntensityChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("专注强度趋势")
                .font(.headline)
            
            if let session = commitManager.currentSession {
                FocusIntensityMiniChart(intensityHistory: session.focusIntensityHistory)
                    .frame(height: 60)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 中断信息
    private var interruptionInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("会话中断")
                    .font(.headline)
                Spacer()
                Text("\(commitManager.interruptionCount) 次")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)
            }
            
            if let session = commitManager.currentSession, !session.interruptions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(session.interruptions.suffix(3).enumerated()), id: \.offset) { index, interruption in
                        HStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                            
                            Text(interruption.reason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(interruption.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if session.interruptions.count > 3 {
                        Text("还有 \(session.interruptions.count - 3) 次中断...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    /// 未开始状态
    private var idleState: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("准备开始新的人生提交")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击开始按钮来记录你的时间")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Computed Properties
    
    /// 进度百分比（基于理想的25分钟番茄工作法）
    private var progressPercentage: Double {
        let duration = commitManager.getCurrentSessionDuration()
        let idealDuration: TimeInterval = 25 * 60 // 25分钟
        return min(1.0, duration / idealDuration)
    }
    
    /// 专注强度对应的颜色
    private var focusIntensityColor: Color {
        let intensity = commitManager.currentFocusIntensity
        switch intensity {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        case 0.2..<0.4: return .red
        default: return .gray
        }
    }
    
    /// 专注质量等级
    private var focusQuality: FocusQuality {
        return FocusIntensityCalculator.getFocusQuality(intensity: commitManager.currentFocusIntensity)
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Supporting Views

/// 状态指标组件
struct StatusIndicator: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 专注强度迷你图表
struct FocusIntensityMiniChart: View {
    let intensityHistory: [FocusIntensityPoint]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard intensityHistory.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepWidth = width / CGFloat(max(1, intensityHistory.count - 1))
                
                // 移动到第一个点
                let firstPoint = CGPoint(
                    x: 0,
                    y: height - (height * intensityHistory[0].intensity)
                )
                path.move(to: firstPoint)
                
                // 连接其他点
                for (index, point) in intensityHistory.enumerated() {
                    if index > 0 {
                        let x = CGFloat(index) * stepWidth
                        let y = height - (height * point.intensity)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.blue, .green],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
            
            // 添加数据点
            ForEach(Array(intensityHistory.enumerated()), id: \.offset) { index, point in
                let width = geometry.size.width
                let height = geometry.size.height
                let stepWidth = width / CGFloat(max(1, intensityHistory.count - 1))
                let x = CGFloat(index) * stepWidth
                let y = height - (height * point.intensity)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 4, height: 4)
                    .position(x: x, y: y)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Preview

struct LiveSessionMonitor_Previews: PreviewProvider {
    static var previews: some View {
        LiveSessionMonitor(
            commitManager: LifeCommitManager(viewContext: PersistenceController.preview.container.viewContext)
        )
        .padding()
    }
}