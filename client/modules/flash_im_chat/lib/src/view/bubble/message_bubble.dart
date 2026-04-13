import 'package:flash_shared/flash_shared.dart';
import 'package:flutter/material.dart';
import '../../data/message.dart';
import '../../logic/chat_state.dart';
import 'text_bubble.dart';
import 'image_bubble.dart';
import 'video_bubble.dart';
import 'file_bubble.dart';

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

  @override
  Widget build(BuildContext context) {
    // 系统消息：居中灰色标签
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ),
        ),
      );
    }

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
    return switch (message.type) {
      MessageType.image => ImageBubble(
        message: message,
        baseUrl: baseUrl,
        uploadProgress: uploadProgress,
        onTap: onImageTap,
      ),
      MessageType.video => VideoBubble(
        message: message,
        baseUrl: baseUrl,
        uploadProgress: uploadProgress,
        onTap: onVideoTap,
      ),
      MessageType.file => FileBubble(
        message: message,
        isMe: isMe,
        uploadProgress: uploadProgress,
        downloadInfo: fileDownloadInfo,
        onTap: onFileTap,
      ),
      _ => TextBubble(message: message, isMe: isMe),
    };
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
