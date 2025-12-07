class TtsSettings {
  // 向后兼容：保留单个 azureApiKey，但优先使用 azureApiKeys 列表
  String azureApiKey;
  
  // 新增：多个 API Keys 支持
  List<String> azureApiKeys;
  int currentKeyIndex;
  
  String azureRegion;
  String defaultVoiceName;
  // 新增：保存语音的本地显示名称，用于在未加载列表时显示
  String defaultVoiceLocalName;
  
  // 新增：收藏的语音列表（按用户自定义顺序）
  List<String> favoriteVoices;
  
  double defaultRate;
  double defaultPitch;

  // SSML 增强选项
  bool enableSsmlEnhancement; // 启用 Markdown→SSML 转换（更自然但可能稍慢）
  String ssmlConfigType; // 'default', 'natural', 'audiobook'

  // 全局节奏控制 (0.5 ~ 2.0, 1.0 为正常)
  double rhythmScale;

  // 音频格式（已简化，只使用 MP3）
  String audioFormat; // 保留字段以向后兼容，实际固定为 'mp3'

  TtsSettings({
    this.azureApiKey = '',
    List<String>? azureApiKeys,
    this.currentKeyIndex = 0,
    this.azureRegion = 'eastus',
    this.defaultVoiceName = 'zh-CN-XiaoxiaoNeural',
    this.defaultVoiceLocalName = '',
    List<String>? favoriteVoices,
    this.defaultRate = 1.0,
    this.defaultPitch = 1.0,
    this.enableSsmlEnhancement = true, // 默认开启
    this.ssmlConfigType = 'natural', // 默认使用自然配置
    this.rhythmScale = 1.0, // 默认正常节奏
    this.audioFormat = 'mp3', // 固定使用 MP3
  }) : azureApiKeys = azureApiKeys ?? [],
       favoriteVoices = favoriteVoices ?? [];

  Map<String, dynamic> toJson() {
    return {
      'azureApiKey': azureApiKey, // 保留以向后兼容
      'azureApiKeys': azureApiKeys,
      'currentKeyIndex': currentKeyIndex,
      'azureRegion': azureRegion,
      'defaultVoiceName': defaultVoiceName,
      'defaultVoiceLocalName': defaultVoiceLocalName,
      'favoriteVoices': favoriteVoices,
      'defaultRate': defaultRate,
      'defaultPitch': defaultPitch,
      'enableSsmlEnhancement': enableSsmlEnhancement,
      'ssmlConfigType': ssmlConfigType,
      'rhythmScale': rhythmScale,
      'audioFormat': audioFormat,
    };
  }

  factory TtsSettings.fromJson(Map<String, dynamic> json) {
    // 向后兼容：如果存在旧的单个 key 但没有 keys 列表，则迁移
    final String oldKey = json['azureApiKey']?.toString() ?? '';
    final List<String> keysList = json['azureApiKeys'] != null 
        ? List<String>.from(json['azureApiKeys'])
        : (oldKey.isNotEmpty ? [oldKey] : <String>[]);
    
    return TtsSettings(
      azureApiKey: oldKey,
      azureApiKeys: keysList,
      currentKeyIndex: json['currentKeyIndex'] ?? 0,
      azureRegion: json['azureRegion'] ?? 'eastus',
      defaultVoiceName: json['defaultVoiceName'] ?? 'zh-CN-XiaoxiaoNeural',
      defaultVoiceLocalName: json['defaultVoiceLocalName'] ?? '',
      favoriteVoices: json['favoriteVoices'] != null
          ? List<String>.from(json['favoriteVoices'])
          : <String>[],
      defaultRate: (json['defaultRate'] as num?)?.toDouble() ?? 1.0,
      defaultPitch: (json['defaultPitch'] as num?)?.toDouble() ?? 1.0,
      enableSsmlEnhancement: json['enableSsmlEnhancement'] ?? true,
      ssmlConfigType: json['ssmlConfigType'] ?? 'natural',
      rhythmScale: (json['rhythmScale'] as num?)?.toDouble() ?? 1.0,
      audioFormat: json['audioFormat'] ?? 'auto',
    );
  }
  
  /// 获取当前使用的 API Key
  String? getCurrentKey() {
    if (azureApiKeys.isEmpty) return null;
    if (currentKeyIndex < 0 || currentKeyIndex >= azureApiKeys.length) {
      currentKeyIndex = 0;
    }
    return azureApiKeys[currentKeyIndex];
  }
  
  /// 切换到下一个 Key（用于失败重试）
  bool switchToNextKey() {
    if (azureApiKeys.length <= 1) return false;
    currentKeyIndex = (currentKeyIndex + 1) % azureApiKeys.length;
    return true;
  }
  
  static const String prefKey = 'tts_settings';
}
