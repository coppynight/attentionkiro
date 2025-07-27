import SwiftUI
import CoreData

/// TimeTaggingView - 时间标记界面
/// Git风格的标签选择和应用界面
struct TimeTaggingView: View {
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State Objects
    
    @StateObject private var tagManager: TimeTagManager
    @StateObject private var timeBlockManager: TimeBlockManager
    
    // MARK: - State Variables
    
    @State private var selectedDate = Date()
    @State private var selectedTimeBlocks: Set<TimeBlock> = []
    @State private var selectedTags: Set<TimeTag> = []
    @State private var searchText = ""
    @State private var selectedCategory = "全部"
    @State private var showingTagEditor = false
    @State private var showingNewTagSheet = false
    @State private var showingTagManager = false
    @State private var editingTag: TimeTag?
    @State private var tagToDelete: TimeTag?
    @State private var showingDeleteAlert = false
    
    // MARK: - Computed Properties
    
    private var filteredTimeBlocks: [TimeBlock] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDate
        
        return timeBlockManager.getTimeBlocks(from: startOfDay, to: endOfDay)
            .sorted { ($0.startTime ?? Date.distantPast) < ($1.startTime ?? Date.distantPast) }
    }
    
    private var filteredTags: [TimeTag] {
        var tags = tagManager.allTags
        
        // 搜索过滤
        if !searchText.isEmpty {
            tags = tagManager.searchTags(query: searchText)
        }
        
        // 类别过滤
        if selectedCategory != "全部" {
            tags = tags.filter { $0.category == selectedCategory }
        }
        
        return tags
    }
    
    private var categories: [String] {
        ["全部"] + tagManager.getAllCategories()
    }
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self._tagManager = StateObject(wrappedValue: TimeTagManager(viewContext: viewContext))
        self._timeBlockManager = StateObject(wrappedValue: TimeBlockManager(viewContext: viewContext))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 日期选择器
                datePickerSection
                
                // 主要内容
                ScrollView {
                    VStack(spacing: 20) {
                        // 时间块列表
                        timeBlocksSection
                        
                        // 标签选择区域
                        tagSelectionSection
                        
                        // 推荐标签
                        recommendedTagsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("时间标记")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("管理") {
                        showingTagManager = true
                    }
                    
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
        .sheet(isPresented: $showingTagManager) {
            TagManagerSheet(tagManager: tagManager) {
                showingTagManager = false
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
        .onAppear {
            Task {
                await timeBlockManager.loadTimeBlocks(for: selectedDate)
            }
        }
        .onChange(of: selectedDate) { _ in
            Task {
                await timeBlockManager.loadTimeBlocks(for: selectedDate)
            }
            selectedTimeBlocks.removeAll()
        }
    }
    
    // MARK: - View Components
    
    /// 日期选择器区域
    private var datePickerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                
                Spacer()
                
                Button(action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // 快速日期选择
            HStack(spacing: 12) {
                ForEach([-2, -1, 0, 1, 2], id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                    let isToday = offset == 0
                    let isSelected = Calendar.current.isDate(selectedDate, inSameDayAs: date)
                    
                    Button(action: {
                        selectedDate = date
                    }) {
                        VStack(spacing: 4) {
                            Text(isToday ? "今天" : dayOfWeekString(for: date))
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.subheadline)
                                .fontWeight(isSelected ? .bold : .regular)
                        }
                        .foregroundColor(isSelected ? .white : .primary)
                        .frame(width: 50, height: 50)
                        .background(isSelected ? Color.blue : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    /// 时间块列表区域
    private var timeBlocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("时间块")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !selectedTimeBlocks.isEmpty {
                    Text("已选择 \(selectedTimeBlocks.count) 个")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if filteredTimeBlocks.isEmpty {
                emptyTimeBlocksView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredTimeBlocks, id: \.id) { timeBlock in
                        TimeBlockRow(
                            timeBlock: timeBlock,
                            isSelected: selectedTimeBlocks.contains(timeBlock),
                            onSelectionChanged: { isSelected in
                                if isSelected {
                                    selectedTimeBlocks.insert(timeBlock)
                                } else {
                                    selectedTimeBlocks.remove(timeBlock)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 空时间块视图
    private var emptyTimeBlocksView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("该日期没有时间记录")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("开始记录时间来创建时间块")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    /// 标签选择区域
    private var tagSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("选择标签")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !selectedTags.isEmpty {
                    Button("应用标签") {
                        applySelectedTags()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedTimeBlocks.isEmpty)
                }
            }
            
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
            
            // 类别筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // 标签网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(filteredTags, id: \.id) { tag in
                    TagSelectionCard(
                        tag: tag,
                        isSelected: selectedTags.contains(tag),
                        onSelectionChanged: { isSelected in
                            if isSelected {
                                selectedTags.insert(tag)
                            } else {
                                selectedTags.remove(tag)
                            }
                        },
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
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 推荐标签区域
    private var recommendedTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("智能推荐")
                .font(.headline)
                .fontWeight(.semibold)
            
            if tagManager.recommendedTags.isEmpty {
                Text("暂无推荐标签")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(tagManager.recommendedTags, id: \.id) { tag in
                            RecommendedTagCard(
                                tag: tag,
                                onTap: {
                                    selectedTags.insert(tag)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // 最近使用的标签
            if !tagManager.recentTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最近使用")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tagManager.recentTags, id: \.id) { tag in
                                Button(action: {
                                    selectedTags.insert(tag)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: tag.icon ?? "tag.fill")
                                            .font(.caption)
                                        Text(tag.name ?? "")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: tag.color ?? "#007AFF"))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func applySelectedTags() {
        Task {
            for timeBlock in selectedTimeBlocks {
                for tag in selectedTags {
                    timeBlock.addTag(tag)
                    await tagManager.useTag(tag)
                }
            }
            
            do {
                try viewContext.save()
                selectedTimeBlocks.removeAll()
                selectedTags.removeAll()
            } catch {
                print("应用标签失败: \(error)")
            }
        }
    }
    
    private func dayOfWeekString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

/// TimeBlockRow - 时间块行组件
struct TimeBlockRow: View {
    let timeBlock: TimeBlock
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 选择指示器
            Button(action: {
                onSelectionChanged(!isSelected)
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // 时间范围
                Text(timeBlock.timeRangeString)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // 持续时间
                Text(timeBlock.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // 已有标签
                if !timeBlock.tagsArray.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(timeBlock.tagsArray, id: \.id) { tag in
                                HStack(spacing: 2) {
                                    Image(systemName: tag.icon ?? "tag.fill")
                                        .font(.system(size: 8))
                                    Text(tag.name ?? "")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: tag.color ?? "#007AFF"))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // 美好时刻指示器
            if timeBlock.isBeautifulMoment {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

/// TagSelectionCard - 标签选择卡片
struct TagSelectionCard: View {
    let tag: TimeTag
    let isSelected: Bool
    let onSelectionChanged: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: tag.icon ?? "tag.fill")
                    .font(.title3)
                    .foregroundColor(Color(hex: tag.color ?? "#007AFF"))
                
                Spacer()
                
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
            
            Text(tag.name ?? "")
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text(tag.category ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if tag.usageCount > 0 {
                Text("使用 \(tag.usageCount) 次")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(isSelected ? Color(hex: tag.color ?? "#007AFF").opacity(0.1) : Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color(hex: tag.color ?? "#007AFF") : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
        )
        .onTapGesture {
            onSelectionChanged(!isSelected)
        }
    }
}

/// RecommendedTagCard - 推荐标签卡片
struct RecommendedTagCard: View {
    let tag: TimeTag
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: tag.icon ?? "tag.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: tag.color ?? "#007AFF"))
                
                Text(tag.name ?? "")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(tag.usageCount) 次")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, height: 80)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct TimeTaggingView_Previews: PreviewProvider {
    static var previews: some View {
        TimeTaggingView(viewContext: PersistenceController.preview.container.viewContext)
    }
}