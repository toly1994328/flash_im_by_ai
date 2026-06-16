```dart
import 'package:flutter/material.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';
import 'package:tolyui_mediax_image/tolyui_mediax_image.dart';

/// 单张图片展示（自动使用注入的 Resolver）
class PhotoCard extends StatelessWidget {
  final ImageMeta meta;
  const PhotoCard({super.key, required this.meta});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: MediaImageView(
        meta: meta,
        level: MediaSourceLevel.thumbnail,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      ),
    );
  }
}

/// 带 Hero 的图片 tile（用于九宫格）
class PhotoGrid extends StatelessWidget {
  final List<ImageMeta> items;
  const PhotoGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final ImageMeta meta = items[index];
        return GestureDetector(
          onTap: () => _openPreview(context, items, index),
          child: Hero(
            tag: meta.heroTag ?? index,
            child: MediaImageView(
              meta: meta,
              level: MediaSourceLevel.thumbnail,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  void _openPreview(BuildContext context, List<ImageMeta> items, int index) {
    // 跳转到预览页（见 preview.md）
  }
}
```
