import SwiftUI
import CoreData

#if DEBUG
struct TestView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var focusQualityAnalyzer: FocusQualityAnalyzer
    @State private var testResults: [String] = []
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        self._focusQualityAnalyzer = StateObject(wrappedValue: FocusQualityAnalyzer(viewContext: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("测试新功能")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        Button("生成测试数据") {
                            generateTestData()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("测试专注质量分析") {
                            testFocusQualityAnalysis()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("测试打断分析") {
                            testInterruptionAnalysis()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("清除测试数据") {
                            clearTestData()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    
                    if !testResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("测试结果:")
                                .font(.headline)
                            
                            ForEach(Array(testResults.enumerated()), id: \.offset) { index, result in
                                Text("• \(result)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("测试")
        }
    }
    
    private func generateTestData() {
        testResults.removeAll()
        
        let calendar = Calendar.current
        let today = Date()
        
        // 生成过去7天的测试数据
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            
            // 为每天生成2-4个专注会话
            let sessionCount = Int.random(in: 2...4)
            
            for j in 0..<sessionCount {
                let session = FocusSession(context: viewContext)
                
                // 随机生成会话时间
                let startHour = Int.random(in: 9...18)
                let startMinute = Int.random(in: 0...59)
                let duration = TimeInterval(Int.random(in: 15...90) * 60) // 15-90分钟
                
                var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
                startComponents.hour = startHour
                startComponents.minute = startMinute
                
                session.startTime = calendar.date(from: startComponents) ?? date
                session.endTime = session.startTime.addingTimeInterval(duration)
                session.duration = duration
                session.sessionType = "focus"
                session.isValid = duration >= 30 * 60 // 30分钟以上为有效
                
                // 注意：FocusSession没有tag属性，这里注释掉
                // let tags = ["工作", "学习", "阅读", "编程", "设计"]
                // session.tag = tags.randomElement()
            }
        }
        
        do {
            try viewContext.save()
            testResults.append("成功生成7天的测试数据")
        } catch {
            testResults.append("生成测试数据失败: \(error.localizedDescription)")
        }
    }
    
    private func testFocusQualityAnalysis() {
        let today = Date()
        let metrics = focusQualityAnalyzer.analyzeFocusQuality(for: today)
        
        testResults.append("今日专注质量评分: \(Int(metrics.focusQualityScore))")
        testResults.append("深度专注时间: \(formatTime(metrics.deepFocusTime))")
        testResults.append("中等专注时间: \(formatTime(metrics.mediumFocusTime))")
        testResults.append("碎片时间: \(formatTime(metrics.fragmentedTime))")
        testResults.append("打断次数: \(metrics.interruptionCount)")
        testResults.append("最长专注时间: \(formatTime(metrics.longestFocusStreak))")
    }
    
    private func testInterruptionAnalysis() {
        let today = Date()
        let analysis = focusQualityAnalyzer.analyzeInterruptions(for: today)
        
        testResults.append("总打断次数: \(analysis.totalInterruptions)")
        testResults.append("平均打断时长: \(formatTime(analysis.averageInterruptionDuration))")
        testResults.append("恢复率: \(Int(analysis.interruptionRecoveryRate * 100))%")
        testResults.append("高发时段: \(analysis.mostCommonInterruptionHour):00")
        
        for (type, count) in analysis.interruptionsByType {
            testResults.append("\(type): \(count)次")
        }
    }
    
    private func clearTestData() {
        let request: NSFetchRequest<NSFetchRequestResult> = FocusSession.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
            testResults.removeAll()
            testResults.append("测试数据已清除")
        } catch {
            testResults.append("清除数据失败: \(error.localizedDescription)")
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif