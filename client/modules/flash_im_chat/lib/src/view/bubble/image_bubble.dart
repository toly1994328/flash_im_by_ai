import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';
import 'package:tolyui_mediax_image/tolyui_mediax_image.dart';

import '../../data/message.dart';
import '../../data/message_media_ext.dart';
import 'bubble_size.dart';

/// 图片消息气泡
class ImageBubble extends StatelessWidget {
  final Message message;
  final String? baseUrl;
  final double? uploadProgress;
  final VoidCallback? onTap;
  final String? localPath;

  const ImageBubble({
    super.key,
    required this.message,
    this.baseUrl,
    this.uploadProgress,
    this.onTap,
    this.localPath,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSending = message.status == MessageStatus.sending;

    // 发送中：本地文件预览 + 上传遮罩（不加 Hero）
    if (isSending) {
      return _buildLocalPreview();
    }

    // 已发送：MediaImageView + Hero
    final ImageMeta meta = message.toImageMeta(baseUrl: baseUrl ?? '');
    final (:double width, :double height, :bool crop) = BubbleSize.fromOriginalSize(meta.originalSize);

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: meta.heroTag ?? meta.hashCode,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: width,
            height: height,
            child: MediaImageView(
              meta: meta,
              level: MediaSourceLevel.thumbnail,
              fit: crop ? BoxFit.cover : BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalPreview() {
    final (:double width, :double height, :bool crop) = BubbleSize.calc(
      (message.extra?['width'] as num?)?.toDouble() ?? 0,
      (message.extra?['height'] as num?)?.toDouble() ?? 0,
    );
    final String url = localPath ?? message.content;
    final bool isUploading = uploadProgress != null && uploadProgress! < 1.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDEE0E2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(url), fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: Colors.grey[100])),
            if (isUploading)
              Container(
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
          ],
        ),
      ),
    );
  }
}
