import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/message.dart';

class ImageBubble extends StatelessWidget {
  final Message message;
  final String? baseUrl;
  final double? uploadProgress;
  final VoidCallback? onTap;

  const ImageBubble({
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
    final url = message.content;
    final isLocal = !url.startsWith('http') && !url.startsWith('/uploads');
    final isUploading = uploadProgress != null && uploadProgress! < 1.0
        && message.status == MessageStatus.sending;

    final rawW = (message.extra?['width'] as num?)?.toDouble();
    final rawH = (message.extra?['height'] as num?)?.toDouble();
    double? placeholderW, placeholderH;
    if (rawW != null && rawH != null && rawW > 0 && rawH > 0) {
      const maxW = 250.0, maxH = 300.0;
      final s = (rawW / maxW > rawH / maxH) ? (maxW / rawW) : (maxH / rawH);
      final finalScale = s > 1.0 ? 1.0 : s;
      placeholderW = rawW * finalScale;
      placeholderH = rawH * finalScale;
    }

    Widget placeholder({bool loading = false}) {
      return Container(
        width: placeholderW ?? 200, height: placeholderH ?? 150,
        color: Colors.grey[100],
        child: Center(child: loading
          ? const SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey))
          : const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32)),
      );
    }

    Widget imageWidget;
    if (isLocal) {
      imageWidget = Image.file(File(url), fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder());
    } else {
      final imageUrl = _fullUrl(url);
      imageWidget = Stack(children: [
        placeholder(loading: true),
        Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder())),
      ]);
    }

    return GestureDetector(
      onTap: isLocal ? null : onTap,
      child: Container(
        width: placeholderW, height: placeholderH,
        constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDEE0E2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(children: [
            imageWidget,
            if (isUploading) Positioned.fill(child: _uploadOverlay()),
          ]),
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
