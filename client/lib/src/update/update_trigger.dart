import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fx_install_android/fx_install_android.dart';
import 'package:fx_updater/fx_updater.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// 闪讯更新触发器
///
/// 负责：获取本地版本 → 调后端接口 → 弹窗 → 执行平台升级策略
class UpdateTrigger {
  final Dio _dio;
  final String appId;

  /// 各商店链接（跳转场景使用）
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.toly1994.flash_im';
  static const String _appStoreUrl =
      'https://apps.apple.com/app/id6772819751';
  static const String _macAppStoreUrl =
      'https://apps.apple.com/app/id6772819751';

  UpdateTrigger({required Dio dio, this.appId = '1'}) : _dio = dio;

  /// 检查更新并在有新版本时弹窗
  Future<void> checkAndPrompt(BuildContext context) async {
    if (kIsWeb) return; // Web 端无需检测

    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final UpdateCheckResult result = await FxUpdater().check(
      packageInfo.version,
      _fetchFromServer,
    );
    if (result is UpdateAvailable && context.mounted) {
      UpdateDialog.show(
        context,
        info: result.info,
        onUpdate: () => executeUpdate(result.info),
        onDismiss: () {},
        downloadHandler: shouldDownload()
            ? (onProgress) => downloadFile(result.info, onProgress)
            : null,
        installHandler: (filePath) => installFile(filePath),
      );
    }
  }

  bool shouldDownload() {
    if (Platform.isAndroid && AppChannel.isGoogle) return false;
    return Platform.isAndroid || Platform.isWindows || Platform.isLinux;
  }

  /// 执行更新（非下载场景：跳转对应平台商店）
  Future<void> executeUpdate(UpdateInfo info) async {
    final String storeUrl = _getStoreUrl();
    if (storeUrl.isNotEmpty) {
      final Uri uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// 获取当前平台对应的商店链接
  String _getStoreUrl() {
    if (Platform.isIOS) return _appStoreUrl;
    if (Platform.isMacOS) return _macAppStoreUrl;
    if (Platform.isAndroid && AppChannel.isGoogle) return _playStoreUrl;
    return '';
  }

  /// 下载文件到临时目录，返回本地路径
  Future<String> downloadFile(
    UpdateInfo info,
    void Function(double) onProgress,
  ) async {
    final Uri uri = Uri.parse(info.downloadUrl);
    final String fileName = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'update.apk';
    final Directory tempDir = await getTemporaryDirectory();
    final String savePath = '${tempDir.path}/$fileName';

    debugPrint('[UpdateTrigger] downloading: ${info.downloadUrl}');
    debugPrint('[UpdateTrigger] savePath: $savePath');

    await _dio.download(
      info.downloadUrl,
      savePath,
      options: Options(headers: {'Accept-Encoding': 'identity'}),
      onReceiveProgress: (int received, int total) {
        final int expectedTotal = total > 0 ? total : info.fileSize;
        debugPrint(
          '[UpdateTrigger] onReceiveProgress: received=$received, total=$total, expectedTotal=$expectedTotal',
        );
        if (expectedTotal > 0) {
          final double p = (received / expectedTotal).clamp(0.0, 1.0);
          debugPrint(
            '[UpdateTrigger] progress: ${(p * 100).toStringAsFixed(1)}%',
          );
          onProgress(p);
          FxUpdater().reportProgress(p);
        }
      },
    );

    // SHA256 校验（流式读取，避免大文件一次性加载到内存）
    if (info.sha256 != null && info.sha256!.isNotEmpty) {
      debugPrint('[UpdateTrigger] verifying SHA256...');
      final File file = File(savePath);
      final Digest fileDigest = await sha256.bind(file.openRead()).first;
      final String fileHash = fileDigest.toString();
      if (fileHash != info.sha256) {
        await file.delete();
        throw Exception('SHA256 校验失败：期望 ${info.sha256}，实际 $fileHash');
      }
      debugPrint('[UpdateTrigger] SHA256 verified OK');
    }

    debugPrint('[UpdateTrigger] download complete: $savePath');
    FxUpdater().reportDownloaded(savePath);
    return savePath;
  }

  /// 安装本地文件
  Future<void> installFile(String filePath) async {
    debugPrint('[UpdateTrigger] installing: $filePath');
    if (Platform.isAndroid) {
      await FxInstall.apk(filePath);
    } else {
      final Uri fileUri = Uri.file(filePath);
      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri);
      }
    }
  }

  /// 从后端获取更新信息
  Future<UpdateInfo?> _fetchFromServer() async {
    try {
      final response = await _dio.get(
        '/api/app/version',
        queryParameters: {
          'app_id': appId,
          'platform': Platform.operatingSystem,
        },
      );
      if (response.statusCode == 200) {
        return UpdateInfo.fromJson(response.data);
      }
      return null;
    } catch (_) {
      return null; // 静默失败
    }
  }

}
