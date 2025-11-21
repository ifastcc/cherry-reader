# Flutter 版本环境变量配置指南

## ✅ 已完成配置

Flutter 项目已经配置好从 `.env` 文件读取 OpenAI API 配置。

### 📁 配置文件

**`.env`** (已创建)
```bash
OPENAI_API_KEY=sk-HCMnot0pRajeYAVVT3bGbTKI4uNztvBgD8g58FfXUsuC3wRH
OPENAI_BASE_URL=https://chat01.ai
OPENAI_MODEL=gpt-5-1-thinking
```

**`.env.example`** (模板文件)
```bash
OPENAI_API_KEY=your_api_key_here
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4
```

## 🔧 代码修改

### 1. `pubspec.yaml` - 添加依赖

```yaml
dependencies:
  flutter_dotenv: ^5.1.0

flutter:
  assets:
    - .env
```

### 2. `lib/main.dart` - 加载环境变量

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载环境变量
  await dotenv.load(fileName: ".env");

  await AnalysisCacheManager().init();
  runApp(const CherryViewerApp());
}
```

### 3. `lib/screens/conversation_screen.dart` - 使用环境变量

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

@override
void initState() {
  super.initState();
  _openaiService = OpenAIService(
    apiKey: _getApiKey(),
    baseUrl: _getBaseUrl(),
  );
}

String _getApiKey() {
  return dotenv.env['OPENAI_API_KEY'] ?? '';
}

String _getBaseUrl() {
  return dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
}
```

### 4. `.gitignore` - 保护敏感信息

```
# Environment variables (contains sensitive API keys)
.env
```

## 🚀 使用方法

### 1. 安装依赖

```bash
cd flutter_viewer
flutter pub get
```

### 2. 运行应用

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux

# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android
```

### 3. 验证配置

应用启动时会自动：
1. 加载 `.env` 文件
2. 读取 `OPENAI_API_KEY`、`OPENAI_BASE_URL`、`OPENAI_MODEL`
3. 使用这些配置初始化 OpenAI 服务

## 🔍 配置验证

应用会使用你配置的：
- **API Key**: `sk-HCMnot0pRajeYAVVT...`
- **Base URL**: `https://chat01.ai` ✅ (不再使用官方地址)
- **Model**: `gpt-5-1-thinking`

## ⚠️ 重要提示

1. **不要提交 `.env` 文件到 Git**
   - 已添加到 `.gitignore`
   - 包含敏感的 API Key

2. **修改配置后需重启应用**
   - `.env` 在启动时加载
   - 修改后需要完全重启

3. **团队协作**
   - 复制 `.env.example` 为 `.env`
   - 每个开发者使用自己的 API Key
   - 将 `.env.example` 提交到 Git

## 📝 与 Python 版本对比

| 特性 | Python MVP | Flutter 版本 |
|------|-----------|-------------|
| 环境变量加载 | `python-dotenv` | `flutter_dotenv` |
| 配置文件 | `.env` | `.env` |
| API Key 读取 | `os.getenv()` | `dotenv.env[]` |
| Base URL 支持 | ✅ | ✅ |
| 模型配置 | ✅ | ✅ |

两个版本现在使用相同的 `.env` 配置方式！
