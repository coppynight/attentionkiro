import SwiftUI

/// NewTagSheet - 新建标签弹窗
struct NewTagSheet: View {
    
    // MARK: - Properties
    
    let tagManager: TimeTagManager
    let onDismiss: () -> Void
    
    // MARK: - State Variables
    
    @State private var tagName = ""
    @State private var selectedCategory = "自定义"
    @State private var selectedColor = "#007AFF"
    @State private var selectedIcon = "tag.fill"
    @State private var tagDescription = ""
    @State private var isCreating = false
    @State private var validationResult: TagValidationResult = .valid
    
    // MARK: - Constants
    
    private let categories = ["工作", "学习", "生活", "创作", "特殊", "自定义"]
    private let colors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#00C7BE", "#32D74B", "#007AFF", "#5856D6", "#AF52DE",
        "#FF2D92", "#A2845E", "#8E8E93", "#000000"
    ]
    private let icons = [
        "tag.fill", "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "lightbulb.fill", "brain.head.profile", "graduationcap.fill", "book.fill",
        "pencil.and.outline", "paintbrush.fill", "music.note", "gamecontroller.fill",
        "dumbbell.fill", "leaf.fill", "sparkles", "crown.fill", "diamond.fill"
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // 基本信息
                Section("基本信息") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("标签名称", text: $tagName)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: tagName) { _ in
                                validateTagName()
                            }
                        
                        if let errorMessage = validationResult.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Picker("类别", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    TextField("描述（可选）", text: $tagDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)
                }
                
                // 外观设置
                Section("外观设置") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("颜色")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(colors, id: \.self) { color in
                                Button(action: {
                                    selectedColor = color
                                }) {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("图标")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .secondary)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.1) : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                
                // 预览
                Section("预览") {
                    HStack(spacing: 12) {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundColor(Color(hex: selectedColor))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tagName.isEmpty ? "标签名称" : tagName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(selectedCategory)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .navigationTitle("新建标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        createTag()
                    }
                    .disabled(validationResult != .valid || isCreating)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateTagName() {
        validationResult = tagManager.validateTagName(tagName)
    }
    
    private func createTag() {
        isCreating = true
        
        Task {
            let success = await tagManager.createTag(
                name: tagName,
                category: selectedCategory,
                color: selectedColor,
                icon: selectedIcon,
                description: tagDescription
            )
            
            await MainActor.run {
                isCreating = false
                if success != nil {
                    onDismiss()
                }
            }
        }
    }
}

/// EditTagSheet - 编辑标签弹窗
struct EditTagSheet: View {
    
    // MARK: - Properties
    
    let tag: TimeTag
    let tagManager: TimeTagManager
    let onDismiss: () -> Void
    
    // MARK: - State Variables
    
    @State private var tagName: String
    @State private var selectedCategory: String
    @State private var selectedColor: String
    @State private var selectedIcon: String
    @State private var tagDescription: String
    @State private var isUpdating = false
    @State private var validationResult: TagValidationResult = .valid
    
    // MARK: - Constants
    
    private let categories = ["工作", "学习", "生活", "创作", "特殊", "自定义"]
    private let colors = [
        "#007AFF", "#FF3B30", "#FF9500", "#FFCC00", "#34C759",
        "#00C7BE", "#32D74B", "#007AFF", "#5856D6", "#AF52DE",
        "#FF2D92", "#A2845E", "#8E8E93", "#000000"
    ]
    private let icons = [
        "tag.fill", "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "lightbulb.fill", "brain.head.profile", "graduationcap.fill", "book.fill",
        "pencil.and.outline", "paintbrush.fill", "music.note", "gamecontroller.fill",
        "dumbbell.fill", "leaf.fill", "sparkles", "crown.fill", "diamond.fill"
    ]
    
    // MARK: - Initialization
    
    init(tag: TimeTag, tagManager: TimeTagManager, onDismiss: @escaping () -> Void) {
        self.tag = tag
        self.tagManager = tagManager
        self.onDismiss = onDismiss
        
        self._tagName = State(initialValue: tag.name ?? "")
        self._selectedCategory = State(initialValue: tag.category ?? "自定义")
        self._selectedColor = State(initialValue: tag.color ?? "#007AFF")
        self._selectedIcon = State(initialValue: tag.icon ?? "tag.fill")
        self._tagDescription = State(initialValue: tag.tagDescription ?? "")
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // 基本信息
                Section("基本信息") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("标签名称", text: $tagName)
                            .textFieldStyle(.roundedBorder)
                            .disabled(tag.isDefault)
                            .onChange(of: tagName) { _ in
                                validateTagName()
                            }
                        
                        if let errorMessage = validationResult.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if tag.isDefault {
                            Text("默认标签的名称不能修改")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Picker("类别", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .disabled(tag.isDefault)
                    
                    TextField("描述（可选）", text: $tagDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)
                }
                
                // 外观设置
                Section("外观设置") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("颜色")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(colors, id: \.self) { color in
                                Button(action: {
                                    selectedColor = color
                                }) {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("图标")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: {
                                    selectedIcon = icon
                                }) {
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .secondary)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.1) : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                
                // 使用统计
                Section("使用统计") {
                    HStack {
                        Text("使用次数")
                        Spacer()
                        Text("\(tag.usageCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastUsed = tag.lastUsedAt {
                        HStack {
                            Text("最后使用")
                            Spacer()
                            Text(lastUsed, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 预览
                Section("预览") {
                    HStack(spacing: 12) {
                        Image(systemName: selectedIcon)
                            .font(.title2)
                            .foregroundColor(Color(hex: selectedColor))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tagName.isEmpty ? "标签名称" : tagName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(selectedCategory)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .navigationTitle("编辑标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        updateTag()
                    }
                    .disabled(validationResult != .valid || isUpdating)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateTagName() {
        validationResult = tagManager.validateTagName(tagName, excludingTag: tag)
    }
    
    private func updateTag() {
        isUpdating = true
        
        Task {
            let success = await tagManager.updateTag(
                tag,
                name: tag.isDefault ? nil : tagName,
                category: tag.isDefault ? nil : selectedCategory,
                color: selectedColor,
                icon: selectedIcon,
                description: tagDescription
            )
            
            await MainActor.run {
                isUpdating = false
                if success {
                    onDismiss()
                }
            }
        }
    }
}

/// TagManagerSheet - 标签管理弹窗
struct TagManagerSheet: View {
    
    // MARK: - Properties
    
    let tagManager: TimeTagManager
    let onDismiss: () -> Void
    
    // MARK: - State Variables
    
    @State private var searchText = ""
    @State private var selectedCategory = "全部"
    @State private var sortOption: TagSortOption = .usage
    @State private var showingNewTagSheet = false
    @State private var editingTag: TimeTag?
    @State private var tagToDelete: TimeTag?
    @State private var showingDeleteAlert = false
    
    // MARK: - Computed Properties
    
    private var filteredAndSortedTags: [TimeTag] {
        var tags = tagManager.allTags
        
        // 搜索过滤
        if !searchText.isEmpty {
            tags = tagManager.searchTags(query: searchText)
        }
        
        // 类别过滤
        if selectedCategory != "全部" {
            tags = tags.filter { $0.category == selectedCategory }
        }
        
        // 排序
        switch sortOption {
        case .usage:
            tags = tags.sorted { $0.usageCount > $1.usageCount }
        case .name:
            tags = tags.sorted { ($0.name ?? "") < ($1.name ?? "") }
        case .category:
            tags = tags.sorted { ($0.category ?? "") < ($1.category ?? "") }
        case .recent:
            tags = tags.sorted { ($0.lastUsedAt ?? Date.distantPast) > ($1.lastUsedAt ?? Date.distantPast) }
        }
        
        return tags
    }
    
    private var categories: [String] {
        ["全部"] + tagManager.getAllCategories()
    }
    
    private var stats: TagUsageStats {
        tagManager.getTagUsageStats()
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计信息
                statsSection
                
                // 搜索和筛选
                searchAndFilterSection
                
                // 标签列表
                List {
                    ForEach(filteredAndSortedTags, id: \.id) { tag in
                        TagManagerRow(
                            tag: tag,
                            onEdit: {
                                editingTag = tag
                            },
                            onDelete: {
                                tagToDelete = tag
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("标签管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新建") {
                        showingNewTagSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewTagSheet) {
            NewTagSheet(tagManager: tagManager) {
                showingNewTagSheet = false
            }
        }
        .sheet(item: $editingTag) { tag in
            EditTagSheet(tag: tag, tagManager: tagManager) {
                editingTag = nil
            }
        }
        .alert("删除标签", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let tag = tagToDelete {
                    Task {
                        await tagManager.deleteTag(tag)
                    }
                }
            }
        } message: {
            Text("确定要删除标签 \"\(tagToDelete?.name ?? "")\" 吗？此操作无法撤销。")
        }
    }
    
    // MARK: - View Components
    
    /// 统计信息区域
    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack {
                StatItem(title: "总标签", value: "\(stats.totalTags)", color: .blue)
                StatItem(title: "默认标签", value: "\(stats.defaultTags)", color: .green)
                StatItem(title: "自定义标签", value: "\(stats.customTags)", color: .orange)
                StatItem(title: "总使用", value: "\(stats.totalUsage)", color: .purple)
            }
            
            HStack {
                Text("最常用: \(stats.mostUsedTagName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("平均使用: \(stats.formattedAverageUsage) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    /// 搜索和筛选区域
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索标签", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button("清除") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
            .cornerRadius(8)
            
            // 筛选选项
            HStack {
                // 类别筛选
                Picker("类别", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.menu)
                
                Spacer()
                
                // 排序选项
                Picker("排序", selection: $sortOption) {
                    ForEach(TagSortOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
    }
    
    /// 统计项组件
    private func StatItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// TagManagerRow - 标签管理行组件
struct TagManagerRow: View {
    let tag: TimeTag
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 标签图标和颜色
            Image(systemName: tag.icon ?? "tag.fill")
                .font(.title3)
                .foregroundColor(Color(hex: tag.color ?? "#007AFF"))
                .frame(width: 30)
            
            // 标签信息
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(tag.name ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if tag.isDefault {
                        Text("默认")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                
                Text(tag.category ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let description = tag.tagDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 使用统计
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(tag.usageCount)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text("次使用")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastUsed = tag.lastUsedAt {
                    Text(lastUsed, style: .relative)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            // 操作菜单
            Menu {
                Button("编辑", action: onEdit)
                if !tag.isDefault {
                    Button("删除", role: .destructive, action: onDelete)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Types

enum TagSortOption: String, CaseIterable {
    case usage = "使用次数"
    case name = "名称"
    case category = "类别"
    case recent = "最近使用"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Extensions

// Color.init(hex:) extension is now defined in InsightsView.swift to avoid duplication

// MARK: - Preview

struct TagManagementSheets_Previews: PreviewProvider {
    static var previews: some View {
        NewTagSheet(
            tagManager: TimeTagManager(viewContext: PersistenceController.preview.container.viewContext),
            onDismiss: {}
        )
    }
}