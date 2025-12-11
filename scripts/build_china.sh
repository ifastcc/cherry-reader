#!/bin/bash
# Cherry Reader 国内市场打包脚本
# 用法: ./scripts/build_china.sh [版本号]
# 例如: ./scripts/build_china.sh 1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/release_china"

VERSION=${1:-"1.0.0"}
BUILD_NUMBER=$(date +%Y%m%d%H%M)

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Cherry Reader 国内市场打包${NC}"
echo -e "${BLUE}  版本: ${VERSION}+${BUILD_NUMBER}${NC}"
echo -e "${BLUE}======================================${NC}"

cd "$PROJECT_DIR"

# 创建输出目录
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 更新 .env
echo "# Auto generated" > .env
echo "APP_VERSION=$VERSION" >> .env

# 检查签名配置
KEYSTORE_CONFIG="$PROJECT_DIR/android/key.properties"
if [ ! -f "$KEYSTORE_CONFIG" ]; then
    echo -e "\n${YELLOW}[提示] 未找到签名配置${NC}"
    echo -e "请创建 android/key.properties 文件:"
    echo ""
    echo "storePassword=你的密钥库密码"
    echo "keyPassword=你的密钥密码"
    echo "keyAlias=cherry_reader"
    echo "storeFile=/path/to/your/keystore.jks"
    echo ""
    echo -e "${YELLOW}创建密钥库命令:${NC}"
    echo "keytool -genkey -v -keystore ~/cherry-reader.jks \\"
    echo "  -keyalg RSA -keysize 2048 -validity 10000 \\"
    echo "  -alias cherry_reader"
    echo ""
    read -p "是否使用 debug 签名继续? (y/N): " use_debug
    if [[ "$use_debug" != "y" && "$use_debug" != "Y" ]]; then
        exit 1
    fi
fi

# 获取依赖
echo -e "\n${YELLOW}[1/4] 获取依赖...${NC}"
flutter pub get

# 构建通用 APK（适用于所有市场）
echo -e "\n${YELLOW}[2/4] 构建通用 APK...${NC}"
flutter build apk --release \
    --build-name="$VERSION" \
    --build-number="$BUILD_NUMBER"

cp build/app/outputs/flutter-apk/app-release.apk \
   "$OUTPUT_DIR/CherryReader-v${VERSION}-universal.apk"
echo -e "${GREEN}  ✓ 通用 APK 完成${NC}"

# 构建分架构 APK（减小包体积）
echo -e "\n${YELLOW}[3/4] 构建分架构 APK...${NC}"
flutter build apk --release --split-per-abi \
    --build-name="$VERSION" \
    --build-number="$BUILD_NUMBER"

# arm64 (主流新手机)
if [ -f "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" ]; then
    cp "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" \
       "$OUTPUT_DIR/CherryReader-v${VERSION}-arm64.apk"
    echo -e "${GREEN}  ✓ arm64 APK 完成${NC}"
fi

# arm32 (老手机)
if [ -f "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" ]; then
    cp "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" \
       "$OUTPUT_DIR/CherryReader-v${VERSION}-arm32.apk"
    echo -e "${GREEN}  ✓ arm32 APK 完成${NC}"
fi

# 生成 SHA256 校验和
echo -e "\n${YELLOW}[4/4] 生成校验和...${NC}"
cd "$OUTPUT_DIR"
for f in *.apk; do
    shasum -a 256 "$f" >> SHA256SUMS.txt
done
cd "$PROJECT_DIR"
echo -e "${GREEN}  ✓ 校验和已生成${NC}"

# 显示结果
echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}  打包完成！${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "\n输出目录: $OUTPUT_DIR"
echo -e "\n生成的文件:"
ls -lh "$OUTPUT_DIR"

# 包大小分析
echo -e "\n${BLUE}包大小分析:${NC}"
for f in "$OUTPUT_DIR"/*.apk; do
    size=$(ls -lh "$f" | awk '{print $5}')
    name=$(basename "$f")
    echo "  $name: $size"
done

# 国内市场上架指南
echo -e "\n${BLUE}======================================${NC}"
echo -e "${BLUE}  国内市场上架指南${NC}"
echo -e "${BLUE}======================================${NC}"

echo -e "\n${YELLOW}推荐上架顺序:${NC}"
echo ""
echo "1. 小米应用商店 (支持个人开发者)"
echo "   https://dev.mi.com/"
echo "   - 审核快（1-2天）"
echo "   - 个人开发者友好"
echo "   - 用户量大"
echo ""
echo "2. 酷安 (技术用户聚集地)"
echo "   https://developer.coolapk.com/"
echo "   - 工具类 App 理想平台"
echo "   - 用户质量高"
echo ""
echo "3. 华为应用市场 (需企业资质)"
echo "   https://developer.huawei.com/"
echo "   - 华为/荣耀用户必备"
echo ""
echo "4. OPPO/vivo 软件商店 (需企业资质)"
echo "   https://open.oppomobile.com/"
echo "   https://dev.vivo.com.cn/"

echo -e "\n${YELLOW}上架前检查清单:${NC}"
echo "  [ ] 应用图标 512x512 PNG"
echo "  [ ] 应用截图 3-5 张"
echo "  [ ] 隐私政策 URL"
echo "  [ ] 功能介绍文案"
echo "  [ ] 开发者身份认证"
echo "  [ ] APK 正式签名"

echo -e "\n${YELLOW}注意事项:${NC}"
echo "  - 工具类 App 通常不需要版号"
echo "  - 确保已声明所有权限用途"
echo "  - 检查 SDK 合规性（个人信息收集）"
echo "  - 建议先上小米，积累评价后再上其他平台"
