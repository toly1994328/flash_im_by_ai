import 'dart:io';
import 'package:flash_shared/flash_shared.dart';
import 'package:flutter/material.dart';
import '../data/message.dart';
import '../logic/chat_state.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onImageTap;
  final VoidCallback? onVideoTap;
  final VoidCallback? onFileTap;
  final String? baseUrl;
  final double? uploadProgress;
  final FileDownloadInfo? fileDownloadInfo;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onImageTap,
    this.onVideoTap,
    this.onFileTap,
    this.baseUrl,
    this.uploadProgress,
    this.fileDownloadInfo,
  });

  String _fullUrl(String url) =>
      (baseUrl != null && url.startsWith('/')) ? '$baseUrl$url' : url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) AvatarWidget(avatar: message.senderAvatar, size: 32, borderRadius: 4),
          if (!isMe) const SizedBox(width: 8),
          Flexible(child: _buildContent()),
          if (isMe) const SizedBox(width: 8),
          if (isMe) AvatarWidget(avatar: message.senderAvatar, size: 32, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isMe && message.senderName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 2),
            child: Text(message.senderName,
              style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isMe) _buildStatusIcon(),
            if (isMe) const SizedBox(width: 4),
            Flexible(child: _buildBubble()),
          ],
        ),
      ],
    );
  }

  Widget _buildBubble() {
    if (message.isImage) return _buildImageContent();
    if (message.isVideo) return _buildVideoContent();
    if (message.isFile) return _buildFileContent();
    return _buildTextBubble();
  }

  Widget _buildTextBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF3B82F6) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isMe ? 12 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 12),
        ),
      ),
      child: Text(message.content,
        style: TextStyle(fontSize: 15, color: isMe ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildImageContent() {
    final url = message.content;
    final isLocal = !url.startsWith('http') && !url.startsWith('/uploads');
    final isUploading = uploadProgress != null && uploadProgress! < 1.0 && message.status == MessageStatus.sending;

    // 从 extra 取宽高，计算等比占位尺寸（限制在 maxWidth 250, maxHeight 300 内）
    final rawW = (message.extra?['width'] as num?)?.toDouble();
    final rawH = (message.extra?['height'] as num?)?.toDouble();
    double? placeholderW, placeholderH;
    if (rawW != null && rawH != null && rawW > 0 && rawH > 0) {
      const maxW = 250.0, maxH = 300.0;
      final scale = (rawW / maxW).clamp(0.0, double.infinity);
      final scaleH = (rawH / maxH).clamp(0.0, double.infinity);
      final s = scale > scaleH ? (maxW / rawW) : (maxH / rawH);
      final finalScale = s > 1.0 ? 1.0 : s;
      placeholderW = rawW * finalScale;
      placeholderH = rawH * finalScale;
    }

    Widget placeholder({bool loading = false}) {
      return Container(
        width: placeholderW ?? 200,
        height: placeholderH ?? 150,
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
      // 用 Stack 叠加：底层占位 + 上层网络图片，避免加载前尺寸为 0 的闪烁
      imageWidget = Stack(
        children: [
          placeholder(loading: true),
          Positioned.fill(
            child: Image.network(imageUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder()),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: isLocal ? null : onImageTap,
      child: Container(
        width: placeholderW,
        height: placeholderH,
        constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDEE0E2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              imageWidget,
              if (isUploading) Positioned.fill(child: _buildUploadOverlay()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    final videoExtra = message.videoExtra;
    final thumbUrl = videoExtra?.thumbnailUrl ?? '';
    final isUploading = uploadProgress != null && uploadProgress! < 1.0 && message.status == MessageStatus.sending;

    // 从 extra 取宽高，计算等比占位尺寸
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

    Widget videoPlaceholder() => Container(width: placeholderW, height: placeholderH,
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.videocam, size: 48, color: Colors.grey)));

    // 缩略图：本地路径用 Image.file，服务端路径用 Image.network
    final isLocalThumb = !message.content.startsWith('http')
        && !message.content.startsWith('/uploads');

    Widget thumbWidget;
    if (isLocalThumb) {
      thumbWidget = Image.file(File(message.content), width: placeholderW, height: placeholderH, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => videoPlaceholder());
    } else if (thumbUrl.isNotEmpty) {
      final fullThumbUrl = _fullUrl(thumbUrl);
      thumbWidget = Stack(
        children: [
          videoPlaceholder(),
          Positioned.fill(
            child: Image.network(fullThumbUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => videoPlaceholder()),
          ),
        ],
      );
    } else {
      thumbWidget = videoPlaceholder();
    }

    return GestureDetector(
      onTap: onVideoTap,
      child: Container(
        width: placeholderW,
        height: placeholderH,
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
              if (isUploading) Positioned.fill(child: _buildUploadOverlay()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileContent() {
    final fileExtra = message.fileExtra;
    final fileName = fileExtra?.fileName ?? message.content;
    final fileType = fileExtra?.fileType ?? '';
    final formattedSize = fileExtra?.formattedSize ?? '';
    final isUploading = uploadProgress != null && uploadProgress! < 1.0 && message.status == MessageStatus.sending;
    final dlInfo = fileDownloadInfo;

    // 自己发的消息不显示未下载灰色状态
    final isIdle = !isMe && (dlInfo == null || dlInfo.status == FileDownloadStatus.idle);
    final isDone = dlInfo != null && dlInfo.status == FileDownloadStatus.done;
    final isDownloading = dlInfo != null && dlInfo.status == FileDownloadStatus.downloading;

    final nameColor = isIdle ? const Color(0xFF999999) : const Color(0xFF333333);
    final bgColor = isIdle ? const Color(0xFFF5F5F5) : Colors.white;

    return GestureDetector(
      onTap: onFileTap,
      child: Container(
        width: 237,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDEE0E2), width: 0.5),
        ),
        child: Stack(
          children: [
            // 上传进度背景填充
            if (isUploading)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: uploadProgress ?? 0,
                  child: Container(color: const Color(0xFF3B82F6).withValues(alpha: 0.1)),
                ),
              ),
            // 下载进度背景填充
            if (isDownloading)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: dlInfo!.progress,
                  child: Container(color: const Color(0xFF3B82F6).withValues(alpha: 0.1)),
                ),
              ),
            // 内容
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: nameColor)),
                        if (formattedSize.isNotEmpty)
                          Padding(padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Text(formattedSize,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                                if (isDone) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                                ],
                              ],
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildFileIcon(fileType),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(String fileType) {
    final (IconData icon, Color color) = switch (fileType.toLowerCase()) {
      'pdf' => (Icons.picture_as_pdf, Colors.red),
      'doc' || 'docx' => (Icons.description, Colors.blue),
      'xls' || 'xlsx' || 'csv' => (Icons.table_chart, Colors.green),
      'ppt' || 'pptx' => (Icons.slideshow, Colors.orange),
      'zip' || 'rar' || '7z' => (Icons.folder_zip, Colors.amber),
      'txt' || 'md' => (Icons.article, Colors.blueGrey),
      _ => (Icons.insert_drive_file, Colors.grey),
    };
    return Container(width: 40, height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 24));
  }

  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: SizedBox(width: 36, height: 36,
          child: CircularProgressIndicator(
            value: uploadProgress,
            strokeWidth: 3,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return switch (message.status) {
      MessageStatus.sending => const Padding(padding: EdgeInsets.only(top: 2),
        child: SizedBox(width: 12, height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5))),
      MessageStatus.failed => const Padding(padding: EdgeInsets.only(top: 2),
        child: Icon(Icons.error_outline, color: Colors.red, size: 14)),
      _ => const SizedBox.shrink(),
    };
  }
}
