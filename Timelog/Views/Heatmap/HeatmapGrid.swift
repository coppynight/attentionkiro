import SwiftUI

/// HeatmapGrid - 热力图网格组件
/// 渲染GitHub风格的24小时×15分钟热力图网格
struct HeatmapGrid: View {
    
    // MARK: - Properties
    
    let heatmapData: HeatmapData?
    let onBlockTapped: (HeatmapGridBlock) -> Void
    
    // MARK: - Constants
    
    private let gridSpacing: CGFloat = 2
    private let blockSize: CGFloat = 12
    private let hoursPerDay = 24
    private let blocksPerHour = 4
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            if let data = heatmapData {
                VStack(spacing: gridSpacing) {
                    ForEach(0..<hoursPerDay, id: \.self) { hour in
                        HStack(spacing: gridSpacing) {
                            ForEach(0..<blocksPerHour, id: \.self) { quarter in
                                let blockIndex = hour * blocksPerHour + quarter
                                let gridBlock = data.gridBlocks[blockIndex]
                                
                                HeatmapGridCell(
                                    gridBlock: gridBlock,
                                    size: blockSize,
                                    onTapped: {
                                        onBlockTapped(gridBlock)
                                    }
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 空状态
                emptyStateView
            }
        }
        .frame(height: CGFloat(hoursPerDay) * (blockSize + gridSpacing) - gridSpacing)
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("暂无数据")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("开始记录时间来生成你的人生贡献图")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// HeatmapGridCell - 热力图网格单元格
struct HeatmapGridCell: View {
    
    // MARK: - Properties
    
    let gridBlock: HeatmapGridBlock
    let size: CGFloat
    let onTapped: () -> Void
    
    // MARK: - State
    
    @State private var isPressed = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTapped) {
            RoundedRectangle(cornerRadius: 2)
                .fill(cellColor)
                .frame(width: size, height: size)
                .overlay(
                    // 美好时刻的特殊标记
                    gridBlock.hasBeautifulMoment ? 
                    Image(systemName: "sparkles")
                        .font(.system(size: size * 0.6))
                        .foregroundColor(.white)
                    : nil
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // 长按执行点击
            onTapped()
        }
        .help(gridBlock.tooltipText) // macOS tooltip support
    }
    
    /// 单元格颜色
    private var cellColor: Color {
        if gridBlock.hasBeautifulMoment {
            return Color(hex: "#FFD700") // 金色美好时刻
        } else {
            return Color(hex: gridBlock.intensityLevel.color)
        }
    }
}

/// HeatmapDetailSheet - 热力图详情弹窗
struct HeatmapDetailSheet: View {
    
    // MARK: - Properties
    
    let gridBlock: HeatmapGridBlock
    let onDismiss: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 时间信息
                timeInfoSection
                
                // 强度信息
                intensityInfoSection
                
                // 活动信息
                if !gridBlock.activities.isEmpty {
                    activitiesSection
                }
                
                // 美好时刻信息
                if gridBlock.hasBeautifulMoment {
                    beautifulMomentSection
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("时间块详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    /// 时间信息区域
    private var timeInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("时间范围")
                .font(.headline)
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text(gridBlock.timeRangeString)
                    .font(.title3)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    /// 强度信息区域
    private var intensityInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("专注强度")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack {
                    Rectangle()
                        .fill(Color(hex: gridBlock.intensityLevel.color))
                        .frame(width: 20, height: 20)
                        .cornerRadius(4)
                    
                    Text(gridBlock.intensityLevel.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", gridBlock.intensity * 100))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: gridBlock.intensityLevel.color))
                }
                
                ProgressView(value: gridBlock.intensity)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: gridBlock.intensityLevel.color)))
                    .scaleEffect(y: 2)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    /// 活动信息区域
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("相关活动")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(gridBlock.activities, id: \.self) { activity in
                    HStack {
                        Image(systemName: "tag.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(activity)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                }
            }
        }
    }
    
    /// 美好时刻信息区域
    private var beautifulMomentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("美好时刻")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("这是一个被标记为美好时刻的时间段")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !gridBlock.timeBlocks.isEmpty {
                    ForEach(gridBlock.timeBlocks.filter { $0.isBeautifulMoment }, id: \.id) { timeBlock in
                        if let commits = timeBlock.commits?.allObjects as? [TimeCommit] {
                            ForEach(commits.filter { $0.isBeautifulMoment }, id: \.id) { commit in
                                HStack {
                                    Text(commit.commitMessage ?? "美好时刻")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
    }
}

/// StatCard - 统计卡片组件
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

/// DatePickerSheet - 日期选择器弹窗
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "选择日期",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("选择日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions

// Color.init(hex:) extension is now defined in InsightsView.swift to avoid duplication

// MARK: - Preview

struct HeatmapGrid_Previews: PreviewProvider {
    static var previews: some View {
        HeatmapGrid(
            heatmapData: nil,
            onBlockTapped: { _ in }
        )
        .frame(height: 300)
        .padding()
    }
}