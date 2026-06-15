import 'dart:convert';
import 'dart:io';

import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';

import 'message.dart';

/// Message → ImageMeta 转换
extension MessageMediaExt on Message {
  ImageMeta toImageMeta({required String baseUrl}) {
    final String thumbnailUrl = extra?['thumbnail_url'] as String? ?? content;
    final String sourceUrl = content;

    final int width = (extra?['width'] as num?)?.toInt() ?? 0;
    final int height = (extra?['height'] as num?)?.toInt() ?? 0;

    // 有本地文件就直接用，跳过网络
    final String? localPath = _localFilePath;
    final bool hasLocal = localPath != null && File(localPath).existsSync();

    final MediaSource source = hasLocal
        ? FileSource(localPath)
        : NetworkSource(Uri.parse(_fullUrl(sourceUrl, baseUrl)));

    final MediaSource thumbnail = hasLocal
        ? FileSource(localPath)
        : NetworkSource(Uri.parse(_fullUrl(thumbnailUrl, baseUrl)));

    return ImageMeta(
      source: source,
      thumbnail: thumbnail,
      heroTag: 'img_$id',
      originalSize: (width > 0 && height > 0) ? (width: width, height: height) : null,
    );
  }

  /// 从 localData JSON 提取本地路径
  String? get _localFilePath {
    if (localData == null) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(localData!) as Map<String, dynamic>;
      return json['path'] as String?;
    } catch (_) {
      return null;
    }
  }

  static String _fullUrl(String url, String baseUrl) =>
      (baseUrl.isNotEmpty && url.startsWith('/')) ? '$baseUrl$url' : url;
}
