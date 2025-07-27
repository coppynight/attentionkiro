import Foundation
import CoreData
import SwiftUI

/// 项目设置管理器 - 管理用户偏好和应用配置
class SettingsManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    @Published var userSettings: UserSettings
    @Published var isExporting = false
    @Published var exportError: Error?
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        self.userSettings = UserSettings.getOrCreate(in: viewContext)
    }
    
    // MARK: - Settings Management
    
    /// 保存设置更改
    func saveSettings() {
        do {
            try viewContext.save()
            print("Settings saved successfully")
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    /// 重置为默认设置
    func resetToDefaults() {
        userSettings.timeBlockGranularity = UserSettings.defaultTimeBlockGranularity
        userSettings.dailyGoalHours = UserSettings.defaultDailyGoalHours
        userSettings.workingHoursStart = UserSettings.defaultWorkingHoursStart
        userSettings.workingHoursEnd = UserSettings.defaultWorkingHoursEnd
        userSettings.heatmapColorScheme = UserSettings.defaultHeatmapColorScheme
        userSettings.enableBeautifulMoments = true
        userSettings.autoTaggingEnabled = false
        userSettings.weeklyReviewEnabled = true
        
        saveSettings()
    }
    
    // MARK: - Data Export
    
    /// 导出数据格式
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            }
        }
    }
    
    /// 导出日期范围
    enum DateRange: String, CaseIterable {
        case lastWeek = "最近一周"
        case lastMonth = "最近一个月"
        case lastThreeMonths = "最近三个月"
        case allTime = "全部时间"
        
        func getDateRange() -> (start: Date, end: Date) {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .lastWeek:
                let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
                return (start, now)
            case .lastMonth:
                let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                return (start, now)
            case .lastThreeMonths:
                let start = calendar.date(byAdding: .month, value: -3, to: now) ?? now
                return (start, now)
            case .allTime:
                let start = calendar.date(byAdding: .year, value: -10, to: now) ?? now
                return (start, now)
            }
        }
    }
    
    /// 导出人生数据
    func exportData(format: ExportFormat, dateRange: DateRange) async -> URL? {
        await MainActor.run {
            isExporting = true
            exportError = nil
        }
        
        defer {
            Task { @MainActor in
                isExporting = false
            }
        }
        
        do {
            let (startDate, endDate) = dateRange.getDateRange()
            let timeBlocks = try fetchTimeBlocks(from: startDate, to: endDate)
            
            switch format {
            case .csv:
                return try exportToCSV(timeBlocks: timeBlocks, dateRange: dateRange)
            case .json:
                return try exportToJSON(timeBlocks: timeBlocks, dateRange: dateRange)
            }
        } catch {
            await MainActor.run {
                exportError = error
            }
            return nil
        }
    }
    
    // MARK: - Data Management
    
    /// 清除所有人生数据
    func clearAllData() throws {
        // 清除时间块数据
        let timeBlockRequest: NSFetchRequest<NSFetchRequestResult> = TimeBlock.fetchRequest()
        let timeBlockDeleteRequest = NSBatchDeleteRequest(fetchRequest: timeBlockRequest)
        
        // 清除时间提交数据
        let timeCommitRequest: NSFetchRequest<NSFetchRequestResult> = TimeCommit.fetchRequest()
        let timeCommitDeleteRequest = NSBatchDeleteRequest(fetchRequest: timeCommitRequest)
        
        // 清除时间标签数据
        let timeTagRequest: NSFetchRequest<NSFetchRequestResult> = TimeTag.fetchRequest()
        let timeTagDeleteRequest = NSBatchDeleteRequest(fetchRequest: timeTagRequest)
        
        try viewContext.execute(timeBlockDeleteRequest)
        try viewContext.execute(timeCommitDeleteRequest)
        try viewContext.execute(timeTagDeleteRequest)
        try viewContext.save()
        
        print("All life project data cleared successfully")
    }
    
    // MARK: - Private Methods
    
    private func fetchTimeBlocks(from startDate: Date, to endDate: Date) throws -> [TimeBlock] {
        let request: NSFetchRequest<TimeBlock> = TimeBlock.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeBlock.startTime, ascending: true)]
        
        return try viewContext.fetch(request)
    }
    
    private func exportToCSV(timeBlocks: [TimeBlock], dateRange: DateRange) throws -> URL {
        var csvContent = "开始时间,结束时间,时长(分钟),活动,分类,备注,是否标记\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for block in timeBlocks {
            let startTime = dateFormatter.string(from: block.startTime ?? Date())
            let endTime = dateFormatter.string(from: block.endTime ?? Date())
            let duration = Int(block.duration / 60)
            let activity = block.taggedActivity?.replacingOccurrences(of: ",", with: ";") ?? ""
            let category = block.category?.replacingOccurrences(of: ",", with: ";") ?? ""
            let notes = block.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            let isTagged = block.isTagged ? "是" : "否"
            
            csvContent += "\(startTime),\(endTime),\(duration),\(activity),\(category),\(notes),\(isTagged)\n"
        }
        
        let fileName = "Timelog_Export_\(dateRange.rawValue)_\(Date().timeIntervalSince1970).csv"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        try csvContent.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    private func exportToJSON(timeBlocks: [TimeBlock], dateRange: DateRange) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        let exportData: [String: Any] = [
            "exportDate": dateFormatter.string(from: Date()),
            "dateRange": dateRange.rawValue,
            "totalBlocks": timeBlocks.count,
            "timeBlocks": timeBlocks.map { block in
                [
                    "id": block.id?.uuidString ?? "",
                    "startTime": dateFormatter.string(from: block.startTime ?? Date()),
                    "endTime": dateFormatter.string(from: block.endTime ?? Date()),
                    "duration": block.duration,
                    "activity": block.taggedActivity ?? "",
                    "category": block.category ?? "",
                    "notes": block.notes ?? "",
                    "isTagged": block.isTagged
                ]
            }
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        
        let fileName = "Timelog_Export_\(dateRange.rawValue)_\(Date().timeIntervalSince1970).json"
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        try jsonData.write(to: url)
        return url
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - Settings Errors

enum SettingsError: LocalizedError {
    case exportFailed(String)
    case dataCorruption
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .exportFailed(let reason):
            return "导出失败: \(reason)"
        case .dataCorruption:
            return "数据损坏，无法导出"
        case .permissionDenied:
            return "没有文件访问权限"
        }
    }
}