# FocusTracker 专注追踪应用

FocusTracker是一款iOS应用，用于追踪和监控用户的专注时间段。应用通过记录用户专注工作的时间，帮助用户建立更好的专注习惯。

## 项目结构

```
FocusTracker/                 # 主应用目标
├── FocusTrackerApp.swift     # 应用入口点和Core Data设置
├── ContentView.swift         # 主UI视图
├── Views/                    # 视图文件夹
│   ├── HomeView.swift        # 首页视图
│   ├── StatisticsView.swift  # 统计视图
│   └── SettingsView.swift    # 设置视图
├── Services/                 # 服务文件夹
│   ├── FocusManager.swift    # 专注管理器
│   └── UsageMonitor.swift    # 使用监控器
├── Models/                   # 模型文件夹
│   ├── FocusSession+CoreDataClass.swift      # 专注会话实体
│   ├── FocusSession+CoreDataProperties.swift # 专注会话属性
│   ├── UserSettings+CoreDataClass.swift      # 用户设置实体
│   └── UserSettings+CoreDataProperties.swift # 用户设置属性
└── FocusDataModel.xcdatamodeld/  # Core Data模型定义

FocusTrackerTests/           # 单元测试目标
├── Services/                # 服务测试
│   └── FocusManagerTests.swift
└── TestHelpers/            # 测试辅助工具
    ├── TestPersistenceController.swift
    ├── TestUsageMonitor.swift
    └── TestFocusManager.swift

FocusTrackerUITests/         # UI测试目标
└── FocusTrackerUITests.swift
```

## 核心功能

- 追踪专注会话的开始和结束时间
- 显示每日专注时间总计
- 根据最小专注时长（30分钟）验证会话
- 存储用户偏好和设置
- 中文界面（专注追踪）
- 7天专注趋势图表
- 专注时段历史列表
- 个人最佳记录展示
- 可配置的午休时间排除
- 灵活的睡眠时间设置
- 跨时区时间调整

## 技术栈

- **SwiftUI** - 现代声明式UI框架
- **Swift** - 主要编程语言
- **Core Data** - 数据持久化和管理
- **Foundation** - 核心系统框架

## 架构模式

- **MVVM** - 模型-视图-视图模型模式与SwiftUI结合
- **Core Data Stack** - 集中式持久化控制器模式
- **Environment Objects** - SwiftUI的依赖注入，用于管理对象上下文

## 测试

项目包含两种类型的测试：

1. **单元测试** (FocusTrackerTests)
   - 测试FocusManager的核心功能
   - 测试专注会话的验证逻辑
   - 测试统计数据的计算

2. **UI测试** (FocusTrackerUITests)
   - 测试标签页导航
   - 测试统计视图的显示
   - 测试设置视图的交互

要运行测试，请在Xcode中选择相应的测试目标并使用Command+U快捷键。

## 构建和运行

1. 使用Xcode打开FocusTracker.xcodeproj
2. 选择一个模拟器或连接的iOS设备
3. 按Command+R运行应用

## 注意事项

- 应用需要iOS 15.0或更高版本
- 图表功能在iOS 16.0及以上版本使用Swift Charts，在较低版本使用自定义实现
- 测试代码已从主应用代码中分离，移至测试目标