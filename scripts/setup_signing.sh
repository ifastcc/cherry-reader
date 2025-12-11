#!/bin/bash
# Android 签名配置向导
# 用法: ./scripts/setup_signing.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Android 签名配置向导${NC}"
echo -e "${BLUE}======================================${NC}"

# 检查是否已有配置
KEY_PROPS="$PROJECT_DIR/android/key.properties"
if [ -f "$KEY_PROPS" ]; then
    echo -e "\n${YELLOW}已存在签名配置: $KEY_PROPS${NC}"
    cat "$KEY_PROPS"
    echo ""
    read -p "是否重新配置? (y/N): " reconfigure
    if [[ "$reconfigure" != "y" && "$reconfigure" != "Y" ]]; then
        exit 0
    fi
fi

echo -e "\n${YELLOW}步骤 1: 创建密钥库${NC}"
echo ""

# 密钥库路径
DEFAULT_KEYSTORE="$HOME/cherry-reader-release.jks"
read -p "密钥库保存路径 [$DEFAULT_KEYSTORE]: " KEYSTORE_PATH
KEYSTORE_PATH=${KEYSTORE_PATH:-$DEFAULT_KEYSTORE}

# 检查是否已存在
if [ -f "$KEYSTORE_PATH" ]; then
    echo -e "${YELLOW}密钥库已存在: $KEYSTORE_PATH${NC}"
    read -p "是否使用现有密钥库? (Y/n): " use_existing
    if [[ "$use_existing" == "n" || "$use_existing" == "N" ]]; then
        read -p "新密钥库路径: " KEYSTORE_PATH
    else
        CREATE_NEW=false
    fi
fi

# 密钥别名
read -p "密钥别名 [cherry_reader]: " KEY_ALIAS
KEY_ALIAS=${KEY_ALIAS:-cherry_reader}

# 密码
echo ""
echo -e "${YELLOW}设置密码 (建议使用强密码)${NC}"
read -s -p "密钥库密码: " STORE_PASSWORD
echo ""
read -s -p "确认密钥库密码: " STORE_PASSWORD_CONFIRM
echo ""

if [ "$STORE_PASSWORD" != "$STORE_PASSWORD_CONFIRM" ]; then
    echo -e "${RED}密码不匹配！${NC}"
    exit 1
fi

read -s -p "密钥密码 (可与密钥库密码相同): " KEY_PASSWORD
echo ""
KEY_PASSWORD=${KEY_PASSWORD:-$STORE_PASSWORD}

# 创建新密钥库
if [ "${CREATE_NEW:-true}" == "true" ] && [ ! -f "$KEYSTORE_PATH" ]; then
    echo -e "\n${YELLOW}步骤 2: 填写证书信息${NC}"
    echo "(这些信息会显示在 APK 签名中)"
    echo ""

    read -p "您的姓名: " CN
    read -p "组织单位 [Development]: " OU
    OU=${OU:-Development}
    read -p "组织名称: " O
    read -p "城市: " L
    read -p "省份: " ST
    read -p "国家代码 [CN]: " C
    C=${C:-CN}

    DNAME="CN=$CN, OU=$OU, O=$O, L=$L, ST=$ST, C=$C"

    echo -e "\n${YELLOW}创建密钥库...${NC}"
    keytool -genkey -v \
        -keystore "$KEYSTORE_PATH" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -alias "$KEY_ALIAS" \
        -storepass "$STORE_PASSWORD" \
        -keypass "$KEY_PASSWORD" \
        -dname "$DNAME"

    echo -e "${GREEN}✓ 密钥库创建成功: $KEYSTORE_PATH${NC}"
fi

# 创建 key.properties
echo -e "\n${YELLOW}步骤 3: 创建配置文件${NC}"

cat > "$KEY_PROPS" << EOF
# Android 签名配置
# 警告: 请勿将此文件提交到版本控制!
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=$KEYSTORE_PATH
EOF

echo -e "${GREEN}✓ 配置文件创建成功: $KEY_PROPS${NC}"

# 确保 .gitignore 包含 key.properties
GITIGNORE="$PROJECT_DIR/android/.gitignore"
if ! grep -q "key.properties" "$GITIGNORE" 2>/dev/null; then
    echo "key.properties" >> "$GITIGNORE"
    echo -e "${GREEN}✓ 已添加 key.properties 到 .gitignore${NC}"
fi

# 验证配置
echo -e "\n${YELLOW}步骤 4: 验证配置${NC}"
if keytool -list -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 密钥库验证成功${NC}"

    echo -e "\n密钥信息:"
    keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" 2>/dev/null | grep -E "(别名|创建日期|有效期|SHA256)"
else
    echo -e "${RED}✗ 密钥库验证失败${NC}"
    exit 1
fi

# 备份提醒
echo -e "\n${BLUE}======================================${NC}"
echo -e "${BLUE}  重要提醒${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${RED}请立即备份以下文件到安全位置:${NC}"
echo "  1. 密钥库: $KEYSTORE_PATH"
echo "  2. 配置文件: $KEY_PROPS"
echo "  3. 密码记录"
echo ""
echo -e "${YELLOW}丢失密钥库将无法更新已发布的应用！${NC}"
echo ""
echo -e "${GREEN}配置完成！现在可以运行:${NC}"
echo "  ./scripts/build_china.sh 1.0.0"
