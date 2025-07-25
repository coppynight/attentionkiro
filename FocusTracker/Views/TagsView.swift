import SwiftUI
import CoreData

struct TagsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var tagManager: TagManager
    @State private var showingCreateTag = false
    @State private var selectedTag: SceneTag?
    @State private var showingEditTag = false
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._tagManager = StateObject(wrappedValue: TagManager(viewContext: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Tag overview section
                    TagOverviewSection()
                    
                    // Default tags section
                    DefaultTagsSection()
                    
                    // Custom tags section
                    CustomTagsSection()
                    
                    // Tag statistics section
                    TagStatisticsSection()
                }
                .padding()
            }
            .navigationTitle("标签管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateTag = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTag) {
                CreateTagView(tagManager: tagManager)
            }
            .sheet(item: $selectedTag) { tag in
                EditTagView(tag: tag, tagManager: tagManager)
            }
        }
        .onAppear {
            // Refresh tag data when view appears
        }
    }
    
    // MARK: - Tag Overview Section
    @ViewBuilder
    private func TagOverviewSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("标签概览")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack(spacing: 20) {
                // Total tags
                VStack(spacing: 4) {
                    Text("\(tagManager.availableTags.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("总标签数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Default tags
                VStack(spacing: 4) {
                    Text("\(tagManager.defaultTags.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("默认标签")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Custom tags
                VStack(spacing: 4) {
                    Text("\(tagManager.customTags.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("自定义标签")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Default Tags Section
    @ViewBuilder
    private func DefaultTagsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("默认标签")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(tagManager.defaultTags.count) 个")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(tagManager.defaultTags, id: \.tagID) { tag in
                    DefaultTagCard(tag: tag)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Custom Tags Section
    @ViewBuilder
    private func CustomTagsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("自定义标签")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(tagManager.customTags.count) 个")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if tagManager.customTags.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("暂无自定义标签")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("点击右上角的 + 按钮创建自定义标签")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(tagManager.customTags, id: \.tagID) { tag in
                        CustomTagCard(tag: tag) {
                            selectedTag = tag
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Tag Statistics Section
    @ViewBuilder
    private func TagStatisticsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("使用统计")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("今日")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            let todayDistribution = tagManager.getTagDistribution(for: Date())
            
            if todayDistribution.isEmpty {
                Text("今日暂无标签使用数据")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(todayDistribution.prefix(5), id: \.tagName) { distribution in
                        TagUsageRowView(distribution: distribution)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Default Tag Card
struct DefaultTagCard: View {
    let tag: SceneTag
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: tag.color) ?? .blue)
                .frame(width: 12, height: 12)
            
            Text(tag.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(tag.usageCount)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Custom Tag Card
struct CustomTagCard: View {
    let tag: SceneTag
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: tag.color) ?? .blue)
                .frame(width: 12, height: 12)
            
            Text(tag.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Tag Usage Row View
struct TagUsageRowView: View {
    let distribution: TagDistribution
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: distribution.color) ?? .blue)
                    .frame(width: 10, height: 10)
                
                Text(distribution.tagName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(distribution.usageTime))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(Int(distribution.percentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Create Tag View
struct CreateTagView: View {
    @Environment(\.presentationMode) var presentationMode
    let tagManager: TagManager
    
    @State private var tagName = ""
    @State private var selectedColor = "#007AFF"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let availableColors = [
        "#007AFF", "#34C759", "#FF9500", "#FF2D92",
        "#AF52DE", "#FF3B30", "#FFCC00", "#5AC8FA",
        "#FF6B35", "#32D74B", "#BF5AF2", "#FF453A"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("标签信息")) {
                    TextField("标签名称", text: $tagName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("选择颜色")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(Color(hex: color) ?? .blue)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button(action: createTag) {
                        Text("创建标签")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                    .disabled(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("创建标签")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
            }
        }
    }
    
    private func createTag() {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "请输入标签名称"
            showingAlert = true
            return
        }
        
        if let _ = tagManager.createCustomTag(name: trimmedName, color: selectedColor) {
            presentationMode.wrappedValue.dismiss()
        } else {
            alertMessage = "创建标签失败，可能是名称已存在"
            showingAlert = true
        }
    }
}

// MARK: - Edit Tag View
struct EditTagView: View {
    @Environment(\.presentationMode) var presentationMode
    let tag: SceneTag
    let tagManager: TagManager
    
    @State private var tagName: String
    @State private var selectedColor: String
    @State private var showingDeleteAlert = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(tag: SceneTag, tagManager: TagManager) {
        self.tag = tag
        self.tagManager = tagManager
        self._tagName = State(initialValue: tag.name)
        self._selectedColor = State(initialValue: tag.color)
    }
    
    private let availableColors = [
        "#007AFF", "#34C759", "#FF9500", "#FF2D92",
        "#AF52DE", "#FF3B30", "#FFCC00", "#5AC8FA",
        "#FF6B35", "#32D74B", "#BF5AF2", "#FF453A"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("标签信息")) {
                    TextField("标签名称", text: $tagName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(tag.isDefault) // Don't allow editing default tag names
                }
                
                Section(header: Text("选择颜色")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(Color(hex: color) ?? .blue)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button(action: saveChanges) {
                        Text("保存更改")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                    
                    if !tag.isDefault {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Text("删除标签")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.red)
                    }
                }
            }
            .navigationTitle("编辑标签")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("删除标签"),
                    message: Text("确定要删除这个标签吗？此操作无法撤销。"),
                    primaryButton: .destructive(Text("删除")) {
                        deleteTag()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func saveChanges() {
        // Update tag properties
        if !tag.isDefault {
            tag.name = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        tag.color = selectedColor
        
        do {
            try tag.managedObjectContext?.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "保存失败: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteTag() {
        if tagManager.deleteTag(tag) {
            presentationMode.wrappedValue.dismiss()
        } else {
            alertMessage = "删除失败，无法删除默认标签"
            showingAlert = true
        }
    }
}



struct TagsView_Previews: PreviewProvider {
    static var previews: some View {
        TagsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}