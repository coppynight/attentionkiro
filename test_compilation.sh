#!/bin/bash

echo "🔍 检查测试编译状态..."

# 尝试编译单个测试文件
echo "📄 检查 TimeAnalysisManagerTests.swift..."
xcodebuild -project FocusTracker.xcodeproj -scheme FocusTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:FocusTrackerTests/TimeAnalysisManagerTests build-for-testing 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)"

echo ""
echo "📄 检查 TagManagerTests.swift..."
xcodebuild -project FocusTracker.xcodeproj -scheme FocusTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:FocusTrackerTests/TagManagerTests build-for-testing 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)"

echo ""
echo "📄 检查 FocusTrackingIntegrationTests.swift..."
xcodebuild -project FocusTracker.xcodeproj -scheme FocusTracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -only-testing:FocusTrackerTests/FocusTrackingIntegrationTests build-for-testing 2>&1 | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)"