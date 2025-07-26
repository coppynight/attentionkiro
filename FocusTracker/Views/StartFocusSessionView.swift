import SwiftUI
import CoreData

struct StartFocusSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var activityName = ""
    @State private var selectedCategory = "工作"
    @State private var targetDuration: TimeInterval = 25 * 60 // 默认25分钟
    @State private var notes = ""
    @State private var showingActivitySuggestions = false
    
    let categories = ["工作", "学习", "娱乐", "健康", "社交", "其他"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("专注活动")
                        .font(.headline)
                    
                    TextField("输入活动名称", text: $activityName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("分类")
                        .font(.headline)
                    
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("开始专注")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("开始") {
                        startFocusSession()
                    }
                    .disabled(activityName.isEmpty)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    private func startFocusSession() {
        let session = FocusSession(context: viewContext)
        session.id = UUID()
        session.startTime = Date()
        session.activityName = activityName
        session.category = selectedCategory
        session.targetDuration = targetDuration
        session.notes = notes.isEmpty ? nil : notes
        session.isActive = true
        session.isCompleted = false
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to start focus session: \(error)")
        }
    }
}

struct StartFocusSessionView_Previews: PreviewProvider {
    static var previews: some View {
        StartFocusSessionView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}