/// 下载函数签名，由调用方注入（解耦 dio）
typedef DownloadFunction = Future<void> Function(
  String url,
  String savePath, {
  void Function(double progress)? onProgress,
});

/// 文件类型分类
enum FileCategory { image, video, audio, file }

/// 文件缓存管理器抽象接口
///
/// 下载队列 + 并发控制 + URL 去重 + 本地路径持久化。
/// 实现类：FileCacheManagerImpl（原生平台）、NoOpFileCacheManager（Web 平台）。
abstract class FileCacheManager {
  /// 获取文件本地路径。
  /// 已缓存且文件存在 → 直接返回路径；否则排入下载队列。
  /// [onProgress] 下载进度回调 0.0~1.0
  Future<String> getFile({
    required String url,
    required String messageId,
    required FileCategory category,
    String? fileName,
    void Function(double)? onProgress,
  });

  /// 直接写入 localData（发送场景：文件已在本地，无需下载）
  Future<void> markLocal({
    required String messageId,
    required String localPath,
  });

  /// 手动清除某消息的本地缓存
  Future<void> clearCache(String messageId);

  /// 释放资源
  void dispose();
}
