import Foundation
import UserNotifications
import SwiftUI
import CoreData

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // Notification identifiers
    private let dailySummaryIdentifier = "daily-focus-summary"
    private let encouragementIdentifier = "focus-encouragement"
    private let goalAchievedIdentifier = "goal-achieved"
    private let streakAchievedIdentifier = "streak-achieved"
    private let declineWarningIdentifier = "decline-warning"
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Notification Delegate Setup
    
    func setupNotificationDelegate() {
        notificationCenter.delegate = NotificationDelegate.shared
    }
    
    // MARK: - Authorization
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            
            if granted {
                await scheduleDailySummaryNotification()
            }
            
            return granted
        } catch {
            print("NotificationManager: Failed to request permission - \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    // MARK: - Daily Summary Notification
    
    func scheduleDailySummaryNotification() async {
        guard isAuthorized else { return }
        
        // Cancel existing daily summary notifications
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [dailySummaryIdentifier])
        
        let content = UNMutableNotificationContent()
        content.title = "今日专注总结"
        content.body = "查看你今天的专注成果！"
        content.sound = .default
        content.categoryIdentifier = "DAILY_SUMMARY"
        content.userInfo = ["type": "scheduled_daily_summary"]
        
        // Schedule for 9 PM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: dailySummaryIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("NotificationManager: Daily summary notification scheduled for 9 PM")
        } catch {
            print("NotificationManager: Failed to schedule daily summary - \(error)")
        }
    }
    
    // MARK: - Encouragement Notifications
    
    func sendEncouragementNotification(message: String) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "专注鼓励"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "ENCOURAGEMENT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(encouragementIdentifier)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("NotificationManager: Encouragement notification sent")
        } catch {
            print("NotificationManager: Failed to send encouragement - \(error)")
        }
    }
    
    func sendGoalAchievedNotification(focusTime: TimeInterval, goal: TimeInterval) async {
        guard isAuthorized else { return }
        
        let focusHours = Int(focusTime / 3600)
        let focusMinutes = Int((focusTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 目标达成！"
        content.body = "恭喜！你今天已专注 \(focusHours)小时\(focusMinutes)分钟，达成了每日目标！"
        content.sound = .default
        content.categoryIdentifier = "GOAL_ACHIEVED"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(goalAchievedIdentifier)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("NotificationManager: Goal achieved notification sent")
        } catch {
            print("NotificationManager: Failed to send goal achieved notification - \(error)")
        }
    }
    
    // MARK: - Daily Summary with Data
    
    func sendDailySummaryNotification(focusTime: TimeInterval, sessionsCount: Int, longestSession: TimeInterval, goalTime: TimeInterval) async {
        guard isAuthorized else { return }
        
        let focusHours = Int(focusTime / 3600)
        let focusMinutes = Int((focusTime.truncatingRemainder(dividingBy: 3600)) / 60)
        let longestHours = Int(longestSession / 3600)
        let longestMinutes = Int((longestSession.truncatingRemainder(dividingBy: 3600)) / 60)
        
        let content = UNMutableNotificationContent()
        content.title = "今日专注总结"
        
        if focusTime > 0 {
            let goalAchieved = focusTime >= goalTime
            let goalEmoji = goalAchieved ? "🎉 " : ""
            let goalText = goalAchieved ? "，已达成目标！" : ""
            
            content.body = "\(goalEmoji)今天专注了 \(focusHours)小时\(focusMinutes)分钟，共 \(sessionsCount) 个专注时段。最长专注 \(longestHours)小时\(longestMinutes)分钟\(goalText)"
        } else {
            content.body = "今天还没有专注时段，明天继续加油！"
        }
        
        content.sound = .default
        content.categoryIdentifier = "DAILY_SUMMARY"
        content.userInfo = ["type": "daily_summary", "date": Date().timeIntervalSince1970]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(dailySummaryIdentifier)-manual-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("NotificationManager: Manual daily summary sent")
        } catch {
            print("NotificationManager: Failed to send manual daily summary - \(error)")
        }
    }
    
    // MARK: - Streak and Decline Notifications
    
    func sendStreakAchievedNotification(streakDays: Int) async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 连续达标！"
        content.body = "太棒了！你已经连续 \(streakDays) 天达成专注目标，保持这个节奏！"
        content.sound = .default
        content.categoryIdentifier = "STREAK_ACHIEVED"
        content.userInfo = ["type": "streak_achieved", "streak_days": streakDays]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(streakAchievedIdentifier)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("NotificationManager: Streak achieved notification sent for \(streakDays) days")
        } catch {
            print("NotificationManager: Failed to send streak notification - \(error)")
        }
    }
    
    func sendDeclineWarningNotification(todayTime: TimeInterval, yesterdayTime: TimeInterval) async {
        guard isAuthorized else { return }
        
        let declinePercentage = Int(((yesterdayTime - todayTime) / yesterdayTime) * 100)
        
        let content = UNMutableNotificationContent()
        content.title = "💪 继续加油"
        content.body = "今天的专注时间比昨天减少了 \(declinePercentage)%，没关系，明天我们可以做得更好！"
        content.sound = .default
        content.categoryIdentifier = "DECLINE_WARNING"
        content.userInfo = ["type": "decline_warning", "decline_percentage": declinePercentage]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(declineWarningIdentifier)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("NotificationManager: Decline warning notification sent")
        } catch {
            print("NotificationManager: Failed to send decline warning - \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - Settings Integration
    
    func updateNotificationSettings(enabled: Bool) async {
        if enabled && !isAuthorized {
            _ = await requestNotificationPermission()
        } else if enabled && isAuthorized {
            await scheduleDailySummaryNotification()
        } else {
            cancelAllNotifications()
        }
    }
    
    // MARK: - Smart Notification Logic
    
    func checkAndSendSmartNotifications(viewContext: NSManagedObjectContext) async {
        guard isAuthorized else { return }
        
        let today = Date()
        let calendar = Calendar.current
        
        // Get today's focus statistics
        let todayStats = getFocusStatistics(for: today, viewContext: viewContext)
        
        // Get user settings for goal comparison
        let userSettings = getUserSettings(viewContext: viewContext)
        let dailyGoal = userSettings.dailyFocusGoal
        
        // Check for goal achievement
        if todayStats.totalFocusTime >= dailyGoal && todayStats.totalFocusTime > 0 {
            await sendPersonalizedGoalAchievedNotification(
                focusTime: todayStats.totalFocusTime, 
                goal: dailyGoal, 
                viewContext: viewContext
            )
        }
        
        // Check for streak achievement (3+ days)
        let streakDays = calculateCurrentStreak(viewContext: viewContext)
        if streakDays >= 3 {
            await sendPersonalizedStreakNotification(streakDays: streakDays, viewContext: viewContext)
        }
        
        // Check for decline warning (30% decrease from yesterday)
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            let yesterdayStats = getFocusStatistics(for: yesterday, viewContext: viewContext)
            
            if yesterdayStats.totalFocusTime > 0 && todayStats.totalFocusTime > 0 {
                let declinePercentage = (yesterdayStats.totalFocusTime - todayStats.totalFocusTime) / yesterdayStats.totalFocusTime
                
                if declinePercentage >= 0.3 { // 30% or more decline
                    await sendPersonalizedDeclineWarning(
                        todayTime: todayStats.totalFocusTime, 
                        yesterdayTime: yesterdayStats.totalFocusTime,
                        viewContext: viewContext
                    )
                }
            }
        }
        
        // Check for weekly improvement suggestions
        await checkAndSendWeeklyInsights(viewContext: viewContext)
        
        // Check for milestone achievements
        await checkAndSendMilestoneNotifications(viewContext: viewContext)
    }
    
    func sendScheduledDailySummary(viewContext: NSManagedObjectContext) async {
        guard isAuthorized else { return }
        
        let today = Date()
        let todayStats = getFocusStatistics(for: today, viewContext: viewContext)
        let userSettings = getUserSettings(viewContext: viewContext)
        
        await sendDailySummaryNotification(
            focusTime: todayStats.totalFocusTime,
            sessionsCount: todayStats.sessionCount,
            longestSession: todayStats.longestSession,
            goalTime: userSettings.dailyFocusGoal
        )
    }
    
    // MARK: - Helper Methods
    
    private func getFocusStatistics(for date: Date, viewContext: NSManagedObjectContext) -> FocusStatistics {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@ AND isValid == YES", 
                                      startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let sessions = try viewContext.fetch(request)
            let totalTime = sessions.reduce(0) { $0 + $1.duration }
            let longestSession = sessions.map { $0.duration }.max() ?? 0
            let averageSession = sessions.isEmpty ? 0 : totalTime / Double(sessions.count)
            
            return FocusStatistics(
                totalFocusTime: totalTime,
                sessionCount: sessions.count,
                longestSession: longestSession,
                averageSession: averageSession
            )
        } catch {
            print("NotificationManager: Error fetching focus statistics - \(error)")
            return FocusStatistics(totalFocusTime: 0, sessionCount: 0, longestSession: 0, averageSession: 0)
        }
    }
    
    private func getUserSettings(viewContext: NSManagedObjectContext) -> UserSettings {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try viewContext.fetch(request)
            if let userSettings = settings.first {
                return userSettings
            } else {
                return UserSettings.createDefaultSettings(in: viewContext)
            }
        } catch {
            print("NotificationManager: Error fetching user settings - \(error)")
            return UserSettings.createDefaultSettings(in: viewContext)
        }
    }
    
    private func calculateCurrentStreak(viewContext: NSManagedObjectContext) -> Int {
        let calendar = Calendar.current
        let today = Date()
        var streakDays = 0
        
        for i in 0..<30 { // Check up to 30 days back
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let stats = getFocusStatistics(for: date, viewContext: viewContext)
            let userSettings = getUserSettings(viewContext: viewContext)
            
            if stats.totalFocusTime >= userSettings.dailyFocusGoal {
                streakDays += 1
            } else {
                break // Streak is broken
            }
        }
        
        return streakDays
    }
    
    // MARK: - Personalized Notifications
    
    private func sendPersonalizedGoalAchievedNotification(focusTime: TimeInterval, goal: TimeInterval, viewContext: NSManagedObjectContext) async {
        let streakDays = calculateCurrentStreak(viewContext: viewContext)
        let focusHours = Int(focusTime / 3600)
        let focusMinutes = Int((focusTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 目标达成！"
        
        // Personalize based on streak and performance
        if streakDays >= 7 {
            content.body = "太棒了！你已经连续 \(streakDays) 天达成目标，今天专注了 \(focusHours)小时\(focusMinutes)分钟。你正在建立一个强大的专注习惯！"
        } else if focusTime > goal * 1.5 {
            content.body = "惊人的表现！今天专注了 \(focusHours)小时\(focusMinutes)分钟，超出目标 \(Int(((focusTime - goal) / goal) * 100))%！"
        } else {
            content.body = "恭喜！你今天已专注 \(focusHours)小时\(focusMinutes)分钟，成功达成了每日目标！"
        }
        
        content.sound = .default
        content.categoryIdentifier = "GOAL_ACHIEVED"
        content.userInfo = ["type": "goal_achieved", "streak_days": streakDays]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(goalAchievedIdentifier)-personalized-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("NotificationManager: Personalized goal achieved notification sent")
        } catch {
            print("NotificationManager: Failed to send personalized goal notification - \(error)")
        }
    }
    
    private func sendPersonalizedStreakNotification(streakDays: Int, viewContext: NSManagedObjectContext) async {
        // Only send streak notifications at meaningful milestones
        let shouldSendNotification = streakDays == 3 || streakDays == 7 || streakDays == 14 || 
                                   streakDays == 30 || streakDays % 30 == 0
        
        guard shouldSendNotification else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 连续达标！"
        
        // Personalize based on streak length
        switch streakDays {
        case 3:
            content.body = "太棒了！你已经连续 3 天达成专注目标，专注习惯正在形成！"
        case 7:
            content.body = "一周连续达标！🎉 你的专注力正在稳步提升，继续保持这个节奏！"
        case 14:
            content.body = "两周连续达标！💪 你已经证明了自己的毅力，专注已经成为你的习惯！"
        case 30:
            content.body = "一个月连续达标！🏆 你已经建立了强大的专注习惯，这是一个了不起的成就！"
        default:
            if streakDays >= 60 {
                content.body = "连续 \(streakDays) 天达标！🌟 你的专注力已经达到了大师级别，继续创造奇迹！"
            } else {
                content.body = "连续 \(streakDays) 天达标！🔥 你的坚持令人敬佩，继续保持这个优秀的习惯！"
            }
        }
        
        content.sound = .default
        content.categoryIdentifier = "STREAK_ACHIEVED"
        content.userInfo = ["type": "streak_achieved", "streak_days": streakDays]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(streakAchievedIdentifier)-personalized-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("NotificationManager: Personalized streak notification sent for \(streakDays) days")
        } catch {
            print("NotificationManager: Failed to send personalized streak notification - \(error)")
        }
    }
    
    private func sendPersonalizedDeclineWarning(todayTime: TimeInterval, yesterdayTime: TimeInterval, viewContext: NSManagedObjectContext) async {
        let declinePercentage = Int(((yesterdayTime - todayTime) / yesterdayTime) * 100)
        let streakDays = calculateCurrentStreak(viewContext: viewContext)
        
        let content = UNMutableNotificationContent()
        content.title = "💪 继续加油"
        
        // Personalize based on streak and decline severity
        if streakDays >= 7 {
            content.body = "虽然今天的专注时间比昨天减少了 \(declinePercentage)%，但你已经连续 \(streakDays) 天达标了！偶尔的波动很正常，明天继续保持优秀的习惯！"
        } else if declinePercentage >= 50 {
            content.body = "今天的专注时间比昨天减少了 \(declinePercentage)%，没关系，每个人都有起伏。重要的是重新开始，明天我们可以做得更好！"
        } else {
            content.body = "今天的专注时间比昨天减少了 \(declinePercentage)%，这只是一个小波动。保持积极的心态，明天继续努力！"
        }
        
        content.sound = .default
        content.categoryIdentifier = "DECLINE_WARNING"
        content.userInfo = ["type": "decline_warning", "decline_percentage": declinePercentage]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(declineWarningIdentifier)-personalized-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("NotificationManager: Personalized decline warning sent")
        } catch {
            print("NotificationManager: Failed to send personalized decline warning - \(error)")
        }
    }
    
    // MARK: - Weekly Insights
    
    private func checkAndSendWeeklyInsights(viewContext: NSManagedObjectContext) async {
        let calendar = Calendar.current
        let today = Date()
        
        // Only send weekly insights on Sundays
        guard calendar.component(.weekday, from: today) == 1 else { return }
        
        let weeklyData = getWeeklyTrend(viewContext: viewContext)
        let totalWeeklyTime = weeklyData.reduce(0) { $0 + $1.totalFocusTime }
        let averageDailyTime = totalWeeklyTime / 7
        let userSettings = getUserSettings(viewContext: viewContext)
        
        let content = UNMutableNotificationContent()
        content.title = "📊 本周专注总结"
        
        let weeklyHours = Int(totalWeeklyTime / 3600)
        let weeklyMinutes = Int((totalWeeklyTime.truncatingRemainder(dividingBy: 3600)) / 60)
        let avgHours = Int(averageDailyTime / 3600)
        let avgMinutes = Int((averageDailyTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if averageDailyTime >= userSettings.dailyFocusGoal {
            content.body = "本周表现优秀！总共专注了 \(weeklyHours)小时\(weeklyMinutes)分钟，平均每天 \(avgHours)小时\(avgMinutes)分钟。继续保持这个节奏！"
        } else {
            content.body = "本周专注了 \(weeklyHours)小时\(weeklyMinutes)分钟，平均每天 \(avgHours)小时\(avgMinutes)分钟。下周让我们一起努力达到更高的目标！"
        }
        
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_INSIGHTS"
        content.userInfo = ["type": "weekly_insights"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "weekly-insights-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("NotificationManager: Weekly insights notification sent")
        } catch {
            print("NotificationManager: Failed to send weekly insights - \(error)")
        }
    }
    
    // MARK: - Milestone Notifications
    
    private func checkAndSendMilestoneNotifications(viewContext: NSManagedObjectContext) async {
        let totalFocusTime = getTotalFocusTime(viewContext: viewContext)
        let totalHours = Int(totalFocusTime / 3600)
        
        // Check for hour milestones
        let milestones = [10, 25, 50, 100, 200, 500, 1000]
        
        for milestone in milestones {
            if totalHours >= milestone && !hasNotifiedForMilestone(milestone) {
                await sendMilestoneNotification(hours: milestone)
                markMilestoneAsNotified(milestone)
                break // Only send one milestone notification at a time
            }
        }
    }
    
    private func sendMilestoneNotification(hours: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "🏆 里程碑达成！"
        
        switch hours {
        case 10:
            content.body = "恭喜！你已经累计专注了 10 小时，这是一个很好的开始！"
        case 25:
            content.body = "太棒了！你已经累计专注了 25 小时，专注习惯正在形成！"
        case 50:
            content.body = "了不起！你已经累计专注了 50 小时，这相当于一个工作周的专注时间！"
        case 100:
            content.body = "惊人的成就！你已经累计专注了 100 小时，这是真正的专注大师！"
        case 200:
            content.body = "令人敬佩！你已经累计专注了 200 小时，你的毅力令人钦佩！"
        case 500:
            content.body = "传奇级成就！你已经累计专注了 500 小时，这是专注力的巅峰表现！"
        case 1000:
            content.body = "史诗级成就！你已经累计专注了 1000 小时，你已经成为专注力的传奇！"
        default:
            content.body = "恭喜！你已经累计专注了 \(hours) 小时，这是一个了不起的成就！"
        }
        
        content.sound = .default
        content.categoryIdentifier = "MILESTONE_ACHIEVED"
        content.userInfo = ["type": "milestone_achieved", "hours": hours]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "milestone-\(hours)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("NotificationManager: Milestone notification sent for \(hours) hours")
        } catch {
            print("NotificationManager: Failed to send milestone notification - \(error)")
        }
    }
    
    // MARK: - Helper Methods for Advanced Features
    
    private func getWeeklyTrend(viewContext: NSManagedObjectContext) -> [DailyFocusData] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [DailyFocusData] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let stats = getFocusStatistics(for: date, viewContext: viewContext)
            
            weeklyData.append(DailyFocusData(
                date: date,
                totalFocusTime: stats.totalFocusTime,
                sessionCount: stats.sessionCount
            ))
        }
        
        return weeklyData.reversed()
    }
    
    private func getTotalFocusTime(viewContext: NSManagedObjectContext) -> TimeInterval {
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        request.predicate = NSPredicate(format: "isValid == YES")
        
        do {
            let sessions = try viewContext.fetch(request)
            return sessions.reduce(0) { $0 + $1.duration }
        } catch {
            print("NotificationManager: Error fetching total focus time - \(error)")
            return 0
        }
    }
    
    private func hasNotifiedForMilestone(_ hours: Int) -> Bool {
        // In a real implementation, this would check UserDefaults or Core Data
        // For now, we'll use a simple UserDefaults check
        return UserDefaults.standard.bool(forKey: "milestone_notified_\(hours)")
    }
    
    private func markMilestoneAsNotified(_ hours: Int) {
        UserDefaults.standard.set(true, forKey: "milestone_notified_\(hours)")
    }
}

// MARK: - Notification Categories

extension NotificationManager {
    func setupNotificationCategories() {
        let viewStatsAction = UNNotificationAction(
            identifier: "VIEW_STATS",
            title: "查看统计",
            options: [.foreground]
        )
        
        let dailySummaryCategory = UNNotificationCategory(
            identifier: "DAILY_SUMMARY",
            actions: [viewStatsAction],
            intentIdentifiers: [],
            options: []
        )
        
        let encouragementCategory = UNNotificationCategory(
            identifier: "ENCOURAGEMENT",
            actions: [viewStatsAction],
            intentIdentifiers: [],
            options: []
        )
        
        let goalAchievedCategory = UNNotificationCategory(
            identifier: "GOAL_ACHIEVED",
            actions: [viewStatsAction],
            intentIdentifiers: [],
            options: []
        )
        
        let streakAchievedCategory = UNNotificationCategory(
            identifier: "STREAK_ACHIEVED",
            actions: [viewStatsAction],
            intentIdentifiers: [],
            options: []
        )
        
        let declineWarningCategory = UNNotificationCategory(
            identifier: "DECLINE_WARNING",
            actions: [viewStatsAction],
            intentIdentifiers: [],
            options: []
        )
        
        let weeklyInsightsCategory = UNNotificationCategory(
            identifier: "WEEKLY_INSIGHTS",
            actions: [viewStatsAction],
            intentIdentifiers: [],
            options: []
        )
        
        let milestoneAchievedCategory = UNNotificationCategory(
            identifier: "MILESTONE_ACHIEVED",
            actions: [viewStatsAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            dailySummaryCategory,
            encouragementCategory,
            goalAchievedCategory,
            streakAchievedCategory,
            declineWarningCategory,
            weeklyInsightsCategory,
            milestoneAchievedCategory
        ])
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        let notificationType = userInfo["type"] as? String ?? ""
        
        // Handle scheduled daily summary by sending actual data
        if notificationType == "scheduled_daily_summary" {
            Task {
                await handleScheduledDailySummary()
            }
        }
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        let notificationType = userInfo["type"] as? String ?? ""
        
        print("NotificationDelegate: Received notification tap for type: \(notificationType)")
        
        // Handle different notification types
        switch notificationType {
        case "daily_summary", "scheduled_daily_summary":
            // Navigate to statistics view
            NotificationCenter.default.post(name: .navigateToStatistics, object: nil)
            
        case "goal_achieved", "streak_achieved":
            // Navigate to home view to show achievement
            NotificationCenter.default.post(name: .navigateToHome, object: nil)
            
        case "decline_warning":
            // Navigate to home view to encourage user
            NotificationCenter.default.post(name: .navigateToHome, object: nil)
            
        case "weekly_insights":
            // Navigate to statistics view
            NotificationCenter.default.post(name: .navigateToStatistics, object: nil)
            
        case "milestone_achieved":
            // Navigate to statistics view to show milestone
            NotificationCenter.default.post(name: .navigateToStatistics, object: nil)
            
        default:
            // Default navigation to home
            NotificationCenter.default.post(name: .navigateToHome, object: nil)
        }
        
        completionHandler()
    }
    
    // MARK: - Scheduled Notification Handling
    
    private func handleScheduledDailySummary() async {
        // Get the main context for data access
        let viewContext = PersistenceController.shared.container.viewContext
        
        // Send the actual daily summary with data
        await NotificationManager.shared.sendScheduledDailySummary(viewContext: viewContext)
    }
}

// MARK: - Navigation Notifications

extension Notification.Name {
    static let navigateToHome = Notification.Name("navigateToHome")
    static let navigateToStatistics = Notification.Name("navigateToStatistics")
    static let navigateToSettings = Notification.Name("navigateToSettings")
}