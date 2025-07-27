import SwiftUI
import CoreData

/// TimeRecordingView - 时间记录主界面
/// Git风格的时间提交界面，支持开始/结束会话、实时状态显示和美好时刻标记
struct TimeRecordingView: View {
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State Objects
    
    @StateObject private var commitManager: LifeCommitManager
    @StateObject private var timeBlockManager: TimeBlockManager
    @StateObject private var beautifulMomentManager: BeautifulMomentManager
    
    // MARK: - State Variables
    
    @State private var showingCommitSheet = false
    @State private var showingBeautifulMomentSheet = false
    @State private var commitMessage = ""
    @State private var currentActivity = ""
    @State private var isBeautifulMoment = false
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self._commitManager = StateObject(wrappedValue: LifeCommitManager(viewContext: viewContext))
        self._timeBlockManager = StateObject(wrappedValue: TimeBlockManager(viewContext: viewContext))
        self._beautifulMomentManager = StateObject(wrappedValue: BeautifulMomentManager(viewContext: viewContext))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 当前会话状态卡片
                    currentSessionCard
                    
                    // 主要操作按钮
                    mainActionButtons
                    
                    // 实时统计信息
                    todayStatsCard
                    
                    // 最近的提交记录
                    recentCommitsSection
                }
                .padding()
            }
            .navigationTitle("人生提交")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("设置") {
                        // TODO: 打开设置界面
                    }
                }
            }
        }
        .sheet(isPresented: $showingCommitSheet) {
            CommitMessageSheet(
                commitMessage: $commitMessage,
                isBeautifulMoment: $isBeautifulMoment,
                onCommit: handleCommitSession
            )
        }
        .sheet(isPresented: $showingBeautifulMomentSheet) {
            BeautifulMomentSheet(
                beautifulMomentManager: beautifulMomentManager,
                onDismiss: { showingBeautifulMomentSheet = false }
            )
        }
    }
    
    // MARK: - View Components
    
    /// 当前会话状态卡片
    private var currentSessionCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: commitManager.isTracking ? "play.circle.fill" : "pause.circle.fill")
                    .font(.title2)
                    .foregroundColor(commitManager.isTracking ? .green : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(commitManager.isTracking ? "正在记录中..." : "未开始记录")
                        .font(.headline)
                        .foregroundColor(commitManager.isTracking ? .primary : .secondary)
                    
                    if commitManager.isTracking {
                        Text("持续时间: \(commitManager.getFormattedSessionDuration())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if commitManager.isTracking {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("专注强度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(commitManager.currentFocusIntensity * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(focusIntensityColor)
                    }
                }
            }
            
            // 专注强度进度条
            if commitManager.isTracking {
                ProgressView(value: commitManager.currentFocusIntensity)
                    .progressViewStyle(LinearProgressViewStyle(tint: focusIntensityColor))
                    .scaleEffect(y: 2)
            }
            
            // 当前活动信息
            if commitManager.isTracking, let session = commitManager.currentSession {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.blue)
                    
                    Text(session.activity ?? "未设置活动")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if commitManager.interruptionCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("\(commitManager.interruptionCount) 次中断")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 主要操作按钮
    private var mainActionButtons: some View {
        VStack(spacing: 12) {
            if commitManager.isTracking {
                // 结束会话按钮
                Button(action: {
                    showingCommitSheet = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("完成提交")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
                
                HStack(spacing: 12) {
                    // 暂停按钮
                    Button(action: {
                        commitManager.pauseSession(reason: "用户手动暂停")
                    }) {
                        HStack {
                            Image(systemName: "pause.fill")
                            Text("暂停")
                        }
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // 取消按钮
                    Button(action: {
                        commitManager.cancelSession()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("取消")
                        }
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            } else {
                // 开始新会话按钮
                Button(action: {
                    startNewSession()
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("开始新的提交")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                // 快速开始按钮组
                quickStartButtons
            }
        }
    }
    
    /// 快速开始按钮组
    private var quickStartButtons: some View {
        VStack(spacing: 8) {
            Text("快速开始")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                QuickStartButton(title: "工作", icon: "briefcase.fill", color: .blue) {
                    startQuickSession(activity: "工作")
                }
                
                QuickStartButton(title: "学习", icon: "book.fill", color: .green) {
                    startQuickSession(activity: "学习")
                }
                
                QuickStartButton(title: "创作", icon: "paintbrush.fill", color: .purple) {
                    startQuickSession(activity: "创作")
                }
                
                QuickStartButton(title: "思考", icon: "brain.head.profile", color: .orange) {
                    startQuickSession(activity: "思考")
                }
            }
        }
    }
    
    /// 今日统计卡片
    private var todayStatsCard: some View {
        let stats = commitManager.getTodayCommitStats()
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("今日统计")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 20) {
                StatItem(title: "提交次数", value: "\(stats.totalCommits)", icon: "number.circle.fill", color: .blue)
                StatItem(title: "专注时间", value: stats.formattedTotalFocusTime, icon: "clock.fill", color: .green)
                StatItem(title: "平均强度", value: String(format: "%.0f%%", stats.averageFocusIntensity * 100), icon: "gauge.medium", color: .orange)
            }
            
            if stats.beautifulMomentsCount > 0 {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("\(stats.beautifulMomentsCount) 个美好时刻")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("查看") {
                        showingBeautifulMomentSheet = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 最近的提交记录
    private var recentCommitsSection: some View {
        let recentCommits = commitManager.getRecentCommits(limit: 5)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.purple)
                Text("最近提交")
                    .font(.headline)
                Spacer()
                
                Button("查看全部") {
                    // TODO: 导航到提交历史页面
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if recentCommits.isEmpty {
                Text("还没有提交记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(recentCommits, id: \.id) { commit in
                    CommitRowView(commit: commit)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
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
    
    // MARK: - Actions
    
    /// 开始新会话
    private func startNewSession() {
        commitManager.startCommitSession()
    }
    
    /// 快速开始会话
    private func startQuickSession(activity: String) {
        commitManager.startCommitSession(activity: activity)
        commitManager.updateSessionActivity(activity)
    }
    
    /// 处理提交会话
    private func handleCommitSession() {
        guard !commitMessage.isEmpty else { return }
        
        let commit = commitManager.endCommitSession(
            commitMessage: commitMessage,
            isBeautifulMoment: isBeautifulMoment
        )
        
        if commit != nil {
            // 重置状态
            commitMessage = ""
            isBeautifulMoment = false
            showingCommitSheet = false
            
            // 显示成功反馈
            // TODO: 添加成功提示
        }
    }
}

// MARK: - Supporting Views

/// 快速开始按钮
struct QuickStartButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// StatItem is now defined in InsightsView.swift to avoid duplication

/// 提交记录行视图
struct CommitRowView: View {
    let commit: TimeCommit
    
    var body: some View {
        HStack(spacing: 12) {
            // 提交哈希
            Text(String(commit.commitHash?.prefix(7) ?? "unknown"))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemGray5))
                .cornerRadius(4)
            
            // 提交信息
            VStack(alignment: .leading, spacing: 2) {
                Text(commit.commitMessage ?? "无提交信息")
                    .font(.subheadline)
                    .lineLimit(1)
                
                if let timeBlock = commit.timeBlock {
                    Text(timeBlock.timeRangeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 美好时刻标记
            if commit.isBeautifulMoment {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            
            // 质量评分
            QualityBadge(quality: commit.focusQuality)
        }
        .padding(.vertical, 4)
    }
}

/// 质量徽章
struct QualityBadge: View {
    let quality: FocusQuality
    
    var body: some View {
        Text(quality.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: quality.color))
            .cornerRadius(4)
    }
}

// MARK: - Extensions
// Color.init(hex:) extension is now defined in InsightsView.swift to avoid duplication

// MARK: - Preview

struct TimeRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        TimeRecordingView(viewContext: PersistenceController.preview.container.viewContext)
    }
}