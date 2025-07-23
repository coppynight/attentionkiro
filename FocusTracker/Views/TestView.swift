import SwiftUI
import CoreData

struct TestView: View {
    @Environment(\.managedObjectContext) private var viewContext
    // @EnvironmentObject private var notificationManager: NotificationManager
    @State private var testResults: String = "Press buttons to test notifications"
    @State private var isRunningTests = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("通知系统测试")
                    .font(.title)
                    .padding()
                
                // Notification Permission Test
                Button(action: {
                    testNotificationPermission()
                }) {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("请求通知权限")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Daily Summary Test
                Button(action: {
                    testDailySummary()
                }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text("测试每日总结通知")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Goal Achievement Test
                Button(action: {
                    testGoalAchievement()
                }) {
                    HStack {
                        Image(systemName: "target")
                        Text("测试目标达成通知")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Streak Achievement Test
                Button(action: {
                    testStreakAchievement()
                }) {
                    HStack {
                        Image(systemName: "flame.fill")
                        Text("测试连续达标通知")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Decline Warning Test
                Button(action: {
                    testDeclineWarning()
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("测试下降提醒通知")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Smart Notifications Test
                Button(action: {
                    testSmartNotifications()
                }) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("测试智能通知")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isRunningTests)
                .padding(.horizontal)
                
                if isRunningTests {
                    ProgressView()
                        .padding()
                }
                
                Text(testResults)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding()
            }
        }
        .navigationTitle("通知测试")
    }
    
    // MARK: - Test Methods
    
    private func testNotificationPermission() {
        testResults = "通知功能暂时禁用，等待NotificationManager集成\n"
        /*
        testResults = "正在请求通知权限...\n"
        
        Task {
            let granted = await notificationManager.requestNotificationPermission()
            await MainActor.run {
                testResults += "通知权限请求结果: \(granted ? "已授权" : "被拒绝")\n"
                testResults += "当前授权状态: \(notificationManager.isAuthorized ? "已授权" : "未授权")\n"
            }
        }
        */
    }
    
    private func testDailySummary() {
        testResults = "通知功能暂时禁用，等待NotificationManager集成\n"
        /*
        testResults = "正在发送每日总结通知...\n"
        
        Task {
            await notificationManager.sendDailySummaryNotification(
                focusTime: 3600, // 1 hour
                sessionsCount: 2,
                longestSession: 1800, // 30 minutes
                goalTime: 7200 // 2 hours goal
            )
            
            await MainActor.run {
                testResults += "每日总结通知已发送\n"
            }
        }
        */
    }
    
    private func testGoalAchievement() {
        testResults = "通知功能暂时禁用，等待NotificationManager集成\n"
        /*
        testResults = "正在发送目标达成通知...\n"
        
        Task {
            await notificationManager.sendGoalAchievedNotification(
                focusTime: 7200, // 2 hours
                goal: 7200 // 2 hours goal
            )
            
            await MainActor.run {
                testResults += "目标达成通知已发送\n"
            }
        }
        */
    }
    
    private func testStreakAchievement() {
        testResults = "通知功能暂时禁用，等待NotificationManager集成\n"
        /*
        testResults = "正在发送连续达标通知...\n"
        
        Task {
            await notificationManager.sendStreakAchievedNotification(streakDays: 5)
            
            await MainActor.run {
                testResults += "连续达标通知已发送 (5天)\n"
            }
        }
        */
    }
    
    private func testDeclineWarning() {
        testResults = "通知功能暂时禁用，等待NotificationManager集成\n"
        /*
        testResults = "正在发送下降提醒通知...\n"
        
        Task {
            await notificationManager.sendDeclineWarningNotification(
                todayTime: 1800, // 30 minutes today
                yesterdayTime: 3600 // 1 hour yesterday
            )
            
            await MainActor.run {
                testResults += "下降提醒通知已发送\n"
            }
        }
        */
    }
    
    private func testSmartNotifications() {
        testResults = "通知功能暂时禁用，等待NotificationManager集成\n"
        /*
        isRunningTests = true
        testResults = "正在测试智能通知系统...\n"
        
        Task {
            await notificationManager.checkAndSendSmartNotifications(viewContext: viewContext)
            
            await MainActor.run {
                testResults += "智能通知检查完成\n"
                isRunningTests = false
            }
        }
        */
    }
}
