import SwiftUI
import CoreData

/// 项目设置主界面 - Git风格的配置管理
struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var settingsManager: SettingsManager?
    
    @State private var showingDataExport = false
    @State private var showingClearDataAlert = false
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            Group {
                if let manager = settingsManager {
                    List {
                        // 项目信息部分
                        Section {
                            ProjectInfoView()
                        } header: {
                            Label("项目信息", systemImage: "folder.fill")
                                .foregroundColor(.green)
                        }
                        
                        // 时间追踪设置
                        Section {
                            TimeTrackingSettingsView(settingsManager: manager)
                        } header: {
                            Label("时间追踪配置", systemImage: "clock.fill")
                                .foregroundColor(.blue)
                        }
                        
                        // 显示选项
                        Section {
                            DisplaySettingsView(settingsManager: manager)
                        } header: {
                            Label("显示选项", systemImage: "eye.fill")
                                .foregroundColor(.purple)
                        }
                        
                        // 数据管理
                        Section {
                            DataManagementView(
                                showingDataExport: $showingDataExport,
                                showingClearDataAlert: $showingClearDataAlert,
                                settingsManager: manager
                            )
                        } header: {
                            Label("数据管理", systemImage: "externaldrive.fill")
                                .foregroundColor(.orange)
                        }
                        
                        // 高级设置
                        Section {
                            AdvancedSettingsView(
                                showingResetAlert: $showingResetAlert,
                                settingsManager: manager
                            )
                        } header: {
                            Label("高级设置", systemImage: "gearshape.2.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .sheet(isPresented: $showingDataExport) {
                        DataExportSheet(settingsManager: manager)
                    }
                    .alert("清除所有数据", isPresented: $showingClearDataAlert) {
                        Button("取消", role: .cancel) { }
                        Button("确认清除", role: .destructive) {
                            clearAllData()
                        }
                    } message: {
                        Text("此操作将永久删除所有时间记录数据，无法恢复。确定要继续吗？")
                    }
                    .alert("重置设置", isPresented: $showingResetAlert) {
                        Button("取消", role: .cancel) { }
                        Button("重置", role: .destructive) {
                            manager.resetToDefaults()
                        }
                    } message: {
                        Text("将所有设置重置为默认值，确定要继续吗？")
                    }
                } else {
                    ProgressView("加载设置...")
                }
            }
            .navigationTitle("项目设置")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if settingsManager == nil {
                    settingsManager = SettingsManager(viewContext: viewContext)
                }
            }
        }
    }
    
    private func clearAllData() {
        guard let manager = settingsManager else { return }
        do {
            try manager.clearAllData()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}

// MARK: - Project Info View

struct ProjectInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Timelog")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("人生项目管理系统")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("v1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
            }
            
            Text("人生就是一个项目，你花费的时间就是在向人生的git提交记录")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Time Tracking Settings

struct TimeTrackingSettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    
    private let granularityOptions: [TimeInterval] = [
        5 * 60,   // 5分钟
        10 * 60,  // 10分钟
        15 * 60,  // 15分钟
        20 * 60,  // 20分钟
        30 * 60,  // 30分钟
        60 * 60   // 60分钟
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // 时间块粒度设置
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("时间块粒度")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("设置时间记录的最小单位")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Picker("时间块粒度", selection: $settingsManager.userSettings.timeBlockGranularity) {
                    ForEach(granularityOptions, id: \.self) { interval in
                        Text("\(Int(interval / 60)) 分钟")
                            .tag(interval)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: settingsManager.userSettings.timeBlockGranularity) { _ in
                    settingsManager.saveSettings()
                }
            }
            
            Divider()
            
            // 每日目标时间
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("每日目标时间")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("设置每日专注时间目标")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack {
                    Text(String(format: "%.1f", settingsManager.userSettings.dailyGoalHours))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("小时")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Slider(
                value: $settingsManager.userSettings.dailyGoalHours,
                in: 1...12,
                step: 0.5
            ) {
                Text("每日目标")
            }
            .accentColor(.green)
            .onChange(of: settingsManager.userSettings.dailyGoalHours) { _ in
                settingsManager.saveSettings()
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Display Settings

struct DisplaySettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 16) {
            // 美好时刻功能
            Toggle(isOn: $settingsManager.userSettings.enableBeautifulMoments) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("美好时刻标记")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("启用特殊时刻的标记功能")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .green))
            .onChange(of: settingsManager.userSettings.enableBeautifulMoments) { _ in
                settingsManager.saveSettings()
            }
            
            Divider()
            
            // 自动标记功能
            Toggle(isOn: $settingsManager.userSettings.autoTaggingEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("智能自动标记")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("基于使用模式自动添加标签")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            .onChange(of: settingsManager.userSettings.autoTaggingEnabled) { _ in
                settingsManager.saveSettings()
            }
            
            Divider()
            
            // 周报功能
            Toggle(isOn: $settingsManager.userSettings.weeklyReviewEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("周度回顾报告")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("每周生成时间使用分析报告")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .purple))
            .onChange(of: settingsManager.userSettings.weeklyReviewEnabled) { _ in
                settingsManager.saveSettings()
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Data Management

struct DataManagementView: View {
    @Binding var showingDataExport: Bool
    @Binding var showingClearDataAlert: Bool
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 12) {
            // 数据导出
            Button(action: {
                showingDataExport = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("导出人生数据")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("备份时间记录到文件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
            
            // 清除数据
            Button(action: {
                showingClearDataAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("清除所有数据")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        Text("永久删除所有时间记录")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Advanced Settings

struct AdvancedSettingsView: View {
    @Binding var showingResetAlert: Bool
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 12) {
            // 重置设置
            Button(action: {
                showingResetAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("重置为默认设置")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("恢复所有设置的默认值")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
            
            // 关于信息
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("关于 Timelog")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("版本 1.0.0 • 构建 2025.01.27")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}