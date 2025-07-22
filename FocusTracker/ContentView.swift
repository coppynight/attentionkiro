import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FocusSession.startTime, ascending: false)],
        animation: .default)
    private var focusSessions: FetchedResults<FocusSession>

    var body: some View {
        NavigationView {
            VStack {
                Text("专注追踪")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("今日专注时间")
                    .font(.headline)
                    .padding(.top)
                
                Text(formatTotalFocusTime())
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                    .padding()
                
                Spacer()
                
                Text("应用正在初始化...")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .navigationTitle("专注追踪")
        }
    }
    
    private func formatTotalFocusTime() -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todaySessions = focusSessions.filter { session in
            session.startTime >= today && session.startTime < tomorrow && session.isValid
        }
        
        let totalSeconds = todaySessions.reduce(0) { $0 + $1.duration }
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}