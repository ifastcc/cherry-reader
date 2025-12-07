/// 工具方法：规范化 OpenAI 兼容的 API Host。
///
/// 这是对 Cherry Studio 中 formatApiHost/hasAPIVersion 的精简 Dart 版本，
/// 方便在本项目中直接复用 Cherry Studio 导出的 Provider 配置。

/// 去除首尾空白
String _trim(String? value) => value?.trim() ?? '';

/// 去掉结尾的 `/`
String _withoutTrailingSlash(String url) {
  if (url.endsWith('/')) {
    return url.substring(0, url.length - 1);
  }
  return url;
}

/// 判断 host 的路径中是否已经包含形如 `/v1`、`/v2beta` 的版本段。
///
/// 对应 Cherry Studio 中的 hasAPIVersion，实现保持一致：
/// - 匹配 `/v<number>`，可选跟随 `alpha` / `beta`
/// - 版本段后面可以是 `/` 或路径结束
bool hasApiVersion(String host) {
  if (host.isEmpty) return false;

  final versionRegex = RegExp(r'/v\d+(?:alpha|beta)?(?=/|$)', caseSensitive: false);

  try {
    final uri = Uri.parse(host);
    return versionRegex.hasMatch(uri.path);
  } catch (_) {
    // 如果不是完整 URL，当作路径直接检测
    return versionRegex.hasMatch(host);
  }
}

/// 规范化 OpenAI 兼容的 API Host，返回用于拼接 `/chat/completions` 的 base URL。
///
/// 规则：
/// - 去除首尾空白、末尾 `/`
/// - 如果为空，返回空字符串
/// - 如果以 `#` 结尾，认为是带端点标记的特殊写法，原样返回
/// - 如果已包含版本段（如 `/v1`、`/v2beta`），原样返回（仅去掉末尾 `/`）
/// - 否则自动追加 `/v1`
String formatOpenAIApiHost(
  String? host, {
  bool isSupportedApiVersion = true,
  String apiVersion = 'v1',
}) {
  final normalizedHost = _withoutTrailingSlash(_trim(host));
  if (normalizedHost.isEmpty) {
    return '';
  }

  if (normalizedHost.endsWith('#') || !isSupportedApiVersion || hasApiVersion(normalizedHost)) {
    return normalizedHost;
  }

  return '$normalizedHost/$apiVersion';
}

