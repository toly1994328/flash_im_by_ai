import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fx_updater/fx_updater.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 闪讯更新触发器
///
/// 负责：获取本地版本 → 调后端接口 → 弹窗 → 执行平台升级策略
class UpdateTrigger {
  final Dio _dio;
  final String appId;

  UpdateTrigger({required Dio dio, this.appId = '1'}) : _dio = dio;

  /// 检查更新并在有新版本时弹窗
  Future<void> checkAndPrompt(BuildContext context) async {
    if (kIsWeb) return; // Web 端无需检测

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = AppVersion.parse(packageInfo.version);

    final checker = UpdateChecker(
      currentVersion: currentVersion,
      fetchUpdateInfo: () => _fetchFromServer(),
    );

    final result = await checker.check();

    if (result is UpdateAvailable && context.mounted) {
      UpdateDialog.show(
        context,
        info: result.info,
        onUpdate: () => _getStrategy().execute(result.info),
      );
    }
  }

  /// 从后端获取更新信息
  Future<UpdateInfo?> _fetchFromServer() async {
    try {
      final platform = _getPlatform();
      final response = await _dio.get(
        '/api/app/version',
        queryParameters: {'app_id': appId, 'platform': platform},
      );
      if (response.statusCode == 200) {
        return UpdateInfo.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null; // 静默失败
    }
  }

  /// 获取当前平台标识
  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// 根据平台选择升级策略
  UpdateStrategy _getStrategy() {
    if (Platform.isIOS) return UrlLaunchStrategy();
    if (Platform.isAndroid || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return _DownloadInstallStrategy(dio: _dio);
    }
    return UrlLaunchStrategy(); // 鸿蒙等：跳转市场
  }
}

/// 下载安装策略（Android/桌面端）
///
/// 下载安装包到临时目录，然后调起系统安装器或打开文件。
class _DownloadInstallStrategy implements UpdateStrategy {
  final Dio dio;

  _DownloadInstallStrategy({required this.dio});

  @override
  Future<void> execute(UpdateInfo info) async {
    try {
      // 从 URL 提取文件名
      final uri = Uri.parse(info.downloadUrl);
      final fileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'update_${info.version}.apk';

      // 保存到临时目录
      final tempDir = Directory.systemTemp;
      final savePath = '${tempDir.path}/$fileName';

      // 下载
      await dio.download(info.downloadUrl, savePath);

      // 打开文件（系统安装器）
      final fileUri = Uri.file(savePath);
      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri);
      }
    } catch (e) {
      debugPrint('[UpdateTrigger] download failed: $e');
    }
  }
}
