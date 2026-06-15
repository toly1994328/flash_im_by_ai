import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/file.dart' as file_pkg;
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';

/// 持久化缓存管理器（Application Support 目录，不被系统清理）
class PersistentCacheManager extends CacheManager with ImageCacheManager {
  static const String _key = 'mediaxPersistentCache';
  static PersistentCacheManager? _instance;

  factory PersistentCacheManager() => _instance ??= PersistentCacheManager._();

  PersistentCacheManager._()
      : super(Config(
          _key,
          stalePeriod: const Duration(days: 365),
          maxNrOfCacheObjects: 1000,
          fileSystem: _AppSupportFileSystem(_key),
        ));
}

class _AppSupportFileSystem implements FileSystem {
  final Future<String> _dirPath;

  _AppSupportFileSystem(String cacheKey)
      : _dirPath = _resolvePath(cacheKey);

  static Future<String> _resolvePath(String key) async {
    final dir = await getApplicationSupportDirectory();
    final String path = p.join(dir.path, key);
    const LocalFileSystem fs = LocalFileSystem();
    await fs.directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<file_pkg.File> createFile(String name) async {
    final String dirPath = await _dirPath;
    const LocalFileSystem fs = LocalFileSystem();
    return fs.file(p.join(dirPath, name));
  }
}

/// 基于 cached_network_image 的 MediaSourceResolver 实现
class AppMediaSourceResolver extends DefaultMediaSourceResolver {
  const AppMediaSourceResolver();

  @override
  Widget resolveNetwork(
    BuildContext context,
    Uri uri, {
    Map<String, String>? headers,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    MediaSource? placeholder,
    MediaSourceLevel level = MediaSourceLevel.source,
  }) {
    return CachedNetworkImage(
      imageUrl: uri.toString(),
      httpHeaders: headers,
      cacheManager: PersistentCacheManager(),
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, _) => _buildPlaceholder(context, placeholder, fit),
      errorWidget: (_, _, _) => _buildError(),
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
    );
  }

  Widget _buildPlaceholder(BuildContext context, MediaSource? placeholder, BoxFit fit) {
    if (placeholder != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _resolveLocalOrShimmer(context, placeholder, fit),
          const Center(
            child: SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
            ),
          ),
        ],
      );
    }
    return _buildShimmer(context);
  }

  Widget _resolveLocalOrShimmer(BuildContext context, MediaSource source, BoxFit fit) {
    return switch (source) {
      NetworkSource(:final uri, :final headers) => CachedNetworkImage(
          imageUrl: uri.toString(),
          httpHeaders: headers,
          cacheManager: PersistentCacheManager(),
          fit: fit,
          placeholder: (_, _) => _buildShimmer(context),
          errorWidget: (_, _, _) => _buildShimmer(context),
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
        ),
      _ => _buildShimmer(context),
    };
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.grey[300]),
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.grey[100],
      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 32)),
    );
  }
}
