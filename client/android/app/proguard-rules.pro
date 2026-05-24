## Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

## Dart 原生通道
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

## WebView（webview_flutter 插件）
-keep class android.webkit.** { *; }
-keep class io.flutter.plugins.webviewflutter.** { *; }

## SharedPreferences 插件
-keep class io.flutter.plugins.sharedpreferences.** { *; }

## SQLite 相关（drift/sqlite3）
-keep class io.requery.android.database.** { *; }
-dontwarn io.requery.android.database.**

## 保留注解
-keepattributes *Annotation*

## 保留枚举
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

## 保留 Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
