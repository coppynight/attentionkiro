# Project Structure

## Root Directory
```
Timelog/                      # Main application target
Timelog.xcodeproj/           # Xcode project configuration
.kiro/                       # Kiro AI assistant configuration
```

## Application Structure
```
Timelog/
├── TimelogApp.swift         # App entry point and Core Data setup
├── ContentView.swift        # Main UI view with tab navigation
├── Info.plist              # App configuration and metadata
├── Assets.xcassets/         # App icons, colors, and image assets
├── Models/                  # Core Data model classes
├── Views/                   # SwiftUI view components
│   ├── Heatmap/            # Heatmap visualization views
│   ├── Tagging/            # Time block tagging views
│   ├── Insights/           # Smart analysis views
│   └── Settings/           # Settings and configuration views
├── Services/               # Business logic and data services
├── TimelogDataModel.xcdatamodeld/  # Core Data model definition
└── Preview Content/        # SwiftUI preview assets
```

## Models Directory
- **TimeBlock+CoreDataClass.swift** - Custom business logic for TimeBlock entity
- **TimeBlock+CoreDataProperties.swift** - Generated Core Data properties
- **UserSettings+CoreDataClass.swift** - Custom business logic for UserSettings entity  
- **UserSettings+CoreDataProperties.swift** - Generated Core Data properties

## Views Organization
- **Time/**: Combined time management interface (heatmap + tagging)
- **Insights/**: Smart analysis and summary views
- **Settings/**: App configuration and preferences

## File Organization Principles
- **Feature-based Structure**: Views organized by main app features
- **Core Data Pattern**: Each entity has separate files for custom logic and generated properties
- **SwiftUI Structure**: Clean separation of UI components and business logic
- **Asset Management**: All visual assets centralized in Assets.xcassets

## Naming Conventions
- Swift files use PascalCase (e.g., `HeatmapView.swift`)
- Core Data extensions follow pattern: `EntityName+CoreDataClass.swift` and `EntityName+CoreDataProperties.swift`
- Folders use PascalCase for consistency
- Asset catalogs use descriptive names (AccentColor, AppIcon)

## Key Architectural Decisions
- **Single Target**: Simple iOS app structure without multiple targets or frameworks
- **Core Data Integration**: Centralized persistence controller with environment injection
- **SwiftUI First**: Modern declarative UI approach throughout
- **Feature Modularity**: Clear separation of main app features