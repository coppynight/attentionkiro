import SwiftUI
import CoreData

/// A view for selecting and applying tags to app usage sessions
struct TagSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var tagManager: TagManager
    @State private var selectedTag: SceneTag?
    @State private var showingCreateTag = false
    @State private var newTagName = ""
    @State private var newTagColor = "#007AFF"
    
    let session: AppUsageSession
    let onTagSelected: (SceneTag) -> Void
    
    // Available colors for new tags
    private let availableColors = [
        "#007AFF", "#34C759", "#FF9500", "#FF2D92",
        "#30D158", "#AC39FF", "#64D2FF", "#FF3B30",
        "#FFCC00", "#5856D6", "#AF52DE", "#FF6482"
    ]
    
    init(session: AppUsageSession, tagManager: TagManager, onTagSelected: @escaping (SceneTag) -> Void) {
        self.session = session
        self.onTagSelected = onTagSelected
        self._tagManager = StateObject(wrappedValue: tagManager)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // App info header
                appInfoHeader
                
                Divider()
                
                // Tag recommendations
                if !recommendations.isEmpty {
                    recommendationsSection
                    Divider()
                }
                
                // All available tags
                allTagsSection
                
                Spacer()
                
                // Action buttons
                actionButtons
            }
            .navigationTitle("选择场景标签")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新建") {
                        showingCreateTag = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateTag) {
            createTagSheet
        }
    }
    
    // MARK: - View Components
    
    private var appInfoHeader: some View {
        VStack(spacing: 8) {
            HStack {
                // App icon placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(session.appName.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.primary)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.appName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(session.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var recommendations: [TagRecommendation] {
        tagManager.getTagRecommendations(session.appIdentifier, limit: 3)
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("推荐标签")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendations, id: \.tag.tagID) { recommendation in
                        RecommendationTagCard(
                            recommendation: recommendation,
                            isSelected: selectedTag?.tagID == recommendation.tag.tagID
                        ) {
                            selectedTag = recommendation.tag
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 12)
        }
    }
    
    private var allTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("所有标签")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(tagManager.availableTags, id: \.tagID) { tag in
                    TagCard(
                        tag: tag,
                        isSelected: selectedTag?.tagID == tag.tagID
                    ) {
                        selectedTag = tag
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if let selectedTag = selectedTag {
                Button(action: {
                    onTagSelected(selectedTag)
                    dismiss()
                }) {
                    HStack {
                        Circle()
                            .fill(selectedTag.swiftUIColor)
                            .frame(width: 16, height: 16)
                        Text("应用标签：\(selectedTag.name)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Button("跳过") {
                dismiss()
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var createTagSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("标签名称")
                        .font(.headline)
                    
                    TextField("输入标签名称", text: $newTagName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("标签颜色")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color) ?? Color.blue)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: newTagColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    newTagColor = color
                                }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("创建新标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showingCreateTag = false
                        newTagName = ""
                        newTagColor = "#007AFF"
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        createNewTag()
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func createNewTag() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        if let newTag = tagManager.createCustomTag(name: trimmedName, color: newTagColor) {
            selectedTag = newTag
            showingCreateTag = false
            newTagName = ""
            newTagColor = "#007AFF"
        }
    }
}

// MARK: - Supporting Views

struct RecommendationTagCard: View {
    let recommendation: TagRecommendation
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(recommendation.tag.swiftUIColor)
                    .frame(width: 20, height: 20)
                
                Text(recommendation.tag.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 4) {
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(index < Int(recommendation.confidence * 5) ? .yellow : .gray.opacity(0.3))
                    }
                }
                
                Text(recommendation.reason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: 120, height: 80)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct TagCard: View {
    let tag: SceneTag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(tag.swiftUIColor)
                .frame(width: 24, height: 24)
            
            Text(tag.name)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
        )
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Preview

struct TagSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let tagManager = TagManager(viewContext: context)
        
        // Create a sample session
        let session = AppUsageSession.createSession(
            appIdentifier: "com.apple.mobilesafari",
            appName: "Safari",
            categoryIdentifier: "productivity",
            in: context
        )
        session.duration = 1800 // 30 minutes
        
        return TagSelectionView(
            session: session,
            tagManager: tagManager
        ) { tag in
            print("Selected tag: \(tag.name)")
        }
        .environment(\.managedObjectContext, context)
    }
}