# Flutter 相关
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Isar 数据库
-keep class dev.isar.** { *; }
-keep class * extends dev.isar.** { *; }

# JSON 序列化
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# 保留模型类（防止混淆导致 JSON 解析失败）
-keep class com.example.cherry_reader.** { *; }

# 保留 native 方法
-keepclasseswithmembernames class * {
    native <methods>;
}
