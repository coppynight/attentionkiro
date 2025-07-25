import SwiftUI
import CoreData
import Combine

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var focusManager: FocusManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @StateObject private var onboardingCoordinator = OnboardingCoordinator.shared
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Main app content
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("首页")
                    }
                    .tag(0)
                
                StatisticsView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("统计")
                    }
                    .tag(1)
                
                TagsView()
                    .tabItem {
                        Image(systemName: "tag.fill")
                        Text("标签")
                    }
                    .tag(2)
                
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("设置")
                    }
                    .tag(3)
                
                #if DEBUG
                TestView()
                    .tabItem {
                        Image(systemName: "hammer.fill")
                        Text("测试")
                    }
                    .tag(4)
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
                selectedTab = 3
            }
            
            // Onboarding overlay
            if onboardingCoordinator.shouldShowOnboarding {
                OnboardingView()
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(1000)
            }
        }
        .errorAlert() // Apply consistent error handling
        .animation(.easeInOut(duration: 0.5), value: onboardingCoordinator.shouldShowOnboarding)
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