#!/bin/bash
# 提交前测试脚本 - 测试所有平台构建
# 用法: ./scripts/pre-commit-test.sh [--quick]
#   --quick: 只测试 pub get 和 analyze，不构建

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Cherry Reader 提交前测试${NC}"
echo -e "${BLUE}============================================${NC}"

QUICK_MODE=false
if [[ "$1" == "--quick" ]]; then
    QUICK_MODE=true
    echo -e "${YELLOW}快速模式：跳过构建${NC}"
fi

# 记录开始时间
START_TIME=$(date +%s)

# 结果追踪
RESULTS=()

run_step() {
    local name="$1"
    local cmd="$2"

    echo -e "\n${YELLOW}[$name]${NC} 开始..."

    if eval "$cmd" > /tmp/build_output_$$.log 2>&1; then
        echo -e "${GREEN}[$name] ✓ 成功${NC}"
        RESULTS+=("✓ $name")
        return 0
    else
        echo -e "${RED}[$name] ✗ 失败${NC}"
        echo -e "${RED}错误输出:${NC}"
        tail -30 /tmp/build_output_$$.log
        RESULTS+=("✗ $name")
        return 1
    fi
}

# 清理
cleanup() {
    rm -f /tmp/build_output_$$.log
}
trap cleanup EXIT

# ========== 基础检查 ==========
echo -e "\n${BLUE}[1/6] 基础检查${NC}"

run_step "Flutter 版本" "flutter --version"
run_step "Pub Get" "flutter pub get"
run_step "代码分析" "flutter analyze lib --no-fatal-infos --no-fatal-warnings"

# 可选：运行 act 模拟 CI（如果安装了 act）
if command -v act &> /dev/null && [[ "$RUN_ACT" == "true" ]]; then
    echo -e "\n${BLUE}[额外] act 模拟 CI${NC}"
    run_step "act 模拟 Android CI" "act -j build-android -e .github/workflows/act-event.json --quiet" || true
fi

if $QUICK_MODE; then
    echo -e "\n${YELLOW}快速模式完成，跳过构建测试${NC}"
else
    # ========== 平台构建测试 ==========
    echo -e "\n${BLUE}[2/6] Android 构建${NC}"
    run_step "Android APK" "flutter build apk --release" || true

    echo -e "\n${BLUE}[3/6] iOS 构建${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        run_step "iOS (no-codesign)" "flutter build ios --release --no-codesign" || true
    else
        echo -e "${YELLOW}跳过 iOS（非 macOS 系统）${NC}"
        RESULTS+=("- iOS (跳过)")
    fi

    echo -e "\n${BLUE}[4/6] macOS 构建${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        run_step "macOS App" "flutter build macos --release" || true
    else
        echo -e "${YELLOW}跳过 macOS（非 macOS 系统）${NC}"
        RESULTS+=("- macOS (跳过)")
    fi

    echo -e "\n${BLUE}[5/6] Windows 构建${NC}"
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        run_step "Windows EXE" "flutter build windows --release" || true
    else
        echo -e "${YELLOW}跳过 Windows（非 Windows 系统）${NC}"
        RESULTS+=("- Windows (跳过)")
    fi
fi

# ========== 结果汇总 ==========
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo -e "\n${BLUE}============================================${NC}"
echo -e "${BLUE}  测试结果汇总${NC}"
echo -e "${BLUE}============================================${NC}"

FAILED=0
for result in "${RESULTS[@]}"; do
    if [[ "$result" == "✗"* ]]; then
        echo -e "${RED}$result${NC}"
        FAILED=1
    elif [[ "$result" == "-"* ]]; then
        echo -e "${YELLOW}$result${NC}"
    else
        echo -e "${GREEN}$result${NC}"
    fi
done

echo -e "\n耗时: ${DURATION}秒"

if [[ $FAILED -eq 1 ]]; then
    echo -e "\n${RED}============================================${NC}"
    echo -e "${RED}  ✗ 测试失败，请修复后再提交${NC}"
    echo -e "${RED}============================================${NC}"
    exit 1
else
    echo -e "\n${GREEN}============================================${NC}"
    echo -e "${GREEN}  ✓ 所有测试通过，可以提交${NC}"
    echo -e "${GREEN}============================================${NC}"
    exit 0
fi
