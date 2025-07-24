import SwiftUI
import CoreData
import BackgroundTasks
import UserNotifications

@main
struct FocusTrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var focusManager: FocusManager
    @StateObject private var tagManager: TagManager
    @StateObject private var notificationManager = NotificationManager.shared
    
    init() {
        // Setup background tasks BEFORE app finishes launching
        UsageMonitor.registerBackgroundTasks()
        
        let viewContext = PersistenceController.shared.container.viewContext
        
        // Initialize tag manager
        _tagManager = StateObject(wrappedValue: TagManager(viewContext: viewContext))
        
        // Initialize focus manager after background tasks are set up
        let usageMonitor = UsageMonitor()
        _focusManager = StateObject(wrappedValue: FocusManager(
            usageMonitor: usageMonitor,
            viewContext: viewContext
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(focusManager)
                .environmentObject(tagManager)
                .environmentObject(notificationManager)
                .onAppear {
                    setupNotifications()
                    focusManager.startMonitoring()
                }
        }
    }
    

    
    private func setupNotifications() {
        Task {
            notificationManager.setupNotificationDelegate()
            notificationManager.setupNotificationCategories()
            await notificationManager.checkAuthorizationStatus()
            
            // Request notification permission on first launch if not determined
            if notificationManager.authorizationStatus == .notDetermined {
                _ = await notificationManager.requestNotificationPermission()
            }
            
            print("FocusTrackerApp: Notifications setup completed")
        }
    }
}