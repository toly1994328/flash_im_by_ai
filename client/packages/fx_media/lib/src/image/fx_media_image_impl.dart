import 'package:flutter/material.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';
import 'package:tolyui_mediax_ui/tolyui_mediax_ui.dart';

import 'fx_cached_image.dart';
import 'fx_media_image.dart';

/// FxMediaImage 实现
class FxMediaImageImpl implements FxMediaImage {
  @override
  void preview(
    BuildContext context, {
    required List<ImageMeta> items,
    int initialIndex = 0,
    VoidCallback? onDismiss,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (BuildContext _, Animation<double> __, Animation<double> ___) => MediaPreviewPage(
          items: items,
          initialIndex: initialIndex,
          onDismiss: onDismiss ?? () => Navigator.of(context).pop(),
          itemBuilder: (BuildContext ctx, int i, MediaMeta item) {
            final ImageMeta imageMeta = item as ImageMeta;
            return ImageViewer(
              heroTag: imageMeta.heroTag ?? imageMeta.hashCode,
              mediaBuilder: (BuildContext _, MediaMeta meta) => MediaImageView(
                meta: meta as ImageMeta,
                level: MediaSourceLevel.source,
                fit: BoxFit.contain,
              ),
              meta: imageMeta,
              imageSize: imageMeta.originalSize != null
                  ? Size(
                      imageMeta.originalSize!.width.toDouble(),
                      imageMeta.originalSize!.height.toDouble(),
                    )
                  : null,
            );
          },
        ),
        transitionsBuilder: (BuildContext _, Animation<double> anim, Animation<double> __, Widget child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget cached({
    required String url,
    String? id,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Map<String, String>? headers,
    void Function(String localPath)? onCached,
  }) {
    return FxCachedImage(
      url: url,
      id: id,
      fit: fit,
      width: width,
      height: height,
      headers: headers,
      onCached: onCached,
    );
  }
}
