#!/bin/bash
# Cherry Viewer Flutter 启动脚本

set -e

# 重置时区为系统默认（避免终端 TZ 环境变量影响）
unset TZ

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🍒 Cherry Viewer Flutter 启动脚本${NC}"
echo ""

# 检查 Flutter 是否安装
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}⚠️  Flutter 未安装${NC}"
    echo "请访问 https://flutter.dev/docs/get-started/install 安装 Flutter"
    exit 1
fi

echo -e "${GREEN}✅ Flutter 已安装${NC}"
flutter --version
echo ""

# 检查依赖
echo -e "${BLUE}📦 检查依赖...${NC}"
flutter pub get
echo ""

# 生成 JSON 序列化代码
echo -e "${BLUE}🔨 生成 JSON 序列化代码...${NC}"
if ! flutter pub run build_runner build --delete-conflicting-outputs; then
    echo -e "${YELLOW}⚠️  代码生成失败，但继续运行${NC}"
fi
echo ""

# 选择运行平台
echo -e "${BLUE}📱 可用设备:${NC}"
flutter devices
echo ""

# 默认运行 macOS 桌面版
if [[ "$1" == "web" ]]; then
    echo -e "${GREEN}🌐 启动 Web 版本...${NC}"
    flutter run -d chrome
elif [[ "$1" == "ios" ]]; then
    echo -e "${GREEN}📱 启动 iOS 模拟器...${NC}"
    flutter run -d ios
else
    echo -e "${GREEN}🖥️  启动 macOS 桌面版...${NC}"

    # 检查是否设置了 OpenAI API Key
    if [[ -z "$OPENAI_API_KEY" ]]; then
        echo -e "${YELLOW}⚠️  未设置 OPENAI_API_KEY 环境变量${NC}"
        echo "AI 分析功能将无法使用"
        echo ""
        echo "设置方法:"
        echo "  export OPENAI_API_KEY='sk-...'"
        echo "  ./run.sh"
        echo ""
    fi

    # 构建运行参数
    RUN_ARGS="-d macos"

    # 添加 DevTools 支持（运行后按 'd' 打开）
    echo -e "${BLUE}💡 提示: 运行后按 'd' 打开 DevTools 性能分析${NC}"
    echo ""

    if [[ -n "$OPENAI_API_KEY" ]]; then
        flutter run $RUN_ARGS --dart-define=OPENAI_API_KEY="$OPENAI_API_KEY"
    else
        flutter run $RUN_ARGS
    fi
fi
