/// 更新信息模型
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final int fileSize;
  final String? sha256;
  final String releaseNotes;
  final bool forceUpdate;

  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    this.fileSize = 0,
    this.sha256,
    this.releaseNotes = '',
    this.forceUpdate = false,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String? ?? '0.0.0',
      downloadUrl: json['download_url'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? 0,
      sha256: json['sha256'] as String?,
      releaseNotes: json['release_notes'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
    );
  }

  /// 文件大小格式化
  String get fileSizeText {
    if (fileSize <= 0) return '';
    final mb = fileSize / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// 更新检查结果
sealed class UpdateCheckResult {}

/// 有新版本可用
class UpdateAvailable extends UpdateCheckResult {
  final UpdateInfo info;
  UpdateAvailable(this.info);
}

/// 已是最新版本
class UpdateNotNeeded extends UpdateCheckResult {}

/// 检查失败
class UpdateCheckFailed extends UpdateCheckResult {
  final String error;
  UpdateCheckFailed(this.error);
}
