import 'file_cache_manager.dart';

/// Web 平台空实现，所有方法 no-op。
///
/// getFile 直接返回原始 URL，走浏览器自带缓存机制。
class NoOpFileCacheManager implements FileCacheManager {
  @override
  Future<String> getFile({
    required String url,
    required String messageId,
    required FileCategory category,
    String? fileName,
    void Function(double)? onProgress,
  }) async => url;

  @override
  Future<void> markLocal({
    required String messageId,
    required String localPath,
  }) async {}

  @override
  Future<void> clearCache(String messageId) async {}

  @override
  void dispose() {}
}
