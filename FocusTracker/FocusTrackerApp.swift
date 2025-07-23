import SwiftUI
import CoreData
import BackgroundTasks
import UserNotifications

@main
struct FocusTrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var focusManager = FocusManager(
        usageMonitor: UsageMonitor(),
        viewContext: PersistenceController.shared.container.viewContext
    )
    // @StateObject private var notificationManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(focusManager)
                // .environmentObject(notificationManager)
                .onAppear {
                    setupBackgroundTasks()
                    setupNotifications()
                    focusManager.startMonitoring()
                }
        }
    }
    
    private func setupBackgroundTasks() {
        // Background tasks are now handled by BGTaskScheduler in UsageMonitor
        // No additional setup needed here
        
        print("FocusTrackerApp: Background tasks setup completed")
    }
    
    private func setupNotifications() {
        // Notification setup temporarily disabled
        print("FocusTrackerApp: Notifications setup temporarily disabled")
    }
}