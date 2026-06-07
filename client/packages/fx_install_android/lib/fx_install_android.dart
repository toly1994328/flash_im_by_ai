import 'package:flutter/services.dart';

/// Android APK 安装结果
class InstallResult {
  final bool isSuccess;
  final String errorMessage;

  const InstallResult({required this.isSuccess, this.errorMessage = ''});

  factory InstallResult.fromMap(Map<dynamic, dynamic> map) {
    return InstallResult(
      isSuccess: map['isSuccess'] as bool? ?? false,
      errorMessage: map['errorMessage'] as String? ?? '',
    );
  }

  @override
  String toString() => 'InstallResult(isSuccess: $isSuccess, errorMessage: $errorMessage)';
}

/// Android APK 安装 Plugin
///
/// 功能：
/// - 自动检测安装权限，无权限时跳转系统设置页请求
/// - 通过自带的 FileProvider 生成 content:// URI，调起系统安装器
/// - 返回安装结果（成功/取消/权限拒绝）
/// - 兼容 Android 6.0+
///
/// 使用方需在 AndroidManifest.xml 中声明 REQUEST_INSTALL_PACKAGES 权限。
class FxInstall {
  static const MethodChannel _channel = MethodChannel('fx_install_android');

  /// 安装指定路径的 APK 文件
  ///
  /// [filePath] 本地 APK 文件绝对路径
  /// 返回 [InstallResult]，包含安装是否成功及错误信息
  static Future<InstallResult> apk(String filePath) async {
    final dynamic result = await _channel.invokeMethod('installApk', {'filePath': filePath});
    if (result is Map) {
      return InstallResult.fromMap(result);
    }
    return const InstallResult(isSuccess: false, errorMessage: 'Unexpected result');
  }
}
