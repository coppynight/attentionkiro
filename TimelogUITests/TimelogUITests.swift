import XCTest

/// TimelogUITests - MVP版本UI集成测试
/// 测试应用的主要用户流程和界面交互
final class TimelogUITests: XCTestCase {
    
    // MARK: - Properties
    
    var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // 在UI测试中，失败时立即停止通常是最好的选择
        continueAfterFailure = false
        
        // 初始化应用
        app = XCUIApplication()
        
        // 设置启动参数，用于测试环境
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["UITEST_DISABLE_ANIMATIONS": "1"]
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - App Launch Tests
    
    /// 测试应用启动和主界面显示
    @MainActor
    func testAppLaunchAndMainInterface() throws {
        app.launch()
        
        // 验证应用成功启动
        XCTAssertTrue(app.state == .runningForeground)
        
        // 验证TabView存在并显示正确的标签
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        
        // 验证四个主要标签页存在
        XCTAssertTrue(app.tabBars.buttons["提交"].exists)
        XCTAssertTrue(app.tabBars.buttons["时间"].exists)
        XCTAssertTrue(app.tabBars.buttons["洞察"].exists)
        XCTAssertTrue(app.tabBars.buttons["设置"].exists)
    }
    
    /// 测试首次启动欢迎界面
    @MainActor
    func testWelcomeScreenOnFirstLaunch() throws {
        // 重置应用状态，模拟首次启动
        app.launchArguments.append("--reset-user-defaults")
        app.launch()
        
        // 检查是否显示欢迎界面
        let welcomeTitle = app.navigationBars["欢迎使用 Timelog"]
        if welcomeTitle.exists {
            // 验证欢迎界面内容
            XCTAssertTrue(app.staticTexts["人生就是一个项目"].exists)
            
            // 测试跳过按钮
            app.buttons["跳过"].tap()
            
            // 验证进入主界面
            XCTAssertTrue(app.tabBars.firstMatch.exists)
        }
    }
    
    // MARK: - Tab Navigation Tests
    
    /// 测试标签页导航
    @MainActor
    func testTabNavigation() throws {
        app.launch()
        
        // 测试切换到时间标签页
        app.tabBars.buttons["时间"].tap()
        XCTAssertTrue(app.navigationBars["时间管理"].exists)
        
        // 测试切换到洞察标签页
        app.tabBars.buttons["洞察"].tap()
        XCTAssertTrue(app.navigationBars["智能洞察"].exists)
        
        // 测试切换到设置标签页
        app.tabBars.buttons["设置"].tap()
        XCTAssertTrue(app.navigationBars["项目设置"].exists)
        
        // 测试切换回提交标签页
        app.tabBars.buttons["提交"].tap()
        XCTAssertTrue(app.navigationBars["人生提交"].exists)
    }
    
    // MARK: - Time Recording Tests
    
    /// 测试时间记录功能
    @MainActor
    func testTimeRecordingFlow() throws {
        app.launch()
        
        // 确保在提交标签页
        app.tabBars.buttons["提交"].tap()
        
        // 查找开始按钮
        let startButton = app.buttons["开始新的提交"]
        if startButton.exists {
            startButton.tap()
            
            // 验证会话已开始
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS '进行中'")).firstMatch.exists)
            
            // 等待一小段时间
            sleep(2)
            
            // 查找结束按钮
            let endButton = app.buttons["结束提交"]
            if endButton.exists {
                endButton.tap()
                
                // 验证提交消息输入界面
                let commitSheet = app.sheets.firstMatch
                if commitSheet.exists {
                    // 输入提交消息
                    let messageField = app.textFields["提交消息"]
                    if messageField.exists {
                        messageField.tap()
                        messageField.typeText("UI测试提交")
                    }
                    
                    // 保存提交
                    app.buttons["保存"].tap()
                }
            }
        }
    }
    
    // MARK: - Heatmap Tests
    
    /// 测试热力图界面
    @MainActor
    func testHeatmapInterface() throws {
        app.launch()
        
        // 切换到时间标签页
        app.tabBars.buttons["时间"].tap()
        
        // 确保在记录图视图
        let segmentedControl = app.segmentedControls.firstMatch
        if segmentedControl.exists {
            segmentedControl.buttons["记录图"].tap()
        }
        
        // 验证热力图相关元素存在
        XCTAssertTrue(app.staticTexts["时间记录图"].exists)
        
        // 测试日期选择
        let todayButton = app.buttons["今天"]
        if todayButton.exists {
            todayButton.tap()
        }
        
        // 验证热力图网格存在
        let heatmapGrid = app.otherElements["HeatmapGrid"]
        XCTAssertTrue(heatmapGrid.exists || app.staticTexts.containing(NSPredicate(format: "label CONTAINS '时间'")).count > 0)
    }
    
    /// 测试时间标签功能
    @MainActor
    func testTimeTaggingInterface() throws {
        app.launch()
        
        // 切换到时间标签页
        app.tabBars.buttons["时间"].tap()
        
        // 切换到标签视图
        let segmentedControl = app.segmentedControls.firstMatch
        if segmentedControl.exists {
            segmentedControl.buttons["标签"].tap()
        }
        
        // 验证标签界面元素
        XCTAssertTrue(app.staticTexts["时间标记"].exists || app.staticTexts["今日时间块"].exists)
        
        // 如果有时间块，测试标记功能
        let timeBlocks = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'TimeBlockRow'"))
        if timeBlocks.count > 0 {
            timeBlocks.firstMatch.tap()
            
            // 验证标记界面
            let taggingSheet = app.sheets.firstMatch
            if taggingSheet.exists {
                // 测试取消按钮
                app.buttons["取消"].tap()
            }
        }
    }
    
    // MARK: - Insights Tests
    
    /// 测试智能洞察界面
    @MainActor
    func testInsightsInterface() throws {
        app.launch()
        
        // 切换到洞察标签页
        app.tabBars.buttons["洞察"].tap()
        
        // 验证洞察界面元素
        XCTAssertTrue(app.navigationBars["智能洞察"].exists)
        
        // 测试时间范围选择
        let timeRangePicker = app.segmentedControls.firstMatch
        if timeRangePicker.exists {
            timeRangePicker.buttons["本周"].tap()
            timeRangePicker.buttons["本月"].tap()
        }
        
        // 验证分析卡片存在
        let analysisCards = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'Card'"))
        XCTAssertGreaterThan(analysisCards.count, 0)
    }
    
    // MARK: - Settings Tests
    
    /// 测试设置界面
    @MainActor
    func testSettingsInterface() throws {
        app.launch()
        
        // 切换到设置标签页
        app.tabBars.buttons["设置"].tap()
        
        // 验证设置界面元素
        XCTAssertTrue(app.navigationBars["项目设置"].exists)
        
        // 测试设置项
        let settingsCells = app.cells
        XCTAssertGreaterThan(settingsCells.count, 0)
        
        // 测试数据导出功能
        let exportButton = app.buttons["数据导出"]
        if exportButton.exists {
            exportButton.tap()
            
            // 验证导出界面
            let exportSheet = app.sheets.firstMatch
            if exportSheet.exists {
                // 测试取消按钮
                app.buttons["取消"].tap()
            }
        }
    }
    
    // MARK: - Data Export Tests
    
    /// 测试数据导出功能
    @MainActor
    func testDataExportFlow() throws {
        app.launch()
        
        // 进入设置页面
        app.tabBars.buttons["设置"].tap()
        
        // 点击数据导出
        let exportButton = app.buttons["数据导出"]
        if exportButton.exists {
            exportButton.tap()
            
            // 验证导出选项界面
            let exportSheet = app.sheets.firstMatch
            if exportSheet.exists {
                // 测试格式选择
                let csvButton = app.buttons["CSV格式"]
                let jsonButton = app.buttons["JSON格式"]
                
                if csvButton.exists {
                    csvButton.tap()
                }
                
                // 测试时间范围选择
                let thisWeekButton = app.buttons["本周"]
                if thisWeekButton.exists {
                    thisWeekButton.tap()
                }
                
                // 测试导出按钮
                let exportActionButton = app.buttons["导出数据"]
                if exportActionButton.exists {
                    exportActionButton.tap()
                }
            }
        }
    }
    
    // MARK: - Performance Tests
    
    /// 测试应用启动性能
    @MainActor
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            app.terminate()
        }
    }
    
    /// 测试界面切换性能
    @MainActor
    func testTabSwitchingPerformance() throws {
        app.launch()
        
        measure {
            // 快速切换所有标签页
            for _ in 0..<5 {
                app.tabBars.buttons["时间"].tap()
                app.tabBars.buttons["洞察"].tap()
                app.tabBars.buttons["设置"].tap()
                app.tabBars.buttons["提交"].tap()
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    /// 测试可访问性支持
    @MainActor
    func testAccessibilitySupport() throws {
        app.launch()
        
        // 验证主要界面元素的可访问性标签
        XCTAssertTrue(app.tabBars.buttons["提交"].isHittable)
        XCTAssertTrue(app.tabBars.buttons["时间"].isHittable)
        XCTAssertTrue(app.tabBars.buttons["洞察"].isHittable)
        XCTAssertTrue(app.tabBars.buttons["设置"].isHittable)
        
        // 测试VoiceOver支持
        let tabButtons = app.tabBars.buttons
        for button in tabButtons.allElementsBoundByIndex {
            XCTAssertFalse(button.label.isEmpty, "Tab button should have accessibility label")
        }
    }
    
    // MARK: - Error Handling Tests
    
    /// 测试网络错误处理
    @MainActor
    func testErrorHandling() throws {
        app.launch()
        
        // 模拟错误状态（如果应用支持）
        // 这里可以添加特定的错误场景测试
        
        // 验证应用在错误状态下仍然可用
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
    
    // MARK: - Memory and Resource Tests
    
    /// 测试内存使用
    @MainActor
    func testMemoryUsage() throws {
        app.launch()
        
        // 执行一系列操作来测试内存使用
        for _ in 0..<10 {
            // 切换标签页
            app.tabBars.buttons["时间"].tap()
            app.tabBars.buttons["洞察"].tap()
            app.tabBars.buttons["设置"].tap()
            app.tabBars.buttons["提交"].tap()
            
            // 短暂等待
            usleep(100000) // 0.1秒
        }
        
        // 验证应用仍然响应
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
}