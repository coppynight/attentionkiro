import SwiftUI
import CoreData

/// TimelogApp - 应用程序入口点
/// 人生项目的主要启动和配置逻辑
@main
struct TimelogApp: App {
    
    // MARK: - Properties
    
    let persistenceController = PersistenceController.shared
    
    // MARK: - Scene Configuration
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    configureAppearance()
                }
        }
    }
    
    // MARK: - App Configuration
    
    /// 配置应用外观和全局设置
    private func configureAppearance() {
        // 配置导航栏外观
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        // 配置Tab Bar外观
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        // 设置选中和未选中的颜色
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemGreen
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemGreen
        ]
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // 配置分段控制器外观
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.systemGreen
        UISegmentedControl.appearance().setTitleTextAttributes([
            .foregroundColor: UIColor.white
        ], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([
            .foregroundColor: UIColor.label
        ], for: .normal)
        
        // 配置进度条外观
        UIProgressView.appearance().progressTintColor = UIColor.systemGreen
        UIProgressView.appearance().trackTintColor = UIColor.systemGray5
        
        // 配置按钮外观
        UIButton.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = UIColor.systemGreen
    }
}
