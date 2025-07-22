import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var focusManager: FocusManager
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FocusSession.startTime, ascending: false)],
        animation: .default)
    private var focusSessions: FetchedResults<FocusSession>

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("专注追踪")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Focus Status Indicator
                VStack(spacing: 8) {
                    Text("监测状态")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Circle()
                            .fill(focusManager.isMonitoring ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(focusManager.isMonitoring ? "正在监测" : "未监测")
                            .font(.subheadline)
                            .foregroundColor(focusManager.isMonitoring ? .green : .red)
                    }
                }
                
                // Today's Focus Time
                VStack(spacing: 8) {
                    Text("今日专注时间")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(focusManager.todaysFocusTime))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
                
                // Recent Sessions
                VStack(alignment: .leading, spacing: 12) {
                    Text("最近专注记录")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if focusSessions.isEmpty {
                        Text("暂无专注记录")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(Array(focusSessions.prefix(3)), id: \.objectID) { session in
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
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                // Test Buttons for Development
                VStack(spacing: 12) {
                    Button("添加测试专注记录") {
                        addTestFocusSession()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("添加睡眠时间记录 (应被过滤)") {
                        addSleepTimeFocusSession()
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                // Debug Info
                VStack(spacing: 4) {
                    Text("提示：将应用切换到后台30分钟以上")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("再次打开应用时将记录专注时段")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .padding()
            .navigationTitle("专注追踪")
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func addTestFocusSession() {
        let testSession = FocusSession(context: viewContext)
        testSession.startTime = Date().addingTimeInterval(-45 * 60) // 45 minutes ago
        testSession.endTime = Date()
        testSession.duration = 45 * 60 // 45 minutes
        testSession.isValid = true
        testSession.sessionType = "focus"
        
        do {
            try viewContext.save()
            focusManager.calculateTodaysFocusTime()
            print("Test focus session added successfully")
        } catch {
            print("Error adding test focus session: \(error)")
        }
    }
    
    private func addSleepTimeFocusSession() {
        // Create a session during sleep time (2 AM - 3 AM)
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        
        let sleepSession = FocusSession(context: viewContext)
        sleepSession.startTime = calendar.date(byAdding: .hour, value: 2, to: startOfDay)! // 2 AM
        sleepSession.endTime = calendar.date(byAdding: .hour, value: 3, to: startOfDay)! // 3 AM
        sleepSession.duration = 60 * 60 // 1 hour
        sleepSession.sessionType = "focus"
        
        // Let FocusManager validate this session (should be marked as invalid due to sleep time)
        sleepSession.isValid = focusManager.validateSession(
            startTime: sleepSession.startTime,
            endTime: sleepSession.endTime!,
            duration: sleepSession.duration
        )
        
        do {
            try viewContext.save()
            focusManager.calculateTodaysFocusTime()
            print("Sleep time session added - Valid: \(sleepSession.isValid)")
        } catch {
            print("Error adding sleep time session: \(error)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}