import SwiftUI
import UniformTypeIdentifiers

/// 数据导出界面 - Git风格的数据备份功能
struct DataExportSheet: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFormat: SettingsManager.ExportFormat = .csv
    @State private var selectedDateRange: SettingsManager.DateRange = .lastMonth
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题区域
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("导出人生数据")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("将你的时间记录备份到文件")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // 设置选项
                Form {
                    Section {
                        // 导出格式选择
                        Picker("导出格式", selection: $selectedFormat) {
                            ForEach(SettingsManager.ExportFormat.allCases, id: \.self) { format in
                                HStack {
                                    Image(systemName: format == .csv ? "tablecells" : "doc.text")
                                    Text(format.rawValue)
                                }
                                .tag(format)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // 格式说明
                        VStack(alignment: .leading, spacing: 8) {
                            if selectedFormat == .csv {
                                Label("CSV格式适合在Excel或Numbers中打开", systemImage: "tablecells")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Label("JSON格式适合程序化处理和数据分析", systemImage: "doc.text")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 8)
                        
                    } header: {
                        Label("文件格式", systemImage: "doc.fill")
                    }
                    
                    Section {
                        // 日期范围选择
                        Picker("时间范围", selection: $selectedDateRange) {
                            ForEach(SettingsManager.DateRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        // 范围说明
                        let (startDate, endDate) = selectedDateRange.getDateRange()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("导出范围:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text("\(formatDate(startDate)) 至 \(formatDate(endDate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                        
                    } header: {
                        Label("时间范围", systemImage: "calendar")
                    }
                    
                    Section {
                        // 预览信息
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("导出预览")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ExportInfoRow(
                                    icon: "doc.fill",
                                    title: "文件格式",
                                    value: selectedFormat.rawValue
                                )
                                
                                ExportInfoRow(
                                    icon: "calendar",
                                    title: "时间范围",
                                    value: selectedDateRange.rawValue
                                )
                                
                                ExportInfoRow(
                                    icon: "clock.fill",
                                    title: "预计大小",
                                    value: "< 1 MB"
                                )
                            }
                        }
                        
                    } header: {
                        Label("导出信息", systemImage: "info.circle")
                    }
                }
                
                Spacer()
                
                // 导出按钮
                VStack(spacing: 16) {
                    if settingsManager.isExporting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("正在导出数据...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else {
                        Button(action: exportData) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("开始导出")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("数据导出")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("完成") {
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("导出失败", isPresented: $showingError) {
            Button("确定") { }
        } message: {
            if let error = settingsManager.exportError {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func exportData() {
        Task {
            if let url = await settingsManager.exportData(format: selectedFormat, dateRange: selectedDateRange) {
                await MainActor.run {
                    exportedFileURL = url
                    showingShareSheet = true
                }
            } else {
                await MainActor.run {
                    showingError = true
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Export Info Row

struct ExportInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    DataExportSheet(settingsManager: SettingsManager(viewContext: PersistenceController.preview.container.viewContext))
}