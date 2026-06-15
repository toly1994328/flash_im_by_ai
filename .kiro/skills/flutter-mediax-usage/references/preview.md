```dart
import 'package:flutter/material.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';
import 'package:tolyui_mediax_ui/tolyui_mediax_ui.dart';

/// 打开全屏预览
void openPreview(BuildContext context, List<MediaMeta> items, int index) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      pageBuilder: (_, __, ___) => MediaPreviewPage(
        items: items,
        initialIndex: index,
        config: const PreviewConfig(
          dragDismissEnabled: true,
          maxScale: 4.0,
          videoAutoPlay: true,
        ),
        onDismiss: () => Navigator.of(context).pop(),
        onPageChanged: (int page) => debugPrint('当前页: $page'),
        itemBuilder: (BuildContext context, int i, MediaMeta meta) {
          return switch (meta) {
            ImageMeta() => ImageViewer(
                meta: meta,
                heroTag: meta.heroTag,
                mediaBuilder: (BuildContext ctx, MediaMeta m) {
                  // 通过 Resolver 渲染图片
                  final MediaSourceResolver resolver =
                      MediaSourceProvider.of(ctx);
                  return resolver.resolve(ctx, m as ImageMeta,
                      level: MediaSourceLevel.source);
                },
              ),
            VideoMeta() => VideoViewer(
                meta: meta,
                autoPlay: i == index,
                heroTag: meta.heroTag,
              ),
          };
        },
      ),
      transitionsBuilder: (_, Animation<double> anim, __, Widget child) {
        return FadeTransition(opacity: anim, child: child);
      },
    ),
  );
}

/// 带下拉关闭的预览（DragDismissWrapper 包裹）
void openPreviewWithDragDismiss(
    BuildContext context, List<MediaMeta> items, int index) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      pageBuilder: (_, __, ___) => DragDismissWrapper(
        threshold: 100,
        onDismiss: () => Navigator.of(context).pop(),
        onDragProgress: (double progress) {
          // 可联动背景透明度
        },
        child: MediaPreviewPage(
          items: items,
          initialIndex: index,
          onDismiss: () => Navigator.of(context).pop(),
          itemBuilder: (BuildContext context, int i, MediaMeta meta) {
            return switch (meta) {
              ImageMeta() => ImageViewer(
                  meta: meta,
                  heroTag: meta.heroTag,
                  mediaBuilder: (BuildContext ctx, MediaMeta m) {
                    final MediaSourceResolver resolver =
                        MediaSourceProvider.of(ctx);
                    return resolver.resolve(ctx, m as ImageMeta);
                  },
                ),
              VideoMeta() => VideoViewer(meta: meta, autoPlay: i == index),
            };
          },
        ),
      ),
      transitionsBuilder: (_, Animation<double> anim, __, Widget child) {
        return FadeTransition(opacity: anim, child: child);
      },
    ),
  );
}
```
