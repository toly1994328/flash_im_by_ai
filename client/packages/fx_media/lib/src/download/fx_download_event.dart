/// 下载事件模型（sealed class）
sealed class FxDownloadEvent {
  final String id;
  final String url;
  const FxDownloadEvent({required this.id, required this.url});
}

/// 下载进度事件
class FxDownloadProgress extends FxDownloadEvent {
  final double progress;
  const FxDownloadProgress({
    required super.id,
    required super.url,
    required this.progress,
  });
}

/// 下载完成事件
class FxDownloadComplete extends FxDownloadEvent {
  final String localPath;
  const FxDownloadComplete({
    required super.id,
    required super.url,
    required this.localPath,
  });
}

/// 下载错误事件
class FxDownloadError extends FxDownloadEvent {
  final Object error;
  const FxDownloadError({
    required super.id,
    required super.url,
    required this.error,
  });
}
