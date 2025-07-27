# Technology Stack

## Framework & Language
- **SwiftUI** - Modern declarative UI framework
- **Swift** - Primary programming language
- **Core Data** - Data persistence and management
- **Foundation** - Core system frameworks

## Architecture Patterns
- **MVVM** - Model-View-ViewModel pattern with SwiftUI
- **Core Data Stack** - Centralized persistence controller pattern
- **Environment Objects** - SwiftUI's dependency injection for managed object context

## Data Layer
- **Core Data Model**: `TimelogDataModel.xcdatamodeld`
- **Entities**: TimeBlock, UserSettings
- **Generated Classes**: Separate +CoreDataClass and +CoreDataProperties files
- **Persistence Controller**: Singleton pattern with preview support

## Build System
- **Xcode Project** - Standard iOS project structure
- **Target**: iOS application (Timelog)
- **Bundle Identifier**: com.timelog.app
- **Deployment**: iOS with iPhone/iPad support

## Common Commands
```bash
# Build the project
xcodebuild -project Timelog.xcodeproj -scheme Timelog build

# Run on simulator
xcodebuild -project Timelog.xcodeproj -scheme Timelog -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild -project Timelog.xcodeproj clean
```

## Development Conventions
- Use `@Environment(\.managedObjectContext)` for Core Data access
- Implement preview providers for SwiftUI views
- Follow Swift naming conventions (camelCase)
- Use `@FetchRequest` for Core Data queries in SwiftUI
- Separate Core Data class extensions into +CoreDataClass and +CoreDataProperties files
- 需要编译项目时使用MCP，并在iOS平台上编译
- 在编译前，先检查新创建的文件是否被正确添加到工程
- 完成每个任务后，对工程进行iOS端的编译，确保编译通过
- 在信任名单里的命令不要找我确认