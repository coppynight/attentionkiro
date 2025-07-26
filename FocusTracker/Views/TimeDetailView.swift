import SwiftUI
import CoreData

struct TimeDetailView: View {
    let timeRange: TimeRecordView.TimeRange
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var timeEntries: [TimeEntry] = []
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 日期选择器
                HStack {
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            
                            Text(formatDate(selectedDate))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("共 \(timeEntries.count) 条记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // 时间条目列表
                if timeEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("该日期暂无时间记录")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("时间记录会自动生成，请继续使用应用")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedEntries, id: \.key) { group in
                            Section(header: Text(group.key).font(.subheadline).foregroundColor(.secondary)) {
                                ForEach(group.value, id: \.id) { entry in
                                    TimeEntryRow(entry: entry)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("时间明细")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate) {
                loadTimeEntries()
            }
        }
        .onAppear {
            loadTimeEntries()
        }
        .onChange(of: selectedDate) { _ in
            loadTimeEntries()
        }
    }
    
    private var groupedEntries: [(key: String, value: [TimeEntry])] {
        let grouped = Dictionary(grouping: timeEntries) { entry in
            let hour = Calendar.current.component(.hour, from: entry.startTime)
            return "\(hour):00 - \(hour + 1):00"
        }
        
        return grouped.sorted { first, second in
            let firstHour = Int(first.key.prefix(2)) ?? 0
            let secondHour = Int(second.key.prefix(2)) ?? 0
            return firstHour < secondHour
        }
    }
    
    private func loadTimeEntries() {
        // 从Core Data加载实际的时间记录
        let request: NSFetchRequest<FocusSession> = FocusSession.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSession.startTime, ascending: true)]
        
        do {
            let sessions = try viewContext.fetch(request)
            timeEntries = sessions.compactMap { session in
                guard let endTime = session.endTime,
                      let category = session.category else { return nil }
                
                let startTime = session.startTime
                
                return TimeEntry(
                    id: session.id ?? UUID(),
                    startTime: startTime,
                    endTime: endTime,
                    category: category,
                    appName: session.activityName ?? "专注时间", // 使用活动名称而不是应用名称
                    duration: endTime.timeIntervalSince(startTime)
                )
            }
        } catch {
            print("Failed to fetch time entries: \(error)")
            timeEntries = []
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Time Entry Model
struct TimeEntry {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let category: String
    let appName: String
    let duration: TimeInterval
}

// MARK: - Time Entry Row
struct TimeEntryRow: View {
    let entry: TimeEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // 时间段
            VStack(alignment: .leading, spacing: 2) {
                Text(formatTime(entry.startTime))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(formatTime(entry.endTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .leading)
            
            // 分类颜色指示器
            Circle()
                .fill(categoryColor(entry.category))
                .frame(width: 8, height: 8)
            
            // 应用和分类信息
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.appName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(entry.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 时长
            Text(formatDuration(entry.duration))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(categoryColor(entry.category))
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "工作": return .blue
        case "学习": return .green
        case "娱乐": return .orange
        case "社交": return .pink
        case "健康": return .red
        default: return .gray
        }
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let onDateChanged: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "选择日期",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle("选择日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        onDateChanged()
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
}

struct TimeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TimeDetailView(timeRange: .today)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}