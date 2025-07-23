import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var focusManager: FocusManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("统计")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
        }
        .accentColor(.blue)
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
    }
}