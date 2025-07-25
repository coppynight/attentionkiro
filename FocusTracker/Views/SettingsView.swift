import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var userSettings: UserSettings?
    @State private var showingGoalPicker = false
    @State private var showingUsageGoalPicker = false
    @State private var showingSleepTimePicker = false
    @State private var showingLunchTimePicker = false
    @State private var showingTimeZonePicker = false
    @State private var showingNotificationAlert = false
    
    // Temporary state for pickers
    @State private var tempDailyGoal: Double = 2.0 // hours
    @State private var tempDailyUsageGoal: Double = 4.0 // hours
    @State private var tempSleepStart = Calendar.current.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
    @State private var tempSleepEnd = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var tempLunchStart = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @State private var tempLunchEnd = Calendar.current.date(from: DateComponents(hour: 14, minute: 0)) ?? Date()
    @State private var tempLunchEnabled = false
    @State private var tempNotificationsEnabled = true
    @State private var tempUseLocalTimeZone = true
    @State private var tempTimeZoneOffset: Double = 0.0
    @State private var tempFlexibleSleepDays = false
    
    // Computed properties for notification status
    private var notificationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return tempNotificationsEnabled ? "已启用" : "已禁用"
        case .denied:
            return "权限被拒绝"
        case .notDetermined:
            return "需要权限"
        case .provisional:
            return "临时授权"
        case .ephemeral:
            return "临时权限"
        @unknown default:
            return "未知状态"
        }
    }
    
    private var notificationStatusColor: Color {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return tempNotificationsEnabled ? .green : .secondary
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .provisional, .ephemeral:
            return .blue
        @unknown default:
            return .secondary
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button(action: {
                        showingGoalPicker = true
                    }) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("专注目标")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(formatGoalTime(tempDailyGoal))
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        showingUsageGoalPicker = true
                    }) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            Text("使用时间目标")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(formatGoalTime(tempDailyUsageGoal))
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("目标设置")
                } footer: {
                    Text("专注目标是您希望每天达到的专注时间，使用时间目标是您希望控制的每日手机使用时间上限")
                }
                
                Section {
                    Button(action: {
                        showingSleepTimePicker = true
                    }) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            Text("睡眠时间")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(formatTime(tempSleepStart)) - \(formatTime(tempSleepEnd))")
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        showingLunchTimePicker = true
                    }) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("午休时间")
                                    .foregroundColor(.primary)
                                
                                if !tempLunchEnabled {
                                    Text("已禁用")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if tempLunchEnabled {
                                Text("\(formatTime(tempLunchStart)) - \(formatTime(tempLunchEnd))")
                                    .foregroundColor(.secondary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        showingTimeZonePicker = true
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("时区设置")
                                    .foregroundColor(.primary)
                                
                                Text(tempUseLocalTimeZone ? "使用系统时区" : formatTimeZoneOffset(tempTimeZoneOffset))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Toggle(isOn: $tempFlexibleSleepDays) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("周末灵活睡眠时间")
                                    .foregroundColor(.primary)
                                
                                Text("周末不应用睡眠时间过滤")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: tempFlexibleSleepDays) { _ in
                        saveSettings()
                    }
                } header: {
                    Text("时间设置")
                } footer: {
                    Text("在睡眠和午休时间内的手机未使用时段不会被计算为专注时间")
                }
                
                Section {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("每日通知")
                                .foregroundColor(.primary)
                            
                            Text(notificationStatusText)
                                .font(.caption)
                                .foregroundColor(notificationStatusColor)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $tempNotificationsEnabled)
                            .onChange(of: tempNotificationsEnabled) { newValue in
                                handleNotificationToggle(newValue)
                            }
                    }
                    
                    if tempNotificationsEnabled && !notificationManager.isAuthorized {
                        Button(action: {
                            requestNotificationPermission()
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("需要通知权限")
                                        .foregroundColor(.primary)
                                    
                                    Text("点击以请求通知权限")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                } header: {
                    Text("通知设置")
                } footer: {
                    Text("每日晚上9点发送专注时间总结通知，包括今日专注时长和鼓励信息。还会在达成目标、连续达标和专注下降时发送智能提醒。")
                }
                
                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("关于应用")
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.gray)
                            .frame(width: 24)
                        
                        Text("使用帮助")
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                } header: {
                    Text("其他")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadSettings()
            }
            .sheet(isPresented: $showingGoalPicker) {
                GoalPickerView(selectedGoal: $tempDailyGoal, goalType: .focus) {
                    saveSettings()
                }
            }
            .sheet(isPresented: $showingUsageGoalPicker) {
                GoalPickerView(selectedGoal: $tempDailyUsageGoal, goalType: .usage) {
                    saveSettings()
                }
            }
            .sheet(isPresented: $showingSleepTimePicker) {
                EnhancedSleepTimePickerView(
                    sleepStart: $tempSleepStart,
                    sleepEnd: $tempSleepEnd,
                    flexibleSleepDays: $tempFlexibleSleepDays
                ) {
                    saveSettings()
                }
            }
            .sheet(isPresented: $showingLunchTimePicker) {
                EnhancedLunchTimePickerView(
                    lunchEnabled: $tempLunchEnabled,
                    lunchStart: $tempLunchStart,
                    lunchEnd: $tempLunchEnd
                ) {
                    saveSettings()
                }
            }
            .sheet(isPresented: $showingTimeZonePicker) {
                TimeZonePickerView(
                    useLocalTimeZone: $tempUseLocalTimeZone,
                    timeZoneOffset: $tempTimeZoneOffset
                ) {
                    saveSettings()
                }
            }
        }
    }
    
    private func loadSettings() {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try viewContext.fetch(request)
            if let userSettings = settings.first {
                self.userSettings = userSettings
                tempDailyGoal = userSettings.dailyFocusGoal / 3600 // Convert seconds to hours
                tempDailyUsageGoal = userSettings.dailyUsageGoal / 3600 // Convert seconds to hours
                tempSleepStart = userSettings.sleepStartTime
                tempSleepEnd = userSettings.sleepEndTime
                tempLunchEnabled = userSettings.lunchBreakEnabled
                tempLunchStart = userSettings.lunchBreakStart ?? Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
                tempLunchEnd = userSettings.lunchBreakEnd ?? Calendar.current.date(from: DateComponents(hour: 14, minute: 0)) ?? Date()
                tempNotificationsEnabled = userSettings.notificationsEnabled
                tempUseLocalTimeZone = userSettings.useLocalTimeZone
                tempTimeZoneOffset = userSettings.timeZoneOffset
                tempFlexibleSleepDays = userSettings.flexibleSleepDays
            } else {
                // Create default settings
                let defaultSettings = UserSettings.createDefaultSettings(in: viewContext)
                try viewContext.save()
                self.userSettings = defaultSettings
                loadSettings() // Reload with default values
            }
        } catch {
            print("Error loading user settings: \(error)")
        }
    }
    
    private func saveSettings() {
        guard let settings = userSettings else { return }
        
        settings.dailyFocusGoal = tempDailyGoal * 3600 // Convert hours to seconds
        settings.dailyUsageGoal = tempDailyUsageGoal * 3600 // Convert hours to seconds
        settings.sleepStartTime = tempSleepStart
        settings.sleepEndTime = tempSleepEnd
        settings.lunchBreakEnabled = tempLunchEnabled
        settings.lunchBreakStart = tempLunchStart
        settings.lunchBreakEnd = tempLunchEnd
        settings.notificationsEnabled = tempNotificationsEnabled
        settings.useLocalTimeZone = tempUseLocalTimeZone
        settings.timeZoneOffset = tempTimeZoneOffset
        settings.flexibleSleepDays = tempFlexibleSleepDays
        
        do {
            try viewContext.save()
            print("Settings saved successfully")
        } catch {
            print("Error saving settings: \(error)")
        }
    }
    
    private func formatGoalTime(_ hours: Double) -> String {
        if hours == 1.0 {
            return "1小时"
        } else if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(hours))小时"
        } else {
            let h = Int(hours)
            let m = Int((hours - Double(h)) * 60)
            return "\(h)小时\(m)分钟"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func formatTimeZoneOffset(_ offset: Double) -> String {
        let hours = Int(offset)
        let minutes = Int(abs(offset.truncatingRemainder(dividingBy: 1)) * 60)
        
        let sign = offset >= 0 ? "+" : "-"
        return String(format: "GMT%@%02d:%02d", sign, abs(hours), minutes)
    }
    
    // MARK: - Notification Methods
    
    private func handleNotificationToggle(_ enabled: Bool) {
        Task {
            await notificationManager.updateNotificationSettings(enabled: enabled)
            
            // Update the authorization status after the toggle
            await notificationManager.checkAuthorizationStatus()
        }
        
        saveSettings()
    }
    
    private func requestNotificationPermission() {
        Task {
            let granted = await notificationManager.requestNotificationPermission()
            
            if granted {
                tempNotificationsEnabled = true
                saveSettings()
            } else {
                // Show alert explaining why notifications are important
                showingNotificationAlert = true
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

// MARK: - Goal Picker View
struct GoalPickerView: View {
    @Binding var selectedGoal: Double
    let goalType: GoalType
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    enum GoalType {
        case focus
        case usage
        
        var title: String {
            switch self {
            case .focus: return "专注目标"
            case .usage: return "使用时间目标"
            }
        }
        
        var headerText: String {
            switch self {
            case .focus: return "选择每日专注目标"
            case .usage: return "选择每日使用时间目标"
            }
        }
        
        var footerText: String {
            switch self {
            case .focus: return "建议根据个人情况设置合理的目标，循序渐进提高专注能力"
            case .usage: return "设置每日手机使用时间上限，帮助控制数字设备使用时间"
            }
        }
        
        var goalOptions: [Double] {
            switch self {
            case .focus: return [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 6.0, 8.0]
            case .usage: return [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 12.0, 14.0]
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(goalType.goalOptions, id: \.self) { goal in
                        HStack {
                            Text(formatGoalTime(goal))
                            
                            Spacer()
                            
                            if goal == selectedGoal {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedGoal = goal
                        }
                    }
                } header: {
                    Text(goalType.headerText)
                } footer: {
                    Text(goalType.footerText)
                }
            }
            .navigationTitle(goalType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatGoalTime(_ hours: Double) -> String {
        if hours == 1.0 {
            return "1小时"
        } else if hours.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(hours))小时"
        } else {
            let h = Int(hours)
            let m = Int((hours - Double(h)) * 60)
            return "\(h)小时\(m)分钟"
        }
    }
}

// MARK: - Enhanced Sleep Time Picker View
struct EnhancedSleepTimePickerView: View {
    @Binding var sleepStart: Date
    @Binding var sleepEnd: Date
    @Binding var flexibleSleepDays: Bool
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDayType: DayType = .weekday
    
    enum DayType: String, CaseIterable, Identifiable {
        case weekday = "工作日"
        case weekend = "周末"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("开始时间", selection: $sleepStart, displayedComponents: .hourAndMinute)
                    
                    DatePicker("结束时间", selection: $sleepEnd, displayedComponents: .hourAndMinute)
                } header: {
                    Text("睡眠时间设置")
                } footer: {
                    Text("在此时间段内的手机未使用不会被计算为专注时间。通常设置为晚上11点到早上7点。")
                }
                
                Section {
                    Toggle("周末灵活睡眠时间", isOn: $flexibleSleepDays)
                } footer: {
                    Text("启用后，周末（周六和周日）不会应用睡眠时间过滤，所有时间段都可能被记录为专注时间。")
                }
                
                if flexibleSleepDays {
                    Section {
                        Text("周末时间不会被过滤")
                            .foregroundColor(.secondary)
                            .italic()
                    } header: {
                        Text("周末设置")
                    } footer: {
                        Text("周末的所有时间段都可能被记录为专注时间，无论是否在睡眠时间范围内。")
                    }
                }
            }
            .navigationTitle("睡眠时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Lunch Time Picker View
struct EnhancedLunchTimePickerView: View {
    @Binding var lunchEnabled: Bool
    @Binding var lunchStart: Date
    @Binding var lunchEnd: Date
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var customLunchDuration: Int = 60 // minutes
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("启用午休时间", isOn: $lunchEnabled)
                } footer: {
                    Text("启用后，午休时间段内的手机未使用不会被计算为专注时间")
                }
                
                if lunchEnabled {
                    Section {
                        DatePicker("开始时间", selection: $lunchStart, displayedComponents: .hourAndMinute)
                        
                        DatePicker("结束时间", selection: $lunchEnd, displayedComponents: .hourAndMinute)
                    } header: {
                        Text("午休时间设置")
                    }
                    
                    Section {
                        Button("设置为12:00 - 13:00") {
                            setLunchTime(start: 12, end: 13)
                        }
                        
                        Button("设置为12:00 - 14:00") {
                            setLunchTime(start: 12, end: 14)
                        }
                        
                        Button("设置为13:00 - 14:00") {
                            setLunchTime(start: 13, end: 14)
                        }
                    } header: {
                        Text("快速设置")
                    }
                    
                    Section {
                        Picker("午休时长", selection: $customLunchDuration) {
                            Text("30分钟").tag(30)
                            Text("45分钟").tag(45)
                            Text("60分钟").tag(60)
                            Text("90分钟").tag(90)
                            Text("120分钟").tag(120)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Button("从当前时间开始午休") {
                            setCustomLunchTime()
                        }
                        .foregroundColor(.blue)
                    } header: {
                        Text("自定义午休")
                    } footer: {
                        Text("设置从当前时间开始的午休时段")
                    }
                }
            }
            .navigationTitle("午休时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func setLunchTime(start: Int, end: Int) {
        let calendar = Calendar.current
        lunchStart = calendar.date(from: DateComponents(hour: start, minute: 0)) ?? Date()
        lunchEnd = calendar.date(from: DateComponents(hour: end, minute: 0)) ?? Date()
    }
    
    private func setCustomLunchTime() {
        let now = Date()
        lunchStart = now
        lunchEnd = now.addingTimeInterval(Double(customLunchDuration) * 60)
    }
}

// MARK: - Time Zone Picker View
struct TimeZonePickerView: View {
    @Binding var useLocalTimeZone: Bool
    @Binding var timeZoneOffset: Double
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let timeZoneOffsets = UserSettings.commonTimeZoneOffsets
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("使用系统时区", isOn: $useLocalTimeZone)
                } footer: {
                    Text("启用后，将使用设备当前时区。禁用后，可以手动设置时区。")
                }
                
                if !useLocalTimeZone {
                    Section {
                        ForEach(timeZoneOffsets, id: \.offset) { timezone in
                            HStack {
                                Text(timezone.name)
                                
                                Spacer()
                                
                                if abs(timezone.offset - timeZoneOffset) < 0.01 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                timeZoneOffset = timezone.offset
                            }
                        }
                    } header: {
                        Text("选择时区")
                    } footer: {
                        Text("选择与您当前位置匹配的时区，以确保专注时间计算准确。")
                    }
                    
                    Section {
                        Text("当前系统时区: \(formatTimeZone(TimeZone.current))")
                            .foregroundColor(.secondary)
                        
                        Text("选择的时区: \(formatTimeZoneOffset(timeZoneOffset))")
                            .foregroundColor(.blue)
                    } header: {
                        Text("时区信息")
                    } footer: {
                        Text("跨时区旅行时，您可以临时调整时区设置，以确保专注时间计算准确。")
                    }
                }
            }
            .navigationTitle("时区设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTimeZone(_ timeZone: TimeZone) -> String {
        let offset = Double(timeZone.secondsFromGMT()) / 3600.0
        return formatTimeZoneOffset(offset)
    }
    
    private func formatTimeZoneOffset(_ offset: Double) -> String {
        let hours = Int(offset)
        let minutes = Int(abs(offset.truncatingRemainder(dividingBy: 1)) * 60)
        
        let sign = offset >= 0 ? "+" : "-"
        return String(format: "GMT%@%02d:%02d", sign, abs(hours), minutes)
    }
}