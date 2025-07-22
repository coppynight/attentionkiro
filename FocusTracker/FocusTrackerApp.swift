import SwiftUI
import CoreData

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
                    focusManager.startMonitoring()
                }
        }
    }
}

// MARK: - Core Data Stack
struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews
        let sampleSession = FocusSession(context: viewContext)
        sampleSession.startTime = Date().addingTimeInterval(-3600) // 1 hour ago
        sampleSession.endTime = Date()
        sampleSession.duration = 3600 // 1 hour
        sampleSession.isValid = true
        sampleSession.sessionType = "focus"
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FocusDataModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}