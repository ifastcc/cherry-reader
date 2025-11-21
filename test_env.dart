import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 测试环境变量加载
/// 运行方式：dart test_env.dart
void main() async {
  print('=' * 60);
  print('✅ Flutter 环境变量加载测试');
  print('=' * 60);

  try {
    // 加载 .env 文件
    await dotenv.load(fileName: ".env");
    print('✅ .env 文件加载成功\n');

    // 读取配置
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '未设置';
    final baseUrl = dotenv.env['OPENAI_BASE_URL'] ?? '未设置';
    final model = dotenv.env['OPENAI_MODEL'] ?? '未设置';

    print('配置信息:');
    print('─' * 60);
    print('OPENAI_API_KEY: ${apiKey.length > 20 ? "${apiKey.substring(0, 20)}..." : apiKey}');
    print('OPENAI_BASE_URL: $baseUrl');
    print('OPENAI_MODEL: $model');
    print('─' * 60);

    // 验证必需配置
    if (apiKey == '未设置' || apiKey.isEmpty) {
      print('\n❌ 错误：OPENAI_API_KEY 未配置');
      print('   请在 .env 文件中设置 API Key');
      return;
    }

    print('\n✅ 所有配置正确！');
    print('   应用将使用: $baseUrl');
    print('   模型: $model');
  } catch (e) {
    print('❌ 加载失败: $e');
    print('\n请确保:');
    print('1. .env 文件存在于项目根目录');
    print('2. .env 文件格式正确');
    print('3. pubspec.yaml 已添加 flutter_dotenv 依赖');
  }
}
