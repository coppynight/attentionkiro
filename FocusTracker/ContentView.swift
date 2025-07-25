import SwiftUI
import CoreData
import Combine

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var focusManager: FocusManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("时间")
                }
                .tag(0)
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("分析")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(2)
            
            #if DEBUG
            TestView()
                .tabItem {
                    Image(systemName: "hammer.fill")
                    Text("测试")
                }
                .tag(3)
            #endif
        }
        .accentColor(.blue)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            selectedTab = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToStatistics)) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToSettings)) { _ in
            selectedTab = 2
        }
        .errorAlert() // Apply consistent error handling
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(FocusManager(
                usageMonitor: UsageMonitor(),
                viewContext: PersistenceController.preview.container.viewContext
            ))
            .environmentObject(NotificationManager.shared)
    }
}