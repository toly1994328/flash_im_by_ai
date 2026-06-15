import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';

import 'message.dart';

/// Message → ImageMeta 转换
extension MessageMediaExt on Message {
  ImageMeta toImageMeta({required String baseUrl}) {
    final String thumbnailUrl = extra?['thumbnail_url'] as String? ?? content;
    final String sourceUrl = content;

    final int width = (extra?['width'] as num?)?.toInt() ?? 0;
    final int height = (extra?['height'] as num?)?.toInt() ?? 0;

    return ImageMeta(
      source: NetworkSource(Uri.parse(_fullUrl(sourceUrl, baseUrl))),
      thumbnail: NetworkSource(Uri.parse(_fullUrl(thumbnailUrl, baseUrl))),
      heroTag: 'img_$id',
      originalSize: (width > 0 && height > 0) ? (width: width, height: height) : null,
    );
  }

  static String _fullUrl(String url, String baseUrl) =>
      (baseUrl.isNotEmpty && url.startsWith('/')) ? '$baseUrl$url' : url;
}
