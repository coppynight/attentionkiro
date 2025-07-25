import SwiftUI
import CoreData

struct TagManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var tagManager: TagManager
    @State private var showingAddTag = false
    @State private var showingDeleteAlert = false
    @State private var tagToDelete: SceneTag?
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._tagManager = StateObject(wrappedValue: TagManager(viewContext: context))
    }
    
    var body: some View {
        List {
            Section {
                ForEach(tagManager.defaultTags, id: \.tagID) { tag in
                    TagRowView(tag: tag, isDefault: true)
                }
            } header: {
                Text("默认标签")
            } footer: {
                Text("默认标签不能删除，但可以修改颜色")
            }
            
            Section {
                ForEach(tagManager.customTags, id: \.tagID) { tag in
                    TagRowView(tag: tag, isDefault: false) {
                        tagToDelete = tag
                        showingDeleteAlert = true
                    }
                }
                
                Button(action: {
                    showingAddTag = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("添加自定义标签")
                            .foregroundColor(.primary)
                    }
                }
            } header: {
                Text("自定义标签")
            } footer: {
                Text("您可以创建自定义标签来更好地分类您的时间使用")
            }
        }
        .navigationTitle("标签管理")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddTag) {
            AddTagView(tagManager: tagManager)
        }
        .alert("删除标签", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let tag = tagToDelete {
                    _ = tagManager.deleteTag(tag)
                }
            }
        } message: {
            Text("确定要删除这个标签吗？已关联的时间记录将变为未分类。")
        }
    }
}

struct TagRowView: View {
    let tag: SceneTag
    let isDefault: Bool
    let onDelete: (() -> Void)?
    
    init(tag: SceneTag, isDefault: Bool, onDelete: (() -> Void)? = nil) {
        self.tag = tag
        self.isDefault = isDefault
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 标签颜色指示器
            Circle()
                .fill(colorFromHex(tag.color))
                .frame(width: 16, height: 16)
            
            // 标签信息
            VStack(alignment: .leading, spacing: 2) {
                Text(tag.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("使用 \(tag.usageCount) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isDefault {
                Button(action: {
                    onDelete?()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddTagView: View {
    @ObservedObject var tagManager: TagManager
    @Environment(\.dismiss) private var dismiss
    @State private var tagName = ""
    @State private var selectedColor = "#007AFF"
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let availableColors = [
        "#007AFF", // 蓝色
        "#34C759", // 绿色
        "#FF9500", // 橙色
        "#FF3B30", // 红色
        "#AF52DE", // 紫色
        "#FF2D92", // 粉色
        "#5AC8FA", // 青色
        "#FFCC00", // 黄色
        "#8E8E93", // 灰色
        "#FF6B35", // 深橙色
        "#32D74B", // 浅绿色
        "#BF5AF2"  // 浅紫色
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("标签名称", text: $tagName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } header: {
                    Text("标签信息")
                } footer: {
                    Text("输入一个简短的标签名称，如\"阅读\"、\"运动\"等")
                }
                
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(colorFromHex(color))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("选择颜色")
                } footer: {
                    Text("选择一个颜色来区分不同的标签")
                }
                
                Section {
                    HStack {
                        Circle()
                            .fill(colorFromHex(selectedColor))
                            .frame(width: 16, height: 16)
                        
                        Text(tagName.isEmpty ? "新标签" : tagName)
                            .foregroundColor(tagName.isEmpty ? .secondary : .primary)
                    }
                } header: {
                    Text("预览")
                }
            }
            .navigationTitle("添加标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTag()
                    }
                    .disabled(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveTag() {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "标签名称不能为空"
            showingError = true
            return
        }
        
        if let _ = tagManager.createCustomTag(name: trimmedName, color: selectedColor) {
            dismiss()
        } else {
            errorMessage = "创建标签失败，可能是名称已存在"
            showingError = true
        }
    }
}

// Helper function to convert hex to Color
private func colorFromHex(_ hex: String) -> Color {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
        (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
        (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
        (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
        return .gray
    }

    return Color(
        .sRGB,
        red: Double(r) / 255,
        green: Double(g) / 255,
        blue:  Double(b) / 255,
        opacity: Double(a) / 255
    )
}

struct TagManagementView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TagManagementView()
        }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}