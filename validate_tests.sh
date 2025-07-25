#!/bin/bash
# FocusTracker 测试验证脚本
# 快速验证测试文件的语法和结构

echo "🔍 验证 FocusTracker 测试文件..."

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

total_tests=0
total_files=0
errors=0

echo "📊 测试文件统计:"
echo "================"

for test_file in $(find FocusTrackerTests -name "*.swift" -type f); do
    if [ -f "$test_file" ]; then
        total_files=$((total_files + 1))
        filename=$(basename "$test_file")
        
        # 统计测试方法
        test_count=$(grep -c "func test" "$test_file" 2>/dev/null || echo "0")
        if [[ "$test_count" =~ ^[0-9]+$ ]]; then
            total_tests=$((total_tests + test_count))
        else
            test_count=0
        fi
        
        # 检查基本结构
        has_import=$(grep -q "import XCTest" "$test_file" && echo "✅" || echo "❌")
        has_testable=$(grep -q "@testable import FocusTracker" "$test_file" && echo "✅" || echo "❌")
        has_class=$(grep -q "class.*XCTestCase" "$test_file" && echo "✅" || echo "❌")
        
        printf "📄 %-35s %2d 测试 | XCTest:%s Testable:%s Class:%s\n" \
               "$filename" "$test_count" "$has_import" "$has_testable" "$has_class"
        
        # 检查错误
        if [[ "$has_import" == "❌" ]] || [[ "$has_testable" == "❌" ]] || [[ "$has_class" == "❌" ]]; then
            errors=$((errors + 1))
        fi
    fi
done

echo ""
echo "📈 统计摘要:"
echo "============"
echo "📁 测试文件总数: $total_files"
echo "🧪 测试方法总数: $total_tests"

if [ $errors -eq 0 ]; then
    echo -e "${GREEN}✅ 所有测试文件结构正确!${NC}"
else
    echo -e "${RED}❌ 发现 $errors 个文件有结构问题${NC}"
fi

echo ""
echo "🎯 测试覆盖范围:"
echo "================"

# 检查各个功能模块的测试覆盖
modules=(
    "TagManager:TagManagerTests.swift"
    "TimeAnalysisManager:TimeAnalysisManagerTests.swift"
    "AppUsageSession:AppUsageSessionTests.swift"
    "SceneTag:SceneTagTests.swift"
    "数据兼容性:DataCompatibilityTests.swift"
    "专注追踪集成:FocusTrackingIntegrationTests.swift"
    "完整功能集成:FullFeatureIntegrationTests.swift"
    "数据迁移:DataMigrationTests.swift"
    "发布验证:ReleaseVerificationTests.swift"
)

for module in "${modules[@]}"; do
    IFS=':' read -r name file <<< "$module"
    if find FocusTrackerTests -name "$file" -type f | grep -q .; then
        echo -e "✅ $name"
    else
        echo -e "❌ $name (文件不存在)"
    fi
done

echo ""
echo "🚀 运行建议:"
echo "============"
echo "1. 语法检查: swift -frontend -parse FocusTrackerTests/**/*.swift"
echo "2. 运行所有测试: xcodebuild test -project FocusTracker.xcodeproj -scheme FocusTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'"
echo "3. 在 Xcode 中运行: ⌘+U"

if [ $total_tests -ge 100 ]; then
    echo -e "${GREEN}🎉 测试覆盖度优秀! ($total_tests 个测试方法)${NC}"
elif [ $total_tests -ge 50 ]; then
    echo -e "${YELLOW}⚠️  测试覆盖度良好，建议增加更多测试${NC}"
else
    echo -e "${RED}⚠️  测试覆盖度不足，需要添加更多测试${NC}"
fi