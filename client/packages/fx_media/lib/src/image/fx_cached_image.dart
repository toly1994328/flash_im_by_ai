import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 持久化缓存管理器（Application Support 目录，不被系统清理）
class _FxPersistentCacheManager extends CacheManager with ImageCacheManager {
  static const String _key = 'fxMediaImageCache';
  static _FxPersistentCacheManager? _instance;

  factory _FxPersistentCacheManager() => _instance ??= _FxPersistentCacheManager._();

  _FxPersistentCacheManager._()
      : super(Config(
          _key,
          stalePeriod: const Duration(days: 365),
          maxNrOfCacheObjects: 2000,
        ));
}

/// 带缓存路径回调的图片 Widget
///
/// 基于 CachedNetworkImage 渲染，加载完成后回调本地路径。
class FxCachedImage extends StatefulWidget {
  final String url;
  final String? id;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Map<String, String>? headers;
  final void Function(String localPath)? onCached;

  const FxCachedImage({
    super.key,
    required this.url,
    this.id,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.headers,
    this.onCached,
  });

  @override
  State<FxCachedImage> createState() => _FxCachedImageState();
}

class _FxCachedImageState extends State<FxCachedImage> {
  bool _hasCalled = false;

  @override
  void didUpdateWidget(FxCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _hasCalled = false;
    }
  }

  void _notifyCached() {
    if (_hasCalled || widget.onCached == null) return;
    _hasCalled = true;

    _FxPersistentCacheManager().getFileFromCache(widget.url).then((FileInfo? info) {
      if (info != null && mounted) {
        widget.onCached?.call(info.file.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: widget.url,
      httpHeaders: widget.headers,
      cacheManager: _FxPersistentCacheManager(),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      imageBuilder: (BuildContext context, ImageProvider imageProvider) {
        _notifyCached();
        return Image(
          image: imageProvider,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
        );
      },
      placeholder: (BuildContext _, String __) => _buildShimmer(),
      errorWidget: (BuildContext _, String __, Object ___) => _buildError(),
    );
  }

  Widget _buildShimmer() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[100],
      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 32)),
    );
  }
}
