import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var userSettings: UserSettings?
    @State private var showingTagManagement = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("时间记录") {
                    HStack {
                        Text("自动记录")
                        Spacer()
                        Text("已开启")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("记录精度")
                        Spacer()
                        Text("5分钟")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("分类管理") {
                    Button("管理时间分类") {
                        showingTagManagement = true
                    }
                }
                
                Section("通知设置") {
                    HStack {
                        Text("记录提醒")
                        Spacer()
                        Text("已开启")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("洞察通知")
                        Spacer()
                        Text("已关闭")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("数据管理") {
                    Button("导出时间数据") {
                        // TODO: 实现数据导出
                    }
                    
                    Button("清除历史数据") {
                        // TODO: 实现数据清除
                    }
                    .foregroundColor(.red)
                }
                
                Section("隐私") {
                    HStack {
                        Text("数据本地存储")
                        Spacer()
                        Text("是")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("AI分析")
                        Spacer()
                        Text("可选")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("应用目标")
                        Spacer()
                        Text("了解时间使用")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingTagManagement) {
            TagManagementView()
        }
        .onAppear {
            loadUserSettings()
        }
    }
    
    private func loadUserSettings() {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let settings = try viewContext.fetch(request)
            if let userSettings = settings.first {
                self.userSettings = userSettings
            } else {
                // 创建默认设置
                let defaultSettings = UserSettings.createDefaultSettings(in: viewContext)
                try viewContext.save()
                self.userSettings = defaultSettings
            }
        } catch {
            print("Error loading user settings: \(error)")
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)小时 \(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}