import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';
import 'package:tolyui_mediax_image/tolyui_mediax_image.dart';

import '../../data/message.dart';
import 'bubble_size.dart';

class VideoBubble extends StatelessWidget {
  final Message message;
  final String? baseUrl;
  final double? uploadProgress;
  final VoidCallback? onTap;
  final String? localThumbnailPath;

  const VideoBubble({
    super.key,
    required this.message,
    this.baseUrl,
    this.uploadProgress,
    this.onTap,
    this.localThumbnailPath,
  });

  String _fullUrl(String url) =>
      (baseUrl != null && url.startsWith('/')) ? '$baseUrl$url' : url;

  @override
  Widget build(BuildContext context) {
    final VideoExtra? videoExtra = message.videoExtra;
    final bool isUploading = uploadProgress != null && uploadProgress! < 1.0
        && message.status == MessageStatus.sending;

    final (:double width, :double height, :bool crop) = BubbleSize.calc(
      (videoExtra?.width ?? 0).toDouble(),
      (videoExtra?.height ?? 0).toDouble(),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x1A000000), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildThumbnail(videoExtra, width, height),
              if (!isUploading)
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                ),
              if (videoExtra != null && !isUploading)
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                      ),
                    ),
                    alignment: Alignment.bottomRight,
                    padding: const EdgeInsets.only(right: 6, bottom: 4),
                    child: Text(
                      videoExtra.formattedDuration,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              if (isUploading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: SizedBox(
                        width: 36, height: 36,
                        child: CircularProgressIndicator(
                          value: uploadProgress, strokeWidth: 3, color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(VideoExtra? videoExtra, double width, double height) {
    // 本地缩略图优先
    if (localThumbnailPath != null && File(localThumbnailPath!).existsSync()) {
      return Image.file(
        File(localThumbnailPath!),
        width: width, height: height, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(width, height),
      );
    }

    // 网络缩略图用 MediaImageView（有缓存）
    final String thumbUrl = videoExtra?.thumbnailUrl ?? '';
    if (thumbUrl.isNotEmpty) {
      final ImageMeta meta = ImageMeta(
        source: NetworkSource(Uri.parse(_fullUrl(thumbUrl))),
        thumbnail: NetworkSource(Uri.parse(_fullUrl(thumbUrl))),
      );
      return SizedBox(
        width: width, height: height,
        child: MediaImageView(meta: meta, level: MediaSourceLevel.source, fit: BoxFit.cover),
      );
    }

    return _placeholder(width, height);
  }

  Widget _placeholder(double width, double height) => Container(
    width: width, height: height,
    color: Colors.grey[200],
    child: const Center(child: Icon(Icons.videocam, size: 48, color: Colors.grey)),
  );
}
