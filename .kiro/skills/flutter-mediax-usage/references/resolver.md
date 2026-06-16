```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';

/// 实现网络图片加载方案
class CachedMediaSourceResolver extends DefaultMediaSourceResolver {
  const CachedMediaSourceResolver();

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
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
    );
  }
}

/// 在 App 顶层注入
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaSourceProvider(
      resolver: const CachedMediaSourceResolver(),
      child: MaterialApp(
        home: const HomePage(),
      ),
    );
  }
}
```
