import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class LanHttpSyncConfig {
  static const int defaultPort = 9531;
  static const String _prefsKey = 'lan_http_sync_config_v1';

  final bool enabled;
  final bool autoStart;
  final int port;
  final String token;

  const LanHttpSyncConfig({
    required this.enabled,
    required this.autoStart,
    required this.port,
    required this.token,
  });

  factory LanHttpSyncConfig.defaults() => LanHttpSyncConfig(
        enabled: false,
        autoStart: false,
        port: defaultPort,
        token: generateToken(),
      );

  LanHttpSyncConfig copyWith({
    bool? enabled,
    bool? autoStart,
    int? port,
    String? token,
  }) {
    return LanHttpSyncConfig(
      enabled: enabled ?? this.enabled,
      autoStart: autoStart ?? this.autoStart,
      port: port ?? this.port,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'autoStart': autoStart,
        'port': port,
        'token': token,
      };

  factory LanHttpSyncConfig.fromJson(Map<String, dynamic> json) {
    return LanHttpSyncConfig(
      enabled: json['enabled'] == true,
      autoStart: json['autoStart'] == true,
      port: (json['port'] is int)
          ? json['port'] as int
          : int.tryParse(json['port']?.toString() ?? '') ?? defaultPort,
      token: json['token']?.toString() ?? generateToken(),
    );
  }

  static Future<LanHttpSyncConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      final cfg = LanHttpSyncConfig.defaults();
      await cfg.save();
      return cfg;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final cfg = LanHttpSyncConfig.fromJson(decoded);
        if (cfg.token.isEmpty) {
          final next = cfg.copyWith(token: generateToken());
          await next.save();
          return next;
        }
        return cfg;
      }
    } catch (_) {}
    final cfg = LanHttpSyncConfig.defaults();
    await cfg.save();
    return cfg;
  }

  static String generateToken() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    final b = StringBuffer();
    for (var i = 0; i < 32; i++) {
      b.write(alphabet[r.nextInt(alphabet.length)]);
    }
    return b.toString();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(toJson()));
  }
}
