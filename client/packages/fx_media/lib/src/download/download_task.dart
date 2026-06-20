import 'dart:async';

import 'fx_download_event.dart';

/// 内部下载任务模型（不导出）
class DownloadTask {
  final String id;
  final String url;
  final String? fileName;
  final String savePath;
  final StreamController<FxDownloadEvent> controller;
  bool cancelled = false;

  DownloadTask({
    required this.id,
    required this.url,
    this.fileName,
    required this.savePath,
    required this.controller,
  });
}
