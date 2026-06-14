import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;

/// 下载进度回调
typedef OnProgressChange = void Function(double progress);

/// 更新策略接口
///
/// 每个平台一个实现，核心方法是 [update]。
abstract class UpdateStrategy {
  Future<void> update(String url, OnProgressChange onProgress);
}

/// 下载 Mixin：复用下载逻辑
///
/// 需要外部注入 downloadFile 的具体实现（传入 Dio 实例）。
/// fx_updater 包不依赖 dio，通过回调注入。
typedef DownloadFileHandler = Future<String> Function(
  String url,
  String savePath,
  OnProgressChange onProgress,
);

/// Android 策略：下载 + 安装 APK
class AndroidUpdateStrategy implements UpdateStrategy {
  final DownloadFileHandler downloadFile;
  final Future<void> Function(String filePath) installApk;

  AndroidUpdateStrategy({
    required this.downloadFile,
    required this.installApk,
  });

  @override
  Future<void> update(String url, OnProgressChange onProgress) async {
    final Directory dir = await getTemporaryDirectory();
    final String savePath = p.join(dir.path, p.basename(Uri.parse(url).path));
    debugPrint('[AndroidStrategy] downloading to: $savePath');
    final String filePath = await downloadFile(url, savePath, onProgress);
    onProgress(1.0);
    debugPrint('[AndroidStrategy] installing: $filePath');
    await installApk(filePath);
  }
}

/// 桌面策略（Windows/Linux）：下载 + 打开文件
class DesktopUpdateStrategy implements UpdateStrategy {
  final DownloadFileHandler downloadFile;

  DesktopUpdateStrategy({required this.downloadFile});

  @override
  Future<void> update(String url, OnProgressChange onProgress) async {
    final Directory dir = await getTemporaryDirectory();
    final String savePath = p.join(dir.path, p.basename(Uri.parse(url).path));
    debugPrint('[DesktopStrategy] downloading to: $savePath');
    final String filePath = await downloadFile(url, savePath, onProgress);
    onProgress(1.0);
    debugPrint('[DesktopStrategy] opening: $filePath');
    final Uri fileUri = Uri.file(filePath);
    await launchUrl(fileUri);
  }
}

/// macOS 策略：跳转浏览器下载
class MacOSUpdateStrategy implements UpdateStrategy {
  @override
  Future<void> update(String url, OnProgressChange onProgress) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// URL 跳转策略（iOS / 鸿蒙）
class UrlLaunchStrategy implements UpdateStrategy {
  @override
  Future<void> update(String url, OnProgressChange onProgress) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// 空策略（Web）
class NoOpStrategy implements UpdateStrategy {
  @override
  Future<void> update(String url, OnProgressChange onProgress) async {}
}
