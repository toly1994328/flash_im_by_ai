import 'dart:async';

import '../../fx_updater.dart';

/// 全局更新状态管理器（单例）
///
/// 持有最新的版本检测结果，通过 Stream 暴露给 UI 层。
/// 底部导航红点、设置页、关于页等通过 [stream] 或 [hasUpdate] 获取状态。
class FxUpdater {
  static final FxUpdater _instance = FxUpdater._();

  factory FxUpdater() => _instance;

  FxUpdater._();

  final StreamController<UpdateCheckResult> _controller =
      StreamController<UpdateCheckResult>.broadcast();

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  Future<UpdateCheckResult> check(
    String version,
    FetchUpdateInfo fetcher,
  ) async {
    final UpdateCheckResult result = await UpdateChecker(
      currentVersion: AppVersion.parse(version),
      fetchUpdateInfo: fetcher,
    ).check();
    currentVersion = version;
    report(result);
    return result;
  }

  /// 状态变更流
  Stream<UpdateCheckResult> get stream => _controller.stream;

  /// 下载进度流（0.0 ~ 1.0）
  Stream<double> get progressStream => _progressController.stream;
  double _progress = 0;

  double get progress => _progress;

  /// 最近一次检测结果
  UpdateCheckResult? _lastResult;

  UpdateCheckResult? get lastResult => _lastResult;

  /// 当前版本号（由 UpdateTrigger 在检测时设置）
  String currentVersion = '';

  /// 下载状态
  bool _isDownloading = false;

  bool get isDownloading => _isDownloading;
  bool _isDownloaded = false;

  bool get isDownloaded => _isDownloaded;
  String? _downloadedFilePath;

  String? get downloadedFilePath => _downloadedFilePath;

  /// 是否有可用更新
  bool get hasUpdate => _lastResult is UpdateAvailable;

  /// 获取更新信息（无更新时返回 null）
  UpdateInfo? get updateInfo => _lastResult is UpdateAvailable
      ? (_lastResult as UpdateAvailable).info
      : null;

  /// 报告检测结果（由 UpdateTrigger 调用）
  void report(UpdateCheckResult result) {
    _lastResult = result;
    _controller.add(result);
  }

  /// 报告下载进度
  void reportProgress(double value) {
    _progress = value;
    _isDownloading = true;
    _progressController.add(value);
  }

  /// 报告下载完成
  void reportDownloaded(String filePath) {
    _isDownloading = false;
    _isDownloaded = true;
    _downloadedFilePath = filePath;
    _progress = 1.0;
    _progressController.add(1.0);
  }

  /// 重置下载状态
  void resetDownload() {
    _isDownloading = false;
    _isDownloaded = false;
    _downloadedFilePath = null;
    _progress = 0;
  }

  /// 用户点击"稍后"后清除红点
  void dismiss() {
    _lastResult = UpdateNotNeeded();
    _controller.add(_lastResult!);
  }

  void dispose() {
    _controller.close();
    _progressController.close();
  }
}
