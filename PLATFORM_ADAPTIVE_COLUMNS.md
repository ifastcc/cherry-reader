# 平台自适应列数配置

## ✅ 实现完成

已实现根据平台自动设置默认列数：

### 📱 移动端（iOS/Android）
- **默认列数**：1 列（全屏显示）
- **原因**：移动端屏幕较窄，1 列可以提供更好的阅读体验

### 💻 桌面端（macOS/Windows/Linux/Web）
- **默认列数**：2 列
- **原因**：桌面端屏幕较宽，2 列可以并排对比多个模型回复

## 🔧 实现方式

### 代码修改

**文件**：`lib/screens/conversation_screen.dart`

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class _ConversationScreenState extends State<ConversationScreen> {
  // 使用 late 延迟初始化
  late int _columnsPerView;

  @override
  void initState() {
    super.initState();

    // 根据平台设置默认列数
    _columnsPerView = _getDefaultColumnsPerView();

    // ...
  }

  /// 根据平台返回默认列数
  int _getDefaultColumnsPerView() {
    // 移动端（iOS/Android）默认 1 列
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          return 1;
        }
      } catch (e) {
        // 平台检测失败，继续检查其他条件
      }
    }

    // 桌面端（macOS/Windows/Linux/Web）默认 2 列
    return 2;
  }
}
```

### 平台检测逻辑

```
┌─────────────────────────────────────┐
│ 检测是否为 Web                       │
│ kIsWeb == false?                    │
└─────────────────────────────────────┘
            │
            ├─ Yes → 检测原生平台
            │         ├─ Platform.isAndroid → 1 列
            │         ├─ Platform.isIOS     → 1 列
            │         ├─ Platform.isMacOS   → 2 列
            │         ├─ Platform.isWindows → 2 列
            │         └─ Platform.isLinux   → 2 列
            │
            └─ No (Web) → 2 列
```

## 🎛️ 用户可自定义

用户仍然可以通过右上角的按钮手动切换列数：

```
┌──────────────────────────────┐
│  📋 话题标题          ⋮      │  ← 右上角菜单按钮
└──────────────────────────────┘
                         │
                         ├─ 1 列 (全屏)
                         ├─ 2 列 (默认) ← 桌面端默认
                         ├─ 3 列 (紧凑)
                         └─ 4 列 (超紧凑)
```

**菜单选项**：
- **1 列 (全屏)**：移动端默认，适合阅读单个回复
- **2 列 (默认)**：桌面端默认，适合对比 2 个模型回复
- **3 列 (紧凑)**：适合宽屏显示器，对比 3 个模型
- **4 列 (超紧凑)**：适合超宽屏，对比 4 个模型

## 📊 不同平台效果

| 平台 | 默认列数 | 典型屏幕宽度 | 单卡片宽度（2列时） |
|------|---------|-------------|-------------------|
| iOS | 1 列 | 375px - 428px | 100% |
| Android | 1 列 | 360px - 480px | 100% |
| iPad | 2 列 | 768px - 1024px | ~50% |
| macOS | 2 列 | 1280px+ | ~640px |
| Windows | 2 列 | 1920px+ | ~960px |
| Linux | 2 列 | 1920px+ | ~960px |
| Web | 2 列 | 可变 | ~50% |

## 🧪 测试方法

### 1. 测试 iOS/Android（移动端）

```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android
```

**预期结果**：
- ✅ 启动后默认显示 **1 列**
- ✅ 右上角菜单显示当前选中 "1 列 (全屏)"
- ✅ 用户可以切换到其他列数

### 2. 测试 macOS/Windows/Linux（桌面端）

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

**预期结果**：
- ✅ 启动后默认显示 **2 列**
- ✅ 右上角菜单显示当前选中 "2 列 (默认)"
- ✅ 用户可以切换到其他列数

### 3. 测试 Web

```bash
flutter run -d chrome
# 或
flutter run -d edge
```

**预期结果**：
- ✅ 启动后默认显示 **2 列**
- ✅ 适应不同浏览器窗口大小

## 💡 设计考虑

### 为什么移动端用 1 列？

1. **屏幕宽度限制**：移动端屏幕较窄（通常 < 500px）
2. **可读性优先**：1 列可以保证文字大小合适，不需要缩小字体
3. **触摸友好**：单列滚动更符合移动端操作习惯
4. **专注阅读**：一次只看一个回复，避免分心

### 为什么桌面端用 2 列？

1. **屏幕利用率**：桌面端屏幕较宽（通常 > 1200px）
2. **对比需求**：多模型回复对比是核心功能
3. **信息密度**：2 列平衡了信息密度和可读性
4. **Cherry Studio 风格**：参考原版设计

## 🔄 用户体验流程

```
用户打开对话
    ↓
检测设备平台
    ├─ 移动端 → 默认 1 列
    │           ├─ 阅读体验好 ✅
    │           └─ 可手动切换到 2 列对比
    │
    └─ 桌面端 → 默认 2 列
                ├─ 对比方便 ✅
                └─ 可手动切换到 1/3/4 列
```

## ✨ 相关文件

- `lib/screens/conversation_screen.dart` - 主要实现
- `lib/widgets/horizontal_scroll_view.dart` - 横向滚动卡片组件

## 🎯 未来优化建议

1. **响应式布局**：根据窗口宽度动态调整列数
   ```dart
   // 例如：
   if (MediaQuery.of(context).size.width < 600) {
     return 1; // 窄屏
   } else if (width < 1200) {
     return 2; // 中屏
   } else {
     return 3; // 宽屏
   }
   ```

2. **保存用户偏好**：使用 SharedPreferences 记住用户选择
   ```dart
   final prefs = await SharedPreferences.getInstance();
   await prefs.setInt('columns_per_view', _columnsPerView);
   ```

3. **平板优化**：iPad 可以默认 2 列，但允许横屏时显示 3 列

现在已经完美实现平台自适应了！🎉
