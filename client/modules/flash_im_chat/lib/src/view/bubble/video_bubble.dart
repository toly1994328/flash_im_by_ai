import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/message.dart';

class VideoBubble extends StatelessWidget {
  final Message message;
  final String? baseUrl;
  final double? uploadProgress;
  final VoidCallback? onTap;

  const VideoBubble({
    super.key,
    required this.message,
    this.baseUrl,
    this.uploadProgress,
    this.onTap,
  });

  String _fullUrl(String url) =>
      (baseUrl != null && url.startsWith('/')) ? '$baseUrl$url' : url;

  @override
  Widget build(BuildContext context) {
    final videoExtra = message.videoExtra;
    final thumbUrl = videoExtra?.thumbnailUrl ?? '';
    final isUploading = uploadProgress != null && uploadProgress! < 1.0
        && message.status == MessageStatus.sending;

    final rawW = (videoExtra?.width ?? 0).toDouble();
    final rawH = (videoExtra?.height ?? 0).toDouble();
    double placeholderW = 200, placeholderH = 150;
    if (rawW > 0 && rawH > 0) {
      const maxW = 250.0, maxH = 300.0;
      final s = (rawW / maxW > rawH / maxH) ? (maxW / rawW) : (maxH / rawH);
      final finalScale = s > 1.0 ? 1.0 : s;
      placeholderW = rawW * finalScale;
      placeholderH = rawH * finalScale;
    }

    Widget videoPlaceholder() => Container(
      width: placeholderW, height: placeholderH,
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.videocam, size: 48, color: Colors.grey)));

    final isLocalThumb = !message.content.startsWith('http')
        && !message.content.startsWith('/uploads');

    Widget thumbWidget;
    if (isLocalThumb) {
      thumbWidget = Image.file(File(message.content),
        width: placeholderW, height: placeholderH, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => videoPlaceholder());
    } else if (thumbUrl.isNotEmpty) {
      final fullThumbUrl = _fullUrl(thumbUrl);
      thumbWidget = Stack(children: [
        videoPlaceholder(),
        Positioned.fill(child: Image.network(fullThumbUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => videoPlaceholder())),
      ]);
    } else {
      thumbWidget = videoPlaceholder();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: placeholderW, height: placeholderH,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDEE0E2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              thumbWidget,
              if (!isUploading)
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 28)),
              if (videoExtra != null && !isUploading)
                Positioned(left: 0, right: 0, bottom: 0,
                  child: Container(height: 32,
                    decoration: BoxDecoration(gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)])),
                    alignment: Alignment.bottomRight,
                    padding: const EdgeInsets.only(right: 6, bottom: 4),
                    child: Text(videoExtra.formattedDuration,
                      style: const TextStyle(color: Colors.white, fontSize: 12)))),
              if (isUploading) Positioned.fill(child: _uploadOverlay()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadOverlay() => Container(
    color: Colors.black.withValues(alpha: 0.3),
    child: Center(child: SizedBox(width: 36, height: 36,
      child: CircularProgressIndicator(value: uploadProgress, strokeWidth: 3, color: Colors.white))),
  );
}
