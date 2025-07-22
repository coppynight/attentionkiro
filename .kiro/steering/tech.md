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