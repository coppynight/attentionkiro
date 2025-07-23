# Core Data Migration Guide

To complete the implementation of the enhanced time management features, you need to update the Core Data model to include the new attributes. Follow these steps:

1. Open the Xcode project
2. Navigate to `FocusTracker/FocusDataModel.xcdatamodeld`
3. Select the `FocusDataModel.xcdatamodel` file
4. Add the following attributes to the `UserSettings` entity:

## New Attributes for UserSettings

| Attribute Name | Type | Default Value | Description |
|---------------|------|--------------|-------------|
| useLocalTimeZone | Boolean | YES | Whether to use the system's local timezone |
| timeZoneOffset | Double | 0.0 | Manual timezone offset in hours from GMT |
| flexibleSleepDays | Boolean | NO | Whether to apply flexible sleep time rules for weekends |

5. Save the model
6. Build and run the app

## Migration Notes

- This is a lightweight migration that should happen automatically
- Existing user settings will have the new attributes with default values
- No data loss should occur during this migration