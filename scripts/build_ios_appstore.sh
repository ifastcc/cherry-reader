#!/bin/bash
# Cherry Reader iOS 打包脚本 v2
# 用法: ./scripts/build_ios_appstore.sh [版本号] [构建号]
# 例如: ./scripts/build_ios_appstore.sh 1.0.0 1

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 路径配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/release_ios"
ARCHIVE_PATH="$OUTPUT_DIR/CherryReader.xcarchive"
EXPORT_DIR="$OUTPUT_DIR/export"

# 版本配置
VERSION=${1:-"1.0.0"}
BUILD_NUMBER=${2:-$(date +%Y%m%d%H%M)}

echo -e "${BLUE}══════════════════════════════════════${NC}"
echo -e "${BLUE}  Cherry Reader iOS 打包 v2${NC}"
echo -e "${BLUE}  版本: ${VERSION} (${BUILD_NUMBER})${NC}"
echo -e "${BLUE}══════════════════════════════════════${NC}"

cd "$PROJECT_DIR"

# Step 1: 清理和准备
step_clean() {
    echo -e "\n${YELLOW}[1/5] 清理旧文件...${NC}"
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$EXPORT_DIR"
    flutter clean
    echo -e "${GREEN}  ✓ 清理完成${NC}"
}

# Step 2: Flutter 构建
step_flutter_build() {
    echo -e "\n${YELLOW}[2/5] Flutter 构建...${NC}"

    # 创建 .env
    echo "APP_VERSION=$VERSION" > .env

    # 获取依赖
    flutter pub get

    # 构建 iOS (不签名，后面 Archive 时再签名)
    flutter build ios --release --no-codesign \
        --build-name="$VERSION" \
        --build-number="$BUILD_NUMBER"

    echo -e "${GREEN}  ✓ Flutter 构建完成${NC}"
}

# Step 3: Pod Install
step_pod_install() {
    echo -e "\n${YELLOW}[3/5] CocoaPods...${NC}"
    cd "$PROJECT_DIR/ios"
    pod install || pod install --repo-update
    cd "$PROJECT_DIR"
    echo -e "${GREEN}  ✓ CocoaPods 完成${NC}"
}

# Step 4: Xcode Archive
step_archive() {
    echo -e "\n${YELLOW}[4/5] Xcode Archive...${NC}"

    xcodebuild -workspace "$PROJECT_DIR/ios/Runner.xcworkspace" \
        -scheme Runner \
        -sdk iphoneos \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=iOS" \
        -allowProvisioningUpdates \
        MARKETING_VERSION="$VERSION" \
        CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
        archive

    if [ -d "$ARCHIVE_PATH" ]; then
        echo -e "${GREEN}  ✓ Archive 创建成功${NC}"
    else
        echo -e "${RED}  ✗ Archive 失败${NC}"
        exit 1
    fi
}

# Step 5: 打开 Xcode Organizer 手动导出
step_open_organizer() {
    echo -e "\n${YELLOW}[5/5] 打开 Xcode Organizer...${NC}"

    # 打开 Archive
    open "$ARCHIVE_PATH"

    echo -e "${GREEN}  ✓ 已打开 Xcode Organizer${NC}"

    echo -e "\n${BLUE}══════════════════════════════════════${NC}"
    echo -e "${BLUE}  请在 Xcode 中完成以下步骤：${NC}"
    echo -e "${BLUE}══════════════════════════════════════${NC}"
    echo ""
    echo -e "  1. 在 Organizer 中选择 ${GREEN}Cherry Reader${NC} 的 Archive"
    echo -e "  2. 点击 ${GREEN}Distribute App${NC}"
    echo -e "  3. 选择 ${GREEN}App Store Connect${NC}"
    echo -e "  4. 选择 ${GREEN}Upload${NC} (直接上传)"
    echo -e "  5. 勾选 ${GREEN}Automatically manage signing${NC}"
    echo -e "  6. 点击 ${GREEN}Upload${NC}"
    echo ""
    echo -e "  上传成功后，约 ${YELLOW}5-30 分钟${NC} 后可在"
    echo -e "  App Store Connect → TestFlight 中看到构建"
    echo ""
}

# 主流程
main() {
    step_clean
    step_flutter_build
    step_pod_install
    step_archive
    step_open_organizer

    echo -e "\n${GREEN}══════════════════════════════════════${NC}"
    echo -e "${GREEN}  打包完成！${NC}"
    echo -e "${GREEN}══════════════════════════════════════${NC}"
    echo -e "\nArchive 位置: $ARCHIVE_PATH"
}

main "$@"
