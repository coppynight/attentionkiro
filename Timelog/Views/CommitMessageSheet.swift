import SwiftUI

/// CommitMessageSheet - 提交消息输入界面
/// Git风格的提交消息编辑界面，支持美好时刻标记
struct CommitMessageSheet: View {
    
    // MARK: - Bindings
    
    @Binding var commitMessage: String
    @Binding var isBeautifulMoment: Bool
    
    // MARK: - Properties
    
    let onCommit: () -> Void
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var selectedEmotion: BeautifulMomentEmotion = .joy
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Git风格的提交界面头部
                commitHeader
                
                // 提交消息输入区域
                messageInputSection
                
                // 美好时刻标记区域
                beautifulMomentSection
                
                Spacer()
                
                // 提交按钮
                commitButton
            }
            .padding()
            .navigationTitle("完成提交")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    // MARK: - View Components
    
    /// Git风格的提交界面头部
    private var commitHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "terminal.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("git commit -m")
                    .font(.system(.title3, design: .monospaced))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                Text("为这次人生提交添加有意义的消息")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// 提交消息输入区域
    private var messageInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("提交消息")
                    .font(.headline)
                
                Spacer()
                
                Text("\(commitMessage.count)/100")
                    .font(.caption)
                    .foregroundColor(commitMessage.count > 100 ? .red : .secondary)
            }
            
            TextField("描述这段时间你做了什么...", text: $commitMessage, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .focused($isTextFieldFocused)
            
            // 快速消息建议
            if commitMessage.isEmpty {
                quickMessageSuggestions
            }
        }
    }
    
    /// 快速消息建议
    private var quickMessageSuggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快速选择")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(quickMessages, id: \.self) { message in
                    Button(action: {
                        commitMessage = message
                    }) {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
        }
    }
    
    /// 美好时刻标记区域
    private var beautifulMomentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $isBeautifulMoment) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("标记为美好时刻")
                        .font(.headline)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .yellow))
            
            if isBeautifulMoment {
                beautifulMomentDetails
            }
        }
        .padding()
        .background(isBeautifulMoment ? Color.yellow.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: isBeautifulMoment)
    }
    
    /// 美好时刻详细设置
    private var beautifulMomentDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择情感类型")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(BeautifulMomentEmotion.allCases, id: \.self) { emotion in
                    Button(action: {
                        selectedEmotion = emotion
                        // 自动添加情感emoji到提交消息
                        if !commitMessage.contains(emotion.emoji) {
                            commitMessage = "\(emotion.emoji) \(commitMessage)".trimmingCharacters(in: .whitespaces)
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(emotion.emoji)
                                .font(.title2)
                            
                            Text(emotion.rawValue)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedEmotion == emotion ? Color.yellow.opacity(0.3) : Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedEmotion == emotion ? Color.yellow : Color.clear, lineWidth: 2)
                        )
                    }
                    .foregroundColor(.primary)
                }
            }
            
            Text(selectedEmotion.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
    
    /// 提交按钮
    private var commitButton: some View {
        Button(action: {
            onCommit()
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("提交到人生仓库")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(commitMessage.isEmpty ? Color.gray : (isBeautifulMoment ? Color.yellow : Color.green))
            .cornerRadius(12)
        }
        .disabled(commitMessage.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: commitMessage.isEmpty)
    }
    
    // MARK: - Data
    
    /// 快速消息建议
    private let quickMessages = [
        "专注工作中",
        "深度学习",
        "创意思考",
        "解决问题",
        "阅读充电",
        "整理思路",
        "项目推进",
        "技能提升"
    ]
}

// MARK: - Preview

struct CommitMessageSheet_Previews: PreviewProvider {
    static var previews: some View {
        CommitMessageSheet(
            commitMessage: .constant(""),
            isBeautifulMoment: .constant(false),
            onCommit: {}
        )
    }
}