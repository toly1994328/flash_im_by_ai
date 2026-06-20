import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';
import 'package:tolyui_mediax_image/tolyui_mediax_image.dart';

import '../../data/message.dart';
import '../../logic/chat_state.dart';
import 'bubble_size.dart';

class VideoBubble extends StatelessWidget {
  final Message message;
  final String? baseUrl;
  final double? uploadProgress;
  final FileDownloadInfo? downloadInfo;
  final VoidCallback? onTap;
  final String? localThumbnailPath;

  const VideoBubble({
    super.key,
    required this.message,
    this.baseUrl,
    this.uploadProgress,
    this.downloadInfo,
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
    final bool isDownloading = downloadInfo?.status == FileDownloadStatus.downloading;

    final (:double width, :double height, :bool crop) = BubbleSize.calc(
      (videoExtra?.width ?? 0).toDouble(),
      (videoExtra?.height ?? 0).toDouble(),
    );

    // 判断视频是否已下载到本地
    final bool isCached = _hasLocalVideo();

    return GestureDetector(
      onTap: (isDownloading || isUploading) ? null : onTap,
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
              // 中央图标：播放/下载
              if (!isUploading && !isDownloading)
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCached ? Icons.play_arrow : Icons.download_rounded,
                    color: Colors.white,
                    size: isCached ? 22 : 18,
                  ),
                ),
              // 底部时长条
              if (videoExtra != null && !isUploading && !isDownloading)
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
              // 上传进度遮罩
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
              // 下载进度遮罩（微信风格：半透明黑底 + 圆形进度）
              if (isDownloading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: Center(
                      child: SizedBox(
                        width: 40, height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: downloadInfo!.progress > 0 ? downloadInfo!.progress : null,
                              strokeWidth: 3,
                              color: Colors.white,
                              backgroundColor: Colors.white24,
                            ),
                            Text(
                              '${(downloadInfo!.progress * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ],
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
    // 本地缩略图优先（已缓存的）
    if (localThumbnailPath != null && File(localThumbnailPath!).existsSync()) {
      return Image.file(
        File(localThumbnailPath!),
        width: width, height: height, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(width, height),
      );
    }

    // 发送中：content 是缩略图本地路径
    if (message.status == MessageStatus.sending) {
      final String thumbPath = message.content;
      if (File(thumbPath).existsSync()) {
        return Image.file(
          File(thumbPath),
          width: width, height: height, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(width, height),
        );
      }
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

  bool _hasLocalVideo() {
    if (message.localData == null) return false;
    try {
      final Map<String, dynamic> json = jsonDecode(message.localData!) as Map<String, dynamic>;
      final String? path = json['path'] as String?;
      return path != null && File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}
