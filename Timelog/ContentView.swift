import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            TimeView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("时间")
                }
            
            InsightsView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("洞察")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
        }
        .accentColor(.green) // GitHub-style green accent
    }
}

// Combined Time view with heatmap and tagging functionality
struct TimeView: View {
    @State private var selectedDate = Date()
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented control to switch between heatmap and tagging
                Picker("View Mode", selection: $selectedSegment) {
                    Text("记录图").tag(0)
                    Text("标签").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected segment
                if selectedSegment == 0 {
                    HeatmapContentView(selectedDate: $selectedDate)
                } else {
                    TaggingContentView(selectedDate: $selectedDate)
                }
                
                Spacer()
            }
            .navigationTitle("时间")
        }
    }
}

struct HeatmapContentView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date picker
                DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.horizontal)
                
                // Heatmap visualization
                VStack(alignment: .leading, spacing: 16) {
                    Text("🔥 时间记录图")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Text("GitHub风格的时间热力图")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    // Placeholder for actual heatmap
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green.opacity(0.6))
                                Text("热力图将在这里显示")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                        .padding(.horizontal)
                }
            }
        }
    }
}

struct TaggingContentView: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date picker
                DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(.horizontal)
                
                // Tagging interface
                VStack(alignment: .leading, spacing: 16) {
                    Text("🏷️ 时间标签系统")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Text("为时间块添加有意义的标签")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    // Placeholder for time blocks list
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                        .overlay(
                            VStack {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green.opacity(0.6))
                                Text("时间块列表将在这里显示")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                        .padding(.horizontal)
                }
            }
        }
    }
}

struct InsightsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("🧠 智能洞察")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("AI分析时间使用模式")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("洞察")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("⚙️ 项目设置")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("配置时间追踪参数")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}