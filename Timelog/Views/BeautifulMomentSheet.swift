import SwiftUI

/// BeautifulMomentSheet - 美好时刻查看和管理界面
/// 展示用户的美好时刻记录，支持筛选和搜索
struct BeautifulMomentSheet: View {
    
    // MARK: - Properties
    
    @ObservedObject var beautifulMomentManager: BeautifulMomentManager
    let onDismiss: () -> Void
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var searchText = ""
    @State private var selectedEmotion: BeautifulMomentEmotion?
    @State private var showingCreateSheet = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 时间范围选择器
                timeRangePicker
                
                // 搜索和筛选
                searchAndFilterSection
                
                // 美好时刻列表
                momentsList
            }
            .navigationTitle("美好时刻")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("创建") {
                        showingCreateSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateBeautifulMomentSheet(
                beautifulMomentManager: beautifulMomentManager,
                onDismiss: { showingCreateSheet = false }
            )
        }
    }
    
    // MARK: - View Components
    
    /// 时间范围选择器
    private var timeRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BeautifulMomentTimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        beautifulMomentManager.selectedTimeRange = range
                    }) {
                        Text(range.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(beautifulMomentManager.selectedTimeRange == range ? .white : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(beautifulMomentManager.selectedTimeRange == range ? Color.blue : Color.blue.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    /// 搜索和筛选区域
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索美好时刻...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button("清除") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // 情感筛选
            emotionFilterSection
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    /// 情感筛选区域
    private var emotionFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 全部选项
                Button(action: {
                    selectedEmotion = nil
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                        Text("全部")
                    }
                    .font(.caption)
                    .foregroundColor(selectedEmotion == nil ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedEmotion == nil ? Color.pink : Color(.systemGray5))
                    .cornerRadius(16)
                }
                
                // 情感选项
                ForEach(BeautifulMomentEmotion.allCases, id: \.self) { emotion in
                    Button(action: {
                        selectedEmotion = selectedEmotion == emotion ? nil : emotion
                    }) {
                        HStack(spacing: 4) {
                            Text(emotion.emoji)
                            Text(emotion.rawValue)
                        }
                        .font(.caption)
                        .foregroundColor(selectedEmotion == emotion ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedEmotion == emotion ? Color.yellow : Color(.systemGray5))
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// 美好时刻列表
    private var momentsList: some View {
        Group {
            if beautifulMomentManager.isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredMoments.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // 统计卡片
                        statsCard
                        
                        // 美好时刻列表
                        ForEach(filteredMoments, id: \.id) { moment in
                            BeautifulMomentCard(moment: moment)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    /// 统计卡片
    private var statsCard: some View {
        let stats = beautifulMomentManager.getBeautifulMomentStats(for: beautifulMomentManager.selectedTimeRange)
        
        return VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.yellow)
                Text("\(beautifulMomentManager.selectedTimeRange.rawValue)统计")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 20) {
                StatItem(
                    title: "总数量",
                    value: "\(stats.totalCount)",
                    icon: "sparkles",
                    color: .yellow
                )
                
                StatItem(
                    title: "总时长",
                    value: stats.formattedTotalDuration,
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatItem(
                    title: "平均强度",
                    value: stats.formattedAverageIntensity,
                    icon: "gauge.medium",
                    color: .green
                )
            }
            
            if let mostCommonEmotion = stats.mostCommonEmotion {
                HStack {
                    Text("最常见的情感:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(mostCommonEmotion.emoji) \(mostCommonEmotion.rawValue)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.yellow.opacity(0.5))
            
            Text("还没有美好时刻")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("开始记录你人生中的美好时刻吧")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("创建第一个美好时刻") {
                showingCreateSheet = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.yellow)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Computed Properties
    
    /// 筛选后的美好时刻
    private var filteredMoments: [TimeCommit] {
        var moments = beautifulMomentManager.beautifulMoments
        
        // 搜索筛选
        if !searchText.isEmpty {
            moments = moments.filter { moment in
                moment.commitMessage?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // 情感筛选
        if let selectedEmotion = selectedEmotion {
            moments = moments.filter { moment in
                moment.commitMessage?.contains(selectedEmotion.emoji) == true
            }
        }
        
        return moments
    }
}

// MARK: - Supporting Views

/// 美好时刻卡片
struct BeautifulMomentCard: View {
    let moment: TimeCommit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部信息
            HStack {
                // 提交哈希
                Text(String(moment.commitHash?.prefix(7) ?? "unknown"))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
                
                Spacer()
                
                // 时间
                if let createdAt = moment.createdAt {
                    Text(createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 提交消息
            Text(moment.commitMessage ?? "无消息")
                .font(.body)
                .fontWeight(.medium)
            
            // 时间范围和强度
            if let timeBlock = moment.timeBlock {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(timeBlock.timeRangeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.medium")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text(moment.formattedFocusIntensity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

/// 创建美好时刻界面
struct CreateBeautifulMomentSheet: View {
    @ObservedObject var beautifulMomentManager: BeautifulMomentManager
    let onDismiss: () -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedEmotion: BeautifulMomentEmotion = .joy
    @State private var intensity: Double = 0.8
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("标题")
                        .font(.headline)
                    
                    TextField("描述这个美好时刻...", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                
                // 情感选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("情感类型")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(BeautifulMomentEmotion.allCases, id: \.self) { emotion in
                            Button(action: {
                                selectedEmotion = emotion
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
                                .background(selectedEmotion == emotion ? Color.yellow.opacity(0.3) : Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                // 强度滑块
                VStack(alignment: .leading, spacing: 8) {
                    Text("美好程度")
                        .font(.headline)
                    
                    HStack {
                        Text("一般")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $intensity, in: 0.1...1.0)
                            .accentColor(.yellow)
                        
                        Text("极佳")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(Int(intensity * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 创建按钮
                Button("创建美好时刻") {
                    // TODO: 实现创建逻辑
                    onDismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(title.isEmpty ? Color.gray : Color.yellow)
                .cornerRadius(12)
                .disabled(title.isEmpty)
            }
            .padding()
            .navigationTitle("创建美好时刻")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct BeautifulMomentSheet_Previews: PreviewProvider {
    static var previews: some View {
        BeautifulMomentSheet(
            beautifulMomentManager: BeautifulMomentManager(viewContext: PersistenceController.preview.container.viewContext),
            onDismiss: {}
        )
    }
}