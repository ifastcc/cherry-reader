#!/bin/bash
# Cherry Reader 生产环境打包脚本
# 支持 Android 签名打包 + iOS Archive
# 用法: ./scripts/build_production.sh [版本号] [平台]
# 例如: ./scripts/build_production.sh 1.0.0 android
#       ./scripts/build_production.sh 1.0.0 ios
#       ./scripts/build_production.sh 1.0.0 all

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/release_output"

# 配置文件路径
ANDROID_KEYSTORE_CONFIG="$PROJECT_DIR/android/key.properties"

# 参数
VERSION=${1:-"1.0.0"}
PLATFORM=${2:-"all"}
BUILD_NUMBER=$(date +%Y%m%d%H%M)

print_header() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  Cherry Reader 生产环境打包${NC}"
    echo -e "${BLUE}  版本: ${VERSION}+${BUILD_NUMBER}${NC}"
    echo -e "${BLUE}  平台: ${PLATFORM}${NC}"
    echo -e "${BLUE}======================================${NC}"
}

check_prerequisites() {
    echo -e "\n${YELLOW}[检查] 检查必要工具...${NC}"

    # Flutter
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}错误: Flutter 未安装${NC}"
        exit 1
    fi
    echo -e "  ✓ Flutter: $(flutter --version | head -1)"

    # Android SDK (如果构建 Android)
    if [[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]]; then
        if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
            echo -e "${YELLOW}  ⚠ ANDROID_HOME 未设置，尝试使用默认路径${NC}"
        fi
    fi

    # Xcode (如果构建 iOS)
    if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
        if [[ "$OSTYPE" != "darwin"* ]]; then
            echo -e "${RED}错误: iOS 构建需要 macOS${NC}"
            exit 1
        fi
        if ! command -v xcodebuild &> /dev/null; then
            echo -e "${RED}错误: Xcode 未安装${NC}"
            exit 1
        fi
        echo -e "  ✓ Xcode: $(xcodebuild -version | head -1)"
    fi
}

setup_android_signing() {
    echo -e "\n${YELLOW}[Android] 检查签名配置...${NC}"

    if [ ! -f "$ANDROID_KEYSTORE_CONFIG" ]; then
        echo -e "${YELLOW}未找到签名配置文件: $ANDROID_KEYSTORE_CONFIG${NC}"
        echo -e "${YELLOW}请创建 key.properties 文件，格式如下:${NC}"
        cat << 'EOF'
# android/key.properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=cherry_reader
storeFile=/path/to/your/keystore.jks
EOF
        echo ""
        read -p "是否使用 debug 签名继续? (y/N): " use_debug
        if [[ "$use_debug" != "y" && "$use_debug" != "Y" ]]; then
            exit 1
        fi
        return 1  # 使用 debug 签名
    fi

    # 验证密钥库文件存在
    KEYSTORE_PATH=$(grep "storeFile" "$ANDROID_KEYSTORE_CONFIG" | cut -d'=' -f2)
    if [ ! -f "$KEYSTORE_PATH" ]; then
        echo -e "${RED}错误: 密钥库文件不存在: $KEYSTORE_PATH${NC}"
        exit 1
    fi

    echo -e "  ✓ 签名配置已就绪"
    return 0
}

build_android() {
    echo -e "\n${GREEN}======================================${NC}"
    echo -e "${GREEN}  构建 Android${NC}"
    echo -e "${GREEN}======================================${NC}"

    cd "$PROJECT_DIR"

    # 检查签名
    if setup_android_signing; then
        SIGNING_FLAG=""
    else
        SIGNING_FLAG="--debug"
        echo -e "${YELLOW}使用 debug 签名${NC}"
    fi

    # 构建 App Bundle (推荐上架 Play Store)
    echo -e "\n${YELLOW}[1/3] 构建 App Bundle (AAB)...${NC}"
    flutter build appbundle --release \
        --build-name="$VERSION" \
        --build-number="$BUILD_NUMBER"

    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
        cp "build/app/outputs/bundle/release/app-release.aab" \
           "$OUTPUT_DIR/CherryReader-$VERSION.aab"
        echo -e "${GREEN}  ✓ AAB 已生成${NC}"
    fi

    # 构建 APK (用于直接分发)
    echo -e "\n${YELLOW}[2/3] 构建 APK...${NC}"
    flutter build apk --release \
        --build-name="$VERSION" \
        --build-number="$BUILD_NUMBER"

    cp "build/app/outputs/flutter-apk/app-release.apk" \
       "$OUTPUT_DIR/CherryReader-$VERSION.apk"
    echo -e "${GREEN}  ✓ APK 已生成${NC}"

    # 构建分架构 APK
    echo -e "\n${YELLOW}[3/3] 构建分架构 APK...${NC}"
    flutter build apk --release --split-per-abi \
        --build-name="$VERSION" \
        --build-number="$BUILD_NUMBER"

    cp "build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" \
       "$OUTPUT_DIR/CherryReader-$VERSION-arm64.apk" 2>/dev/null || true
    cp "build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" \
       "$OUTPUT_DIR/CherryReader-$VERSION-arm32.apk" 2>/dev/null || true
    echo -e "${GREEN}  ✓ 分架构 APK 已生成${NC}"
}

build_ios() {
    echo -e "\n${GREEN}======================================${NC}"
    echo -e "${GREEN}  构建 iOS${NC}"
    echo -e "${GREEN}======================================${NC}"

    cd "$PROJECT_DIR"

    # 检查是否有签名配置
    echo -e "\n${YELLOW}[1/4] 检查 iOS 签名配置...${NC}"

    # 更新 CocoaPods
    echo -e "\n${YELLOW}[2/4] 更新 CocoaPods...${NC}"
    cd ios
    pod install --repo-update || pod install
    cd "$PROJECT_DIR"

    # 构建选项
    echo -e "\n${YELLOW}选择构建类型:${NC}"
    echo "  1) 未签名 (用于企业签名/自签名)"
    echo "  2) 开发签名 (用于真机调试)"
    echo "  3) App Store 签名 (用于上架)"
    read -p "请选择 [1-3, 默认1]: " build_type
    build_type=${build_type:-1}

    case $build_type in
        1)
            # 未签名构建
            echo -e "\n${YELLOW}[3/4] 构建 iOS (未签名)...${NC}"
            flutter build ios --release --no-codesign \
                --build-name="$VERSION" \
                --build-number="$BUILD_NUMBER"

            echo -e "\n${YELLOW}[4/4] 导出 .app...${NC}"
            mkdir -p "$OUTPUT_DIR/ios-unsigned"
            cp -r "build/ios/iphoneos/Runner.app" "$OUTPUT_DIR/ios-unsigned/"
            cd "$OUTPUT_DIR/ios-unsigned"
            zip -r "../CherryReader-$VERSION-ios-unsigned.zip" Runner.app
            cd "$PROJECT_DIR"
            rm -rf "$OUTPUT_DIR/ios-unsigned"
            echo -e "${GREEN}  ✓ 未签名 iOS App 已生成${NC}"
            ;;
        2)
            # 开发签名
            echo -e "\n${YELLOW}[3/4] 构建 iOS (开发签名)...${NC}"
            flutter build ios --release \
                --build-name="$VERSION" \
                --build-number="$BUILD_NUMBER"

            echo -e "\n${YELLOW}[4/4] 导出 IPA (开发)...${NC}"
            create_export_options "development"
            export_ipa "development"
            ;;
        3)
            # App Store 签名
            echo -e "\n${YELLOW}[3/4] 构建 iOS (App Store)...${NC}"
            flutter build ios --release \
                --build-name="$VERSION" \
                --build-number="$BUILD_NUMBER"

            echo -e "\n${YELLOW}[4/4] 导出 IPA (App Store)...${NC}"
            create_export_options "app-store"
            export_ipa "app-store"
            ;;
    esac
}

create_export_options() {
    local method=$1
    local plist_file="$PROJECT_DIR/ios/ExportOptions.plist"

    # 从 Xcode 项目获取 Team ID 和 Bundle ID
    local team_id=$(grep -A1 "DEVELOPMENT_TEAM" "$PROJECT_DIR/ios/Runner.xcodeproj/project.pbxproj" | grep -o '"[A-Z0-9]*"' | head -1 | tr -d '"')
    local bundle_id=$(grep "PRODUCT_BUNDLE_IDENTIFIER" "$PROJECT_DIR/ios/Runner.xcodeproj/project.pbxproj" | head -1 | grep -o '"[^"]*"' | tr -d '"')

    if [ -z "$team_id" ]; then
        echo -e "${YELLOW}未找到 Team ID，请输入:${NC}"
        read -p "Team ID: " team_id
    fi

    if [ -z "$bundle_id" ]; then
        bundle_id="com.example.cherryViewerFlutter"
    fi

    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${method}</string>
    <key>teamID</key>
    <string>${team_id}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF
    echo -e "  ✓ 导出配置已生成"
}

export_ipa() {
    local method=$1
    local archive_path="$PROJECT_DIR/build/ios/archive/Runner.xcarchive"
    local export_path="$OUTPUT_DIR/ios-$method"

    # 创建 Archive
    echo -e "  创建 Archive..."
    xcodebuild -workspace "$PROJECT_DIR/ios/Runner.xcworkspace" \
        -scheme Runner \
        -configuration Release \
        -archivePath "$archive_path" \
        archive \
        -allowProvisioningUpdates

    # 导出 IPA
    echo -e "  导出 IPA..."
    mkdir -p "$export_path"
    xcodebuild -exportArchive \
        -archivePath "$archive_path" \
        -exportPath "$export_path" \
        -exportOptionsPlist "$PROJECT_DIR/ios/ExportOptions.plist" \
        -allowProvisioningUpdates

    # 重命名 IPA
    if [ -f "$export_path/Runner.ipa" ]; then
        mv "$export_path/Runner.ipa" "$OUTPUT_DIR/CherryReader-$VERSION-ios-$method.ipa"
        rm -rf "$export_path"
        echo -e "${GREEN}  ✓ IPA 已生成: CherryReader-$VERSION-ios-$method.ipa${NC}"
    fi
}

setup_android_gradle() {
    # 检查是否已配置签名
    local build_gradle="$PROJECT_DIR/android/app/build.gradle.kts"

    if ! grep -q "signingConfigs" "$build_gradle" || grep -q 'signingConfigs.getByName("debug")' "$build_gradle"; then
        echo -e "\n${YELLOW}[Android] 配置 release 签名...${NC}"

        # 创建带签名配置的 build.gradle.kts
        cat > "$build_gradle" << 'GRADLE_EOF'
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 加载签名配置
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.cherry_reader"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.cherry_reader"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

configurations.all {
    resolutionStrategy {
        force("androidx.core:core:1.13.1")
        force("androidx.core:core-ktx:1.13.1")
    }
}
GRADLE_EOF

        # 创建 ProGuard 规则文件
        cat > "$PROJECT_DIR/android/app/proguard-rules.pro" << 'PROGUARD_EOF'
# Flutter 相关
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Isar 数据库
-keep class dev.isar.isar.** { *; }
PROGUARD_EOF

        echo -e "${GREEN}  ✓ Android 签名配置已更新${NC}"
    fi
}

print_summary() {
    echo -e "\n${GREEN}======================================${NC}"
    echo -e "${GREEN}  构建完成！${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo -e "\n输出目录: $OUTPUT_DIR"
    echo -e "\n生成的文件:"
    ls -lh "$OUTPUT_DIR" 2>/dev/null || echo "  (无文件)"

    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${BLUE}  下一步操作${NC}"
    echo -e "${BLUE}======================================${NC}"

    if [[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]]; then
        echo -e "\n${YELLOW}Android 上架:${NC}"
        echo "  1. 登录 Google Play Console"
        echo "  2. 创建应用 → 上传 AAB 文件"
        echo "  3. 填写应用信息、截图、隐私政策"
        echo "  4. 提交审核"
    fi

    if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
        echo -e "\n${YELLOW}iOS 上架:${NC}"
        echo "  1. 登录 App Store Connect"
        echo "  2. 创建 App → 上传 IPA (使用 Transporter 或 altool)"
        echo "  3. 填写应用信息、截图"
        echo "  4. 提交审核"
        echo ""
        echo "  上传命令:"
        echo "  xcrun altool --upload-app -f CherryReader-$VERSION-ios-app-store.ipa -t ios -u YOUR_APPLE_ID"
    fi
}

# 主流程
main() {
    print_header
    check_prerequisites

    # 创建输出目录
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"

    # 更新 .env
    echo "# Auto generated by build script" > "$PROJECT_DIR/.env"
    echo "APP_VERSION=$VERSION" >> "$PROJECT_DIR/.env"

    # 获取依赖
    echo -e "\n${YELLOW}[准备] 获取依赖...${NC}"
    cd "$PROJECT_DIR"
    flutter pub get

    # 更新 Android Gradle 配置
    setup_android_gradle

    # 构建
    case $PLATFORM in
        android)
            build_android
            ;;
        ios)
            build_ios
            ;;
        all)
            build_android
            if [[ "$OSTYPE" == "darwin"* ]]; then
                build_ios
            else
                echo -e "${YELLOW}跳过 iOS 构建 (非 macOS 系统)${NC}"
            fi
            ;;
        *)
            echo -e "${RED}未知平台: $PLATFORM${NC}"
            echo "支持的平台: android, ios, all"
            exit 1
            ;;
    esac

    print_summary
}

# 运行
main "$@"
