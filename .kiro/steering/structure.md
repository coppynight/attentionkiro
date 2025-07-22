# Project Structure

## Root Directory
```
FocusTracker/                 # Main application target
FocusTracker.xcodeproj/       # Xcode project configuration
.kiro/                        # Kiro AI assistant configuration
```

## Application Structure
```
FocusTracker/
├── FocusTrackerApp.swift     # App entry point and Core Data setup
├── ContentView.swift         # Main UI view
├── Info.plist               # App configuration and metadata
├── Assets.xcassets/         # App icons, colors, and image assets
├── Models/                  # Core Data model classes
├── FocusDataModel.xcdatamodeld/  # Core Data model definition
└── Preview Content/         # SwiftUI preview assets
```

## Models Directory
- **FocusSession+CoreDataClass.swift** - Custom business logic for FocusSession entity
- **FocusSession+CoreDataProperties.swift** - Generated Core Data properties
- **UserSettings+CoreDataClass.swift** - Custom business logic for UserSettings entity  
- **UserSettings+CoreDataProperties.swift** - Generated Core Data properties

## File Organization Principles
- **Separation of Concerns**: UI, models, and data persistence are clearly separated
- **Core Data Pattern**: Each entity has separate files for custom logic and generated properties
- **SwiftUI Structure**: Views, app entry point, and preview content are organized logically
- **Asset Management**: All visual assets centralized in Assets.xcassets

## Naming Conventions
- Swift files use PascalCase (e.g., `ContentView.swift`)
- Core Data extensions follow pattern: `EntityName+CoreDataClass.swift` and `EntityName+CoreDataProperties.swift`
- Folders use PascalCase for consistency
- Asset catalogs use descriptive names (AccentColor, AppIcon)

## Key Architectural Decisions
- **Single Target**: Simple iOS app structure without multiple targets or frameworks
- **Core Data Integration**: Centralized persistence controller with environment injection
- **SwiftUI First**: Modern declarative UI approach throughout
- **Preview Support**: All views should include preview providers for development