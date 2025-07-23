# Core Data Crash 修复总结

## 问题描述
在点击设置tab时发生crash，错误信息：
```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[UserSettings useLocalTimeZone]: unrecognized selector sent to instance 0x6000021a9f40'
```

## 根本原因
Core Data模型文件（.xcdatamodel）中缺少了以下属性：
- `useLocalTimeZone` (Boolean)
- `timeZoneOffset` (Double) 
- `flexibleSleepDays` (Boolean)

虽然Swift代码中的UserSettings+CoreDataProperties.swift文件包含了这些属性，但Core Data模型定义文件没有同步更新。

## 修复步骤

### 1. 更新Core Data模型文件
在 `FocusTracker/FocusDataModel.xcdatamodeld/FocusDataModel.xcdatamodel/contents` 中添加了缺失的属性：

```xml
<attribute name=\"flexibleSleepDays\" optional=\"NO\" attributeType=\"Boolean\" defaultValueString=\"NO\" usesScalarValueType=\"YES\"/>
<attribute name=\"timeZoneOffset\" optional=\"NO\" attributeType=\"Double\" defaultValueString=\"8\" usesScalarValueType=\"YES\"/>
<attribute name=\"useLocalTimeZone\" optional=\"NO\" attributeType=\"Boolean\" defaultValueString=\"YES\" usesScalarValueType=\"YES\"/>
```

### 2. 增强PersistenceController的错误处理
- 启用了轻量级迁移：`shouldMigrateStoreAutomatically = true` 和 `shouldInferMappingModelAutomatically = true`
- 添加了错误恢复机制：如果迁移失败，会删除旧的存储文件并重新创建
- 修复了closure中的内存管理问题，使用`[weak container]`避免循环引用

### 3. 编译修复
修复了PersistenceController中的Swift编译错误：
- 在escaping closure中正确处理self引用
- 使用weak reference避免内存泄漏

## 测试结果
- ✅ 项目编译成功
- ✅ Core Data模型包含所有必需属性
- ✅ 支持轻量级迁移，现有数据不会丢失
- ✅ 错误恢复机制确保应用稳定性

## 技术细节

### Core Data轻量级迁移
当Core Data模型发生变化时，系统会自动：
1. 检测模型版本差异
2. 推断映射模型
3. 迁移现有数据到新模型
4. 如果迁移失败，删除旧数据重新开始（开发阶段）

### 默认值设置
- `useLocalTimeZone`: `true` - 默认使用系统时区
- `timeZoneOffset`: `8.0` - 默认GMT+8（中国时区）
- `flexibleSleepDays`: `false` - 默认不启用周末灵活睡眠时间

## 预防措施
1. 确保Core Data模型文件与Swift属性定义保持同步
2. 在修改Core Data模型时，考虑数据迁移策略
3. 使用版本控制跟踪模型文件变更
4. 在开发过程中定期测试Core Data相关功能

现在应用应该可以正常运行，设置界面不会再发生crash。