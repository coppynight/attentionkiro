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
- **Core Data Model**: `FocusDataModel.xcdatamodeld`
- **Entities**: FocusSession, UserSettings
- **Generated Classes**: Separate +CoreDataClass and +CoreDataProperties files
- **Persistence Controller**: Singleton pattern with preview support

## Build System
- **Xcode Project** - Standard iOS project structure
- **Target**: iOS application
- **Bundle Identifier**: Configured via project settings
- **Deployment**: iOS with iPhone/iPad support

## Common Commands
```bash
# Build the project
xcodebuild -project FocusTracker.xcodeproj -scheme FocusTracker build

# Run on simulator
xcodebuild -project FocusTracker.xcodeproj -scheme FocusTracker -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild -project FocusTracker.xcodeproj clean
```

## Development Conventions
- Use `@Environment(\.managedObjectContext)` for Core Data access
- Implement preview providers for SwiftUI views
- Follow Swift naming conventions (camelCase)
- Use `@FetchRequest` for Core Data queries in SwiftUI
- Separate Core Data class extensions into +CoreDataClass and +CoreDataProperties files
- 需要操作Xcode时请使用MCP
- 需要编译工程时，请在iOS平台上进行编译
- 在编译前，先检查新创建的文件是否被正确添加到工程，如果没有添加，先暂停操作并列出需要被添加的文件请求人工添加，在人工添加完成后再继续刚才的编译
- 完成每个任务后，对工程进行iOS端的编译，确保编译通过