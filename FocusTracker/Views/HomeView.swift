import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var focusManager: FocusManager
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FocusSession.startTime, ascending: false)],
        animation: .default)
    private var focusSessions: FetchedResults<FocusSession>

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Focus Status Card
                    FocusStatusCard()
                    
                    // Current Session Card (if in focus)
                    if focusManager.isInFocusMode || focusManager.currentSession != nil {
                        CurrentSessionCard()
                    }
                    
                    // Today's Focus Time Card
                    TodaysFocusCard()
                    
                    // Recent Sessions Card
                    RecentSessionsCard()
                    
                    // 开发测试按钮已移至测试目标
                }
                .padding()
            }
            .navigationTitle("专注追踪")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Focus Status Card
struct FocusStatusCard: View {
    @EnvironmentObject private var focusManager: FocusManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(statusBackgroundColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: statusIcon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("当前状态")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(statusDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusIcon: String {
        if focusManager.isInFocusMode {
            return "brain.head.profile"
        } else if focusManager.isMonitoring {
            return "eye.fill"
        } else {
            return "pause.circle.fill"
        }
    }
    
    private var statusText: String {
        if focusManager.isInFocusMode {
            return "专注中"
        } else if focusManager.isMonitoring {
            return "监测中"
        } else {
            return "已暂停"
        }
    }
    
    private var statusColor: Color {
        if focusManager.isInFocusMode {
            return .green
        } else if focusManager.isMonitoring {
            return .blue
        } else {
            return .red
        }
    }
    
    private var statusBackgroundColor: Color {
        if focusManager.isInFocusMode {
            return .green
        } else if focusManager.isMonitoring {
            return .blue
        } else {
            return .red
        }
    }
    
    private var statusDescription: String {
        if focusManager.isInFocusMode {
            return "您正在专注中，继续保持！"
        } else if focusManager.isMonitoring {
            return "正在监测您的专注状态"
        } else {
            return "专注监测已暂停"
        }
    }
}

// MARK: - Today's Focus Card
struct TodaysFocusCard: View {
    @EnvironmentObject private var focusManager: FocusManager
    @Environment(\.managedObjectContext) private var viewContext
    @State private var dailyGoal: TimeInterval = 2 * 60 * 60 // Default 2 hours
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("今日专注时间")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // Focus Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: min(focusManager.todaysFocusTime / dailyGoal, 1.0))
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: focusManager.todaysFocusTime)
                
                // Center content
                VStack(spacing: 4) {
                    Text(formatTime(focusManager.todaysFocusTime))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("/ \(formatTime(dailyGoal))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int((focusManager.todaysFocusTime / dailyGoal) * 100))%")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            // Goal status message
            HStack {
                Image(systemName: goalStatusIcon)
                    .foregroundColor(goalStatusColor)
                
                Text(goalStatusMessage)
                    .font(.subheadline)
                    .foregroundColor(goalStatusColor)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            loadDailyGoal()
        }
    }
    
    private func loadDailyGoal() {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try viewContext.fetch(request)
            if let userSettings = settings.first {
                dailyGoal = userSettings.dailyFocusGoal
            }
        } catch {
            print("Error loading daily goal: \(error)")
        }
    }
    
    private var goalStatusIcon: String {
        if focusManager.todaysFocusTime >= dailyGoal {
            return "checkmark.circle.fill"
        } else if focusManager.todaysFocusTime >= dailyGoal * 0.5 {
            return "clock.fill"
        } else {
            return "target"
        }
    }
    
    private var goalStatusColor: Color {
        if focusManager.todaysFocusTime >= dailyGoal {
            return .green
        } else if focusManager.todaysFocusTime >= dailyGoal * 0.5 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var goalStatusMessage: String {
        if focusManager.todaysFocusTime >= dailyGoal {
            return "今日目标已达成！"
        } else if focusManager.todaysFocusTime >= dailyGoal * 0.5 {
            return "已完成一半目标，继续加油！"
        } else {
            let remaining = dailyGoal - focusManager.todaysFocusTime
            return "还需 \(formatTime(remaining)) 达成目标"
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

// MARK: - Current Session Card
struct CurrentSessionCard: View {
    @EnvironmentObject private var focusManager: FocusManager
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.green)
                
                Text("当前专注时段")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(), value: currentTime)
                    
                    Text("LIVE")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            if let session = focusManager.currentSession {
                VStack(spacing: 8) {
                    Text(formatCurrentSessionTime(session.startTime))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("开始时间: \(formatTime(session.startTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Estimated current focus time based on last screen lock
                VStack(spacing: 8) {
                    Text("正在专注...")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("继续保持专注状态")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private func formatCurrentSessionTime(_ startTime: Date) -> String {
        let duration = currentTime.timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Recent Sessions Card
struct RecentSessionsCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FocusSession.startTime, ascending: false)],
        animation: .default)
    private var focusSessions: FetchedResults<FocusSession>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("最近专注记录")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if focusSessions.isEmpty {
                Text("暂无专注记录")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(focusSessions.prefix(5)), id: \.objectID) { session in
                        SessionRowView(session: session)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Session Row View
struct SessionRowView: View {
    let session: FocusSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatTime(session.duration))
                    .font(.headline)
                    .foregroundColor(session.isValid ? .primary : .secondary)
                
                Text(formatDate(session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if session.isValid {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.orange)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// 测试代码已移至FocusTrackerTests目标

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(FocusManager(
                usageMonitor: UsageMonitor(),
                viewContext: PersistenceController.preview.container.viewContext
            ))
    }
}