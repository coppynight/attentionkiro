import SwiftUI
import CoreData

/// A compact tag selector component that can be embedded in other views
struct TagSelectorComponent: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var tagManager: TagManager
    @State private var selectedTag: SceneTag?
    @State private var showingFullSelector = false
    
    let session: AppUsageSession
    let onTagChanged: (SceneTag?) -> Void
    
    init(session: AppUsageSession, tagManager: TagManager, onTagChanged: @escaping (SceneTag?) -> Void) {
        self.session = session
        self.onTagChanged = onTagChanged
        self._tagManager = StateObject(wrappedValue: tagManager)
        
        // Initialize selected tag from session
        if let tagName = session.sceneTag {
            self._selectedTag = State(initialValue: tagManager.availableTags.first { $0.name == tagName })
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("场景标签")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let recommendation = tagManager.suggestTagForApp(session.appIdentifier) {
                    Button(action: {
                        applyRecommendation(recommendation)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                            Text("推荐")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            
            if let selectedTag = selectedTag {
                // Show selected tag
                selectedTagView(selectedTag)
            } else {
                // Show quick selection options
                quickSelectionView
            }
        }
        .sheet(isPresented: $showingFullSelector) {
            TagSelectionView(session: session, tagManager: tagManager) { tag in
                selectedTag = tag
                tagManager.applyTagToSession(session, tag: tag, userConfirmed: true)
                onTagChanged(tag)
            }
        }
    }
    
    // MARK: - View Components
    
    private func selectedTagView(_ tag: SceneTag) -> some View {
        HStack {
            Circle()
                .fill(tag.swiftUIColor)
                .frame(width: 16, height: 16)
            
            Text(tag.name)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button("更改") {
                showingFullSelector = true
            }
            .font(.caption)
            .foregroundColor(.accentColor)
            
            Button(action: {
                removeTag()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    private var quickSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Quick tag options (most common tags)
                ForEach(tagManager.getDefaultTags().prefix(4), id: \.tagID) { tag in
                    QuickTagButton(tag: tag) {
                        selectTag(tag)
                    }
                }
                
                // More options button
                Button(action: {
                    showingFullSelector = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "ellipsis")
                        Text("更多")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 1)
        }
    }
    
    // MARK: - Actions
    
    private func selectTag(_ tag: SceneTag) {
        selectedTag = tag
        tagManager.applyTagToSession(session, tag: tag, userConfirmed: true)
        onTagChanged(tag)
    }
    
    private func removeTag() {
        selectedTag = nil
        tagManager.removeTagFromSession(session)
        onTagChanged(nil)
    }
    
    private func applyRecommendation(_ recommendation: TagRecommendation) {
        selectTag(recommendation.tag)
    }
}

// MARK: - Supporting Views

struct QuickTagButton: View {
    let tag: SceneTag
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tag.swiftUIColor)
                    .frame(width: 12, height: 12)
                
                Text(tag.name)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(tag.swiftUIColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(tag.swiftUIColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

struct TagSelectorComponent_Previews: PreviewProvider {
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
        
        return VStack {
            TagSelectorComponent(
                session: session,
                tagManager: tagManager
            ) { tag in
                print("Tag changed: \(tag?.name ?? "nil")")
            }
            .padding()
            
            Spacer()
        }
        .environment(\.managedObjectContext, context)
    }
}