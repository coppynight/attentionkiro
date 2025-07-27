import SwiftUI
import CoreData

/// ContentView - 主应用界面
/// 统一的TabView导航，集成所有核心功能模块
struct ContentView: View {
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - State Variables
    
    @State private var selectedTab = 0
    @State private var showingWelcome = false
    @State private var isInitialized = false
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 时间记录主界面 - 人生提交界面
            TimeRecordingView(viewContext: viewContext)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "play.circle.fill" : "play.circle")
                    Text("提交")
                }
                .tag(0)
            
            // 时间管理界面 - 人生贡献图和标签系统
            TimeManagementView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "clock.fill" : "clock")
                    Text("时间")
                }
                .tag(1)
            
            // 智能洞察界面 - 人生代码审查
            InsightsView(viewContext: viewContext)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "brain.head.profile.fill" : "brain.head.profile")
                    Text("洞察")
                }
                .tag(2)
            
            // 项目设置界面
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                    Text("设置")
                }
                .tag(3)
        }
        .accentColor(.green) // GitHub风格的绿色主题
        .onAppear {
            initializeApp()
        }
        .onChange(of: scenePhase) { phase in
            handleScenePhaseChange(phase)
        }
        .sheet(isPresented: $showingWelcome) {
            WelcomeView {
                showingWelcome = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// 应用初始化逻辑
    private func initializeApp() {
        guard !isInitialized else { return }
        
        // 检查是否首次启动
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        
        if isFirstLaunch {
            // 首次启动，显示欢迎界面
            showingWelcome = true
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        }
        
        // 初始化默认数据
        initializeDefaultData()
        
        isInitialized = true
    }
    
    /// 初始化默认数据
    private func initializeDefaultData() {
        // 这里可以添加默认标签、设置等初始化逻辑
        // 由于PersistenceController已经处理了默认数据，这里主要做一些应用级别的初始化
        
        // 设置默认的用户偏好
        if UserDefaults.standard.object(forKey: "DefaultTimeBlockDuration") == nil {
            UserDefaults.standard.set(1200, forKey: "DefaultTimeBlockDuration") // 20分钟
        }
        
        if UserDefaults.standard.object(forKey: "EnableBeautifulMoments") == nil {
            UserDefaults.standard.set(true, forKey: "EnableBeautifulMoments")
        }
        
        if UserDefaults.standard.object(forKey: "HeatmapColorScheme") == nil {
            UserDefaults.standard.set("github", forKey: "HeatmapColorScheme")
        }
    }
    
    /// 处理应用生命周期变化
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // 应用变为活跃状态
            break
        case .inactive:
            // 应用变为非活跃状态
            break
        case .background:
            // 应用进入后台，保存数据
            saveContext()
        @unknown default:
            break
        }
    }
    
    /// 保存Core Data上下文
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("保存数据失败: \(error)")
        }
    }
}

// MARK: - Time Management View

/// TimeManagementView - 时间管理综合界面
/// 集成热力图和标签功能的统一界面
struct TimeManagementView: View {
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State Variables
    
    @State private var selectedSegment = 0
    @State private var selectedDate = Date()
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 分段控制器 - 切换热力图和标签视图
                segmentedControl
                
                // 主要内容区域
                contentView
            }
            .navigationTitle("时间管理")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 今天按钮
                    Button("今天") {
                        selectedDate = Date()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// 分段控制器
    private var segmentedControl: some View {
        VStack(spacing: 0) {
            Picker("视图模式", selection: $selectedSegment) {
                Label("记录图", systemImage: "chart.bar.fill").tag(0)
                Label("标签", systemImage: "tag.fill").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
        }
        .background(Color(.systemGray6))
    }
    
    /// 内容视图
    private var contentView: some View {
        Group {
            if selectedSegment == 0 {
                // 热力图视图
                HeatmapView(viewContext: viewContext)
            } else {
                // 标签视图
                TimeTaggingView(viewContext: viewContext)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedSegment)
    }
}

// MARK: - Welcome View

/// WelcomeView - 欢迎界面
/// 首次启动时显示的引导界面
struct WelcomeView: View {
    let onDismiss: () -> Void
    
    @State private var currentPage = 0
    private let totalPages = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 页面指示器
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)
                
                // 内容区域
                TabView(selection: $currentPage) {
                    welcomePage1.tag(0)
                    welcomePage2.tag(1)
                    welcomePage3.tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // 底部按钮
                VStack(spacing: 16) {
                    if currentPage < totalPages - 1 {
                        Button("下一步") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button("跳过") {
                            onDismiss()
                        }
                        .foregroundColor(.secondary)
                    } else {
                        Button("开始使用") {
                            onDismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding()
            }
            .navigationTitle("欢迎使用 Timelog")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("跳过", action: onDismiss))
        }
    }
    
    // MARK: - Welcome Pages
    
    private var welcomePage1: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("人生就是一个项目")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("你花费的时间就是在向人生的git提交记录")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    private var welcomePage2: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("GitHub风格的人生贡献图")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("用热力图展示你的时间投入，就像程序员的代码贡献")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    private var welcomePage3: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
            
            VStack(spacing: 16) {
                Text("标记美好时刻")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("为重要的时间片段打上tag，记录人生中的精彩瞬间")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}