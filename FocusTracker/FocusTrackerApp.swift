import SwiftUI
import CoreData
import BackgroundTasks

@main
struct FocusTrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var focusManager = FocusManager(
        usageMonitor: UsageMonitor(),
        viewContext: PersistenceController.shared.container.viewContext
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(focusManager)
                .onAppear {
                    setupBackgroundTasks()
                    focusManager.startMonitoring()
                }
        }
    }
    
    private func setupBackgroundTasks() {
        // Background tasks are now handled by BGTaskScheduler in UsageMonitor
        // No additional setup needed here
        
        print("FocusTrackerApp: Background tasks setup completed")
    }
}