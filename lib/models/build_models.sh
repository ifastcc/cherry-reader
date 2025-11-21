#!/bin/bash
# JSON 序列化代码生成脚本

cd "$(dirname "$0")/../.."

echo "🔨 正在生成 JSON 序列化代码..."
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

echo "✅ 生成完成！"
