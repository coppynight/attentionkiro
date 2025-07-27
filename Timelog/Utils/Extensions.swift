import SwiftUI
import Foundation

// MARK: - Color Extensions

extension Color {
    /// GitHub风格的绿色系列
    static let githubGreen1 = Color(hex: "#ebedf0") // 最浅
    static let githubGreen2 = Color(hex: "#c6e48b") // 浅
    static let githubGreen3 = Color(hex: "#7bc96f") // 中
    static let githubGreen4 = Color(hex: "#239a3b") // 深
    static let githubGreen5 = Color(hex: "#196127") // 最深
    
    /// 美好时刻金色
    static let beautifulMomentGold = Color(hex: "#FFD700")
}

// MARK: - Date Extensions

extension Date {
    /// 格式化为时间字符串
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// 格式化为日期字符串
    func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
    
    /// 格式化为短日期字符串
    func shortDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: self)
    }
    
    /// 获取星期几
    func weekdayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    /// 获取短星期几
    func shortWeekdayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
    
    /// 是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// 是否是昨天
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// 是否是明天
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// 获取一天的开始时间
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// 获取一天的结束时间
    var endOfDay: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? self
    }
    
    /// 获取一周的开始时间
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// 获取一月的开始时间
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
}

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// 格式化为时长字符串
    func formattedDuration() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    /// 格式化为详细时长字符串
    func detailedFormattedDuration() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d小时%d分钟", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d分钟%d秒", minutes, seconds)
        } else {
            return String(format: "%d秒", seconds)
        }
    }
}

// MARK: - String Extensions

extension String {
    /// 截断字符串到指定长度
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count <= length {
            return self
        } else {
            return String(self.prefix(length)) + trailing
        }
    }
    
    /// 移除空白字符
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 是否为空或只包含空白字符
    var isBlankOrEmpty: Bool {
        return self.trimmed().isEmpty
    }
}

// MARK: - Array Extensions

extension Array {
    /// 安全获取数组元素
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - View Extensions

extension View {
    /// 条件性应用修饰符
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// 条件性应用修饰符（带else分支）
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    /// 隐藏视图
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
    
    /// 添加圆角边框
    func roundedBorder(
        radius: CGFloat = 8,
        color: Color = .gray,
        lineWidth: CGFloat = 1
    ) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(color, lineWidth: lineWidth)
            )
    }
    
    /// 添加阴影
    func cardShadow(
        color: Color = .black.opacity(0.1),
        radius: CGFloat = 2,
        x: CGFloat = 0,
        y: CGFloat = 1
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    /// 时间块持续时间设置
    var timeBlockDuration: TimeInterval {
        get { double(forKey: "TimeBlockDuration") == 0 ? 1200 : double(forKey: "TimeBlockDuration") }
        set { set(newValue, forKey: "TimeBlockDuration") }
    }
    
    /// 是否启用美好时刻功能
    var enableBeautifulMoments: Bool {
        get { object(forKey: "EnableBeautifulMoments") == nil ? true : bool(forKey: "EnableBeautifulMoments") }
        set { set(newValue, forKey: "EnableBeautifulMoments") }
    }
    
    /// 热力图颜色方案
    var heatmapColorScheme: String {
        get { string(forKey: "HeatmapColorScheme") ?? "github" }
        set { set(newValue, forKey: "HeatmapColorScheme") }
    }
    
    /// 是否显示欢迎界面
    var shouldShowWelcome: Bool {
        get { !bool(forKey: "HasCompletedWelcome") }
        set { set(!newValue, forKey: "HasCompletedWelcome") }
    }
}