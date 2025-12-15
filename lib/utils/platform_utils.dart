import 'dart:io';
import 'package:flutter/foundation.dart';

/// 平台工具类
///
/// 提供跨平台判断功能，用于根据平台显示/隐藏特定功能
class PlatformUtils {
  PlatformUtils._();

  /// 是否为桌面平台 (macOS, Windows, Linux)
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// 是否为移动平台 (iOS, Android)
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// 是否为 Web 平台
  static bool get isWeb => kIsWeb;

  /// 是否为 macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// 是否为 Windows
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// 是否为 Linux
  static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  /// 是否为 iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// 是否为 Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// 是否支持本地文件夹监听同步（仅桌面端支持）
  static bool get supportsLocalFolderSync => isDesktop;

  /// 获取平台名称
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Unknown';
  }
}
