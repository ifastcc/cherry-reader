#!/bin/bash
# iOS 真机 Release 模式安装脚本
# 自动检测连接的 iOS 真机设备并安装 release 版本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📱 iOS 真机 Release 安装脚本${NC}"
echo ""

# 检查 Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter 未安装${NC}"
    exit 1
fi

# 使用 --machine 获取 JSON 格式的设备列表，更可靠
echo -e "${BLUE}🔍 检测 iOS 真机设备...${NC}"

# 获取 JSON 格式设备列表，筛选 iOS 真机（排除模拟器）
DEVICE_JSON=$(flutter devices --machine 2>/dev/null)

# 使用 python 解析 JSON（macOS 自带 python3）
DEVICE_ID=$(echo "$DEVICE_JSON" | python3 -c "
import sys, json
try:
    devices = json.load(sys.stdin)
    for d in devices:
        # 筛选条件：iOS 平台 + 非模拟器
        if d.get('targetPlatform') == 'ios' and not d.get('emulator', True):
            print(d['id'])
            break
except:
    pass
" 2>/dev/null)

if [ -z "$DEVICE_ID" ]; then
    echo -e "${RED}❌ 未检测到 iOS 真机设备${NC}"
    echo ""
    echo "请确保："
    echo "  1. iPhone/iPad 已通过 USB 连接"
    echo "  2. 设备已解锁并信任此电脑"
    echo "  3. 已安装 Xcode 和 iOS 开发工具"
    echo ""
    echo "当前所有设备："
    flutter devices
    exit 1
fi

# 获取设备名称用于显示
DEVICE_NAME=$(echo "$DEVICE_JSON" | python3 -c "
import sys, json
try:
    devices = json.load(sys.stdin)
    for d in devices:
        if d.get('id') == '$DEVICE_ID':
            print(d.get('name', 'Unknown'))
            break
except:
    print('iOS Device')
" 2>/dev/null)

echo -e "${GREEN}✅ 检测到设备: ${DEVICE_NAME}${NC}"
echo -e "${BLUE}   设备 ID: ${DEVICE_ID}${NC}"
echo ""

# 检查依赖
echo -e "${BLUE}📦 检查依赖...${NC}"
flutter pub get
echo ""

# 构建并安装 release 版本
echo -e "${BLUE}🔨 构建 iOS Release 版本...${NC}"
echo -e "${YELLOW}这可能需要几分钟时间...${NC}"
echo ""

# 加载环境变量（如果有 .env 文件）
DART_DEFINES=""
if [ -f ".env" ]; then
    echo -e "${BLUE}📄 加载 .env 配置...${NC}"
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        # 去除引号
        value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
        if [ -n "$key" ] && [ -n "$value" ]; then
            DART_DEFINES="$DART_DEFINES --dart-define=$key=$value"
        fi
    done < .env
fi

# 执行构建和安装
echo -e "${GREEN}🚀 开始安装到设备...${NC}"
flutter run -d "$DEVICE_ID" --release $DART_DEFINES

echo ""
echo -e "${GREEN}✅ 安装完成！${NC}"
