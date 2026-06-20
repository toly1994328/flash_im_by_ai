import 'fx_download_event.dart';

/// 下载管理抽象接口
abstract class FxMediaDownload {
  /// 流式下载（带进度事件）
  Stream<FxDownloadEvent> stream({required String url, String? id, String? fileName});

  /// 便捷获取（只等最终路径）
  Future<String> get({required String url, String? id, String? fileName});

  /// 是否已缓存
  bool isCached(String id);

  /// 获取本地路径（未缓存返回 null）
  String? localPath(String id);

  /// 移除缓存（删文件 + 清记录）
  Future<void> remove(String id);

  /// 取消下载
  void cancel(String id);
}
