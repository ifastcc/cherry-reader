#!/bin/bash
# 安装/卸载 git pre-commit hook
# 用法:
#   ./scripts/install-hooks.sh install [--quick]  安装 hook
#   ./scripts/install-hooks.sh uninstall          卸载 hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
HOOK_FILE="$PROJECT_DIR/.git/hooks/pre-commit"

case "$1" in
    install)
        QUICK_FLAG=""
        if [[ "$2" == "--quick" ]]; then
            QUICK_FLAG=" --quick"
            echo "安装 pre-commit hook (快速模式)..."
        else
            echo "安装 pre-commit hook (完整构建模式)..."
        fi

        cat > "$HOOK_FILE" << EOF
#!/bin/bash
# Auto-generated pre-commit hook
# 跳过 hook: git commit --no-verify

echo "运行提交前测试..."
"$SCRIPT_DIR/pre-commit-test.sh"$QUICK_FLAG

if [ \$? -ne 0 ]; then
    echo "测试失败，提交已取消"
    echo "使用 git commit --no-verify 跳过测试"
    exit 1
fi
EOF
        chmod +x "$HOOK_FILE"
        echo "✓ Hook 已安装: $HOOK_FILE"
        echo ""
        echo "提示:"
        echo "  - 每次 git commit 前会自动运行测试"
        echo "  - 使用 git commit --no-verify 跳过测试"
        echo "  - 使用 ./scripts/install-hooks.sh uninstall 卸载"
        ;;

    uninstall)
        if [ -f "$HOOK_FILE" ]; then
            rm "$HOOK_FILE"
            echo "✓ Hook 已卸载"
        else
            echo "Hook 不存在"
        fi
        ;;

    *)
        echo "用法:"
        echo "  $0 install          安装 hook (完整构建)"
        echo "  $0 install --quick  安装 hook (快速模式，只检查不构建)"
        echo "  $0 uninstall        卸载 hook"
        ;;
esac
