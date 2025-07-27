import SwiftUI
import CoreData

/// TimeView - 时间管理综合界面
/// 集成热力图和标签功能的统一界面（已移至ContentView中的TimeManagementView）
/// 此文件保留用于未来的模块化重构

// 注意：当前的TimeView功能已经集成到ContentView中的TimeManagementView
// 这样可以更好地与主应用导航集成，提供统一的用户体验

struct TimeView: View {
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State Variables
    
    @State private var selectedSegment = 0
    @State private var selectedDate = Date()
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 分段控制器
                Picker("视图模式", selection: $selectedSegment) {
                    Text("记录图").tag(0)
                    Text("标签").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // 内容区域
                if selectedSegment == 0 {
                    HeatmapView(viewContext: viewContext)
                } else {
                    TimeTaggingView(viewContext: viewContext)
                }
                
                Spacer()
            }
            .navigationTitle("时间管理")
        }
    }
}

// MARK: - Preview

#Preview {
    TimeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}