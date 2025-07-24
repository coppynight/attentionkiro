import SwiftUI
import CoreData

struct TestView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var tagManager: TagManager
    @State private var testResults: String = "Press buttons to test notifications and tags"
    @State private var isRunningTests = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("系统功能测试")
                    .font(.title)
                    .padding()
                
                // Tag Manager Tests Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("标签管理测试")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Button(action: {
                        testTagInitialization()
                    }) {
                        HStack {
                            Image(systemName: "tag.fill")
                            Text("测试标签初始化")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        testTagRecommendation()
                    }) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                            Text("测试标签推荐")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        testCustomTagCreation()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("测试自定义标签创建")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.mint)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding()
                
                // Test Data Insertion Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("测试数据插入")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Button(action: {
                        insertTestFocusSessions()
                    }) {
                        HStack {
                            Image(systemName: "clock.fill")
                            Text("插入测试专注时段")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.cyan)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        insertTestAppUsageSessions()
                    }) {
                        HStack {
                            Image(systemName: "apps.iphone")
                            Text("插入测试应用使用记录")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.brown)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        insertWeeklyTestData()
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("插入一周测试数据")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        clearAllTestData()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("清除所有测试数据")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding()
                
                Text("通知系统测试")
                    .font(.headline)
                    .padding(.horizontal)
                
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
        testResults = "正在请求通知权限...\n"
        
        Task {
            let granted = await notificationManager.requestNotificationPermission()
            await MainActor.run {
                testResults += "通知权限请求结果: \(granted ? "已授权" : "被拒绝")\n"
                testResults += "当前授权状态: \(notificationManager.isAuthorized ? "已授权" : "未授权")\n"
            }
        }
    }
    
    private func testDailySummary() {
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
    }
    
    private func testGoalAchievement() {
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
    }
    
    private func testStreakAchievement() {
        testResults = "正在发送连续达标通知...\n"
        
        Task {
            await notificationManager.sendStreakAchievedNotification(streakDays: 5)
            
            await MainActor.run {
                testResults += "连续达标通知已发送 (5天)\n"
            }
        }
    }
    
    private func testDeclineWarning() {
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
    }
    
    private func testSmartNotifications() {
        isRunningTests = true
        testResults = "正在测试智能通知系统...\n"
        
        Task {
            await notificationManager.checkAndSendSmartNotifications(viewContext: viewContext)
            
            await MainActor.run {
                testResults += "智能通知检查完成\n"
                isRunningTests = false
            }
        }
    }
    
    // MARK: - Tag Manager Test Methods
    
    private func testTagInitialization() {
        testResults = "正在测试标签初始化...\n"
        
        let defaultTags = tagManager.getDefaultTags()
        let allTags = tagManager.getAllTags()
        
        testResults += "默认标签数量: \(defaultTags.count)\n"
        testResults += "总标签数量: \(allTags.count)\n"
        testResults += "标签列表:\n"
        
        for tag in allTags {
            testResults += "  - \(tag.name) (\(tag.isDefault ? "默认" : "自定义")) - 使用次数: \(tag.usageCount)\n"
        }
        
        testResults += "标签初始化测试完成\n"
    }
    
    private func testTagRecommendation() {
        testResults = "正在测试标签推荐...\n"
        
        let testApps = [
            "com.microsoft.Office.Word",
            "com.tencent.xin",
            "com.netflix.Netflix",
            "com.apple.Health",
            "com.taobao.taobao4iphone",
            "com.autonavi.amap",
            "com.unknown.app"
        ]
        
        for appId in testApps {
            if let recommendation = tagManager.suggestTagForApp(appId) {
                testResults += "\(appId):\n"
                testResults += "  推荐标签: \(recommendation.tag.name)\n"
                testResults += "  置信度: \(String(format: "%.1f", recommendation.confidence))\n"
                testResults += "  原因: \(recommendation.reason)\n\n"
            } else {
                testResults += "\(appId): 无推荐标签\n\n"
            }
        }
        
        testResults += "标签推荐测试完成\n"
    }
    
    private func testCustomTagCreation() {
        testResults = "正在测试自定义标签创建...\n"
        
        let testTagName = "测试标签_\(Int.random(in: 1000...9999))"
        let testColor = "#FF6B6B"
        
        if let newTag = tagManager.createCustomTag(name: testTagName, color: testColor) {
            testResults += "成功创建自定义标签:\n"
            testResults += "  名称: \(newTag.name)\n"
            testResults += "  颜色: \(newTag.color)\n"
            testResults += "  ID: \(newTag.tagID)\n"
            testResults += "  创建时间: \(newTag.createdAt)\n"
            
            // Test tag deletion
            if tagManager.deleteTag(newTag) {
                testResults += "成功删除测试标签\n"
            } else {
                testResults += "删除测试标签失败\n"
            }
        } else {
            testResults += "创建自定义标签失败\n"
        }
        
        testResults += "自定义标签创建测试完成\n"
    }
    
    // MARK: - Test Data Insertion Methods
    
    private func insertTestFocusSessions() {
        testResults = "正在插入测试专注时段...\n"
        
        let now = Date()
        
        // Create test focus sessions for the past few days
        let testSessions = [
            // Today
            (startOffset: -2 * 3600, duration: 45 * 60, isValid: true), // 2 hours ago, 45 min
            (startOffset: -4 * 3600, duration: 90 * 60, isValid: true), // 4 hours ago, 1.5 hours
            
            // Yesterday
            (startOffset: -24 * 3600 - 3 * 3600, duration: 60 * 60, isValid: true), // Yesterday 3pm, 1 hour
            (startOffset: -24 * 3600 - 6 * 3600, duration: 30 * 60, isValid: true), // Yesterday 12pm, 30 min
            (startOffset: -24 * 3600 - 8 * 3600, duration: 20 * 60, isValid: false), // Yesterday 10am, 20 min (invalid)
            
            // 2 days ago
            (startOffset: -48 * 3600 - 2 * 3600, duration: 120 * 60, isValid: true), // 2 days ago 2pm, 2 hours
            (startOffset: -48 * 3600 - 5 * 3600, duration: 75 * 60, isValid: true), // 2 days ago 11am, 1.25 hours
            
            // 3 days ago
            (startOffset: -72 * 3600 - 4 * 3600, duration: 40 * 60, isValid: true), // 3 days ago 12pm, 40 min
        ]
        
        var createdCount = 0
        
        for (startOffset, duration, isValid) in testSessions {
            let startTime = now.addingTimeInterval(TimeInterval(startOffset))
            let endTime = startTime.addingTimeInterval(TimeInterval(duration))
            
            let focusSession = FocusSession(context: viewContext)
            focusSession.startTime = startTime
            focusSession.endTime = endTime
            focusSession.duration = TimeInterval(duration)
            focusSession.sessionType = "focus"
            focusSession.isValid = isValid
            
            createdCount += 1
        }
        
        do {
            try viewContext.save()
            testResults += "成功插入 \(createdCount) 个专注时段记录\n"
            testResults += "包含有效时段和无效时段用于测试验证逻辑\n"
        } catch {
            testResults += "插入专注时段失败: \(error.localizedDescription)\n"
        }
        
        testResults += "专注时段插入完成\n"
    }
    
    private func insertTestAppUsageSessions() {
        testResults = "正在插入测试应用使用记录...\n"
        
        let calendar = Calendar.current
        let now = Date()
        
        // Test apps with different categories and tags
        let testApps = [
            ("com.microsoft.Office.Word", "Microsoft Word", "productivity", "工作"),
            ("com.tencent.xin", "微信", "social", "社交"),
            ("com.netflix.Netflix", "Netflix", "entertainment", "娱乐"),
            ("com.apple.Health", "健康", "health", "健康"),
            ("com.taobao.taobao4iphone", "淘宝", "shopping", "购物"),
            ("com.autonavi.amap", "高德地图", "navigation", "出行"),
            ("com.duolingo.DuolingoMobile", "Duolingo", "education", "学习"),
            ("com.apple.mobilesafari", "Safari", "productivity", "工作"),
            ("com.spotify.client", "Spotify", "entertainment", "娱乐"),
            ("com.zhihu.ios", "知乎", "social", "学习")
        ]
        
        var createdCount = 0
        
        // Create sessions for the past 3 days
        for dayOffset in 0..<3 {
            let baseDate = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            
            // Create multiple sessions per day
            for (appId, appName, category, tag) in testApps.shuffled().prefix(6) {
                let sessionCount = Int.random(in: 1...3)
                
                for _ in 0..<sessionCount {
                    let hourOffset = Int.random(in: 8...20) // Between 8 AM and 8 PM
                    let minuteOffset = Int.random(in: 0...59)
                    let duration = TimeInterval(Int.random(in: 5...120) * 60) // 5 to 120 minutes
                    
                    let startTime = calendar.date(bySettingHour: hourOffset, minute: minuteOffset, second: 0, of: baseDate)!
                    let endTime = startTime.addingTimeInterval(duration)
                    
                    let session = AppUsageSession.createSession(
                        appIdentifier: appId,
                        appName: appName,
                        categoryIdentifier: category,
                        startTime: startTime,
                        in: viewContext
                    )
                    
                    session.endTime = endTime
                    session.duration = duration
                    session.sceneTag = tag
                    session.isProductiveTime = ["productivity", "education", "business"].contains(category)
                    session.interruptionCount = Int16(Int.random(in: 0...3))
                    
                    createdCount += 1
                }
            }
        }
        
        do {
            try viewContext.save()
            testResults += "成功插入 \(createdCount) 个应用使用记录\n"
            testResults += "涵盖多个应用类别和场景标签\n"
        } catch {
            testResults += "插入应用使用记录失败: \(error.localizedDescription)\n"
        }
        
        testResults += "应用使用记录插入完成\n"
    }
    
    private func insertWeeklyTestData() {
        testResults = "正在插入一周测试数据...\n"
        
        let calendar = Calendar.current
        let now = Date()
        
        var totalFocusSessions = 0
        var totalAppSessions = 0
        
        // Insert data for the past 7 days
        for dayOffset in 0..<7 {
            let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let isWeekend = calendar.isDateInWeekend(targetDate)
            
            // Focus sessions (fewer on weekends)
            let focusSessionCount = isWeekend ? Int.random(in: 1...3) : Int.random(in: 2...5)
            
            for _ in 0..<focusSessionCount {
                let hour = isWeekend ? Int.random(in: 10...22) : Int.random(in: 9...18)
                let minute = Int.random(in: 0...59)
                let duration = TimeInterval(Int.random(in: 30...180) * 60) // 30 min to 3 hours
                
                let startTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDate)!
                let endTime = startTime.addingTimeInterval(duration)
                
                let focusSession = FocusSession(context: viewContext)
                focusSession.startTime = startTime
                focusSession.endTime = endTime
                focusSession.duration = duration
                focusSession.sessionType = "focus"
                focusSession.isValid = duration >= 30 * 60 // Valid if >= 30 minutes
                
                totalFocusSessions += 1
            }
            
            // App usage sessions (more variety on weekends)
            let appSessionCount = isWeekend ? Int.random(in: 8...15) : Int.random(in: 5...12)
            
            let workApps = [
                ("com.microsoft.Office.Word", "Microsoft Word", "productivity", "工作"),
                ("com.slack.Slack", "Slack", "productivity", "工作"),
                ("com.apple.mail", "邮件", "productivity", "工作")
            ]
            
            let leisureApps = [
                ("com.netflix.Netflix", "Netflix", "entertainment", "娱乐"),
                ("com.tencent.xin", "微信", "social", "社交"),
                ("com.sina.weibo", "微博", "social", "社交"),
                ("com.youku.YouKu", "优酷", "entertainment", "娱乐")
            ]
            
            let studyApps = [
                ("com.duolingo.DuolingoMobile", "Duolingo", "education", "学习"),
                ("com.apple.iBooks", "图书", "education", "学习"),
                ("com.khanacademy.Khan-Academy", "Khan Academy", "education", "学习")
            ]
            
            let appsToUse = isWeekend ? (leisureApps + studyApps) : (workApps + leisureApps.prefix(2))
            
            for _ in 0..<appSessionCount {
                let (appId, appName, category, tag) = appsToUse.randomElement()!
                let hour = Int.random(in: 8...22)
                let minute = Int.random(in: 0...59)
                let duration = TimeInterval(Int.random(in: 2...90) * 60) // 2 to 90 minutes
                
                let startTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDate)!
                let endTime = startTime.addingTimeInterval(duration)
                
                let session = AppUsageSession.createSession(
                    appIdentifier: appId,
                    appName: appName,
                    categoryIdentifier: category,
                    startTime: startTime,
                    in: viewContext
                )
                
                session.endTime = endTime
                session.duration = duration
                session.sceneTag = tag
                session.isProductiveTime = ["productivity", "education"].contains(category)
                session.interruptionCount = Int16(Int.random(in: 0...2))
                
                totalAppSessions += 1
            }
        }
        
        do {
            try viewContext.save()
            testResults += "成功插入一周测试数据:\n"
            testResults += "  专注时段: \(totalFocusSessions) 个\n"
            testResults += "  应用使用记录: \(totalAppSessions) 个\n"
            testResults += "  涵盖工作日和周末的不同使用模式\n"
        } catch {
            testResults += "插入一周测试数据失败: \(error.localizedDescription)\n"
        }
        
        testResults += "一周测试数据插入完成\n"
    }
    
    private func clearAllTestData() {
        testResults = "正在清除所有测试数据...\n"
        
        var deletedFocusSessions = 0
        var deletedAppSessions = 0
        var deletedCustomTags = 0
        
        // Delete all focus sessions
        let focusRequest: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        do {
            let focusSessions = try viewContext.fetch(focusRequest)
            for session in focusSessions {
                viewContext.delete(session)
                deletedFocusSessions += 1
            }
        } catch {
            testResults += "删除专注时段失败: \(error.localizedDescription)\n"
        }
        
        // Delete all app usage sessions
        let appRequest: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        do {
            let appSessions = try viewContext.fetch(appRequest)
            for session in appSessions {
                viewContext.delete(session)
                deletedAppSessions += 1
            }
        } catch {
            testResults += "删除应用使用记录失败: \(error.localizedDescription)\n"
        }
        
        // Delete custom tags (keep default tags)
        let tagRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        tagRequest.predicate = NSPredicate(format: "isDefault == NO")
        do {
            let customTags = try viewContext.fetch(tagRequest)
            for tag in customTags {
                viewContext.delete(tag)
                deletedCustomTags += 1
            }
        } catch {
            testResults += "删除自定义标签失败: \(error.localizedDescription)\n"
        }
        
        // Reset default tags usage count
        let defaultTagRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        defaultTagRequest.predicate = NSPredicate(format: "isDefault == YES")
        do {
            let defaultTags = try viewContext.fetch(defaultTagRequest)
            for tag in defaultTags {
                tag.usageCount = 0
                tag.associatedApps = nil
            }
        } catch {
            testResults += "重置默认标签失败: \(error.localizedDescription)\n"
        }
        
        // Save changes
        do {
            try viewContext.save()
            testResults += "成功清除测试数据:\n"
            testResults += "  专注时段: \(deletedFocusSessions) 个\n"
            testResults += "  应用使用记录: \(deletedAppSessions) 个\n"
            testResults += "  自定义标签: \(deletedCustomTags) 个\n"
            testResults += "  默认标签已重置\n"
        } catch {
            testResults += "保存清除操作失败: \(error.localizedDescription)\n"
        }
        
        testResults += "测试数据清除完成\n"
    }
}
