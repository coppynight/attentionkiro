import SwiftUI
import CoreData

struct AppCategoryMappingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var timeRecordManager: TimeRecordManager
    
    @State private var appMappings: [AppMapping] = []
    @State private var searchText = ""
    @State private var showingAddApp = false
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._timeRecordManager = StateObject(wrappedValue: TimeRecordManager(viewContext: context))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                
                // 说明文字
                VStack(alignment: .leading, spacing: 8) {
                    Text("应用分类映射")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("设置不同应用对应的时间分类，系统会自动将时间记录归类到相应标签下")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // 应用映射列表
                List {
                    ForEach(filteredMappings, id: \.appName) { mapping in
                        AppMappingRow(
                            mapping: mapping,
                            onCategoryChanged: { newCategory in
                                updateMapping(mapping.appName, category: newCategory)
                            }
                        )
                    }
                    .onDelete(perform: deleteMapping)
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("应用分类设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddApp = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddApp) {
            AddAppMappingView { appName, category in
                addNewMapping(appName: appName, category: category)
            }
        }
        .onAppear {
            loadAppMappings()
        }
    }
    
    private var filteredMappings: [AppMapping] {
        if searchText.isEmpty {
            return appMappings
        } else {
            return appMappings.filter { mapping in
                mapping.appName.localizedCaseInsensitiveContains(searchText) ||
                mapping.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func loadAppMappings() {
        let mappings = timeRecordManager.getAllAppMappings()
        appMappings = mappings.map { AppMapping(appName: $0.key, category: $0.value) }
            .sorted { $0.appName < $1.appName }
    }
    
    private func updateMapping(_ appName: String, category: String) {
        timeRecordManager.updateAppCategory(appName, category: category)
        if let index = appMappings.firstIndex(where: { $0.appName == appName }) {
            appMappings[index].category = category
        }
    }
    
    private func addNewMapping(appName: String, category: String) {
        let newMapping = AppMapping(appName: appName, category: category)
        appMappings.append(newMapping)
        appMappings.sort { $0.appName < $1.appName }
        timeRecordManager.updateAppCategory(appName, category: category)
    }
    
    private func deleteMapping(at offsets: IndexSet) {
        for index in offsets {
            let mapping = filteredMappings[index]
            appMappings.removeAll { $0.appName == mapping.appName }
        }
    }
}

// MARK: - App Mapping Model
struct AppMapping {
    let appName: String
    var category: String
}

// MARK: - App Mapping Row
struct AppMappingRow: View {
    let mapping: AppMapping
    let onCategoryChanged: (String) -> Void
    
    @State private var selectedCategory: String
    
    private let categories = ["工作", "学习", "娱乐", "社交", "健康", "购物", "出行", "浏览", "其他"]
    
    init(mapping: AppMapping, onCategoryChanged: @escaping (String) -> Void) {
        self.mapping = mapping
        self.onCategoryChanged = onCategoryChanged
        self._selectedCategory = State(initialValue: mapping.category)
    }
    
    var body: some View {
        HStack {
            // 应用图标占位符
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(mapping.appName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            // 应用名称
            VStack(alignment: .leading, spacing: 2) {
                Text(mapping.appName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("应用")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 分类选择器
            Menu {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        onCategoryChanged(category)
                    }) {
                        HStack {
                            Text(category)
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(categoryColor(selectedCategory))
                        .frame(width: 12, height: 12)
                    
                    Text(selectedCategory)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "工作": return .blue
        case "学习": return .green
        case "娱乐": return .orange
        case "社交": return .pink
        case "健康": return .red
        case "购物": return .purple
        case "出行": return .cyan
        case "浏览": return .indigo
        default: return .gray
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索应用或分类", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
        .cornerRadius(10)
        .padding()
    }
}

// MARK: - Add App Mapping View
struct AddAppMappingView: View {
    let onAdd: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var appName = ""
    @State private var selectedCategory = "工作"
    
    private let categories = ["工作", "学习", "娱乐", "社交", "健康", "购物", "出行", "浏览", "其他"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("应用信息") {
                    TextField("应用名称", text: $appName)
                        .textInputAutocapitalization(.words)
                }
                
                Section("选择分类") {
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            HStack {
                                Circle()
                                    .fill(categoryColor(category))
                                    .frame(width: 12, height: 12)
                                
                                Text(category)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
            }
            .navigationTitle("添加应用映射")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        onAdd(appName, selectedCategory)
                        dismiss()
                    }
                    .disabled(appName.isEmpty)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "工作": return .blue
        case "学习": return .green
        case "娱乐": return .orange
        case "社交": return .pink
        case "健康": return .red
        case "购物": return .purple
        case "出行": return .cyan
        case "浏览": return .indigo
        default: return .gray
        }
    }
}

struct AppCategoryMappingView_Previews: PreviewProvider {
    static var previews: some View {
        AppCategoryMappingView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}