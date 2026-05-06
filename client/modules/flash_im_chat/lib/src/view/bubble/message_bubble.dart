import 'package:flash_shared/flash_shared.dart';
import 'package:flutter/material.dart';
import '../../data/message.dart';
import '../../logic/chat_state.dart';
import 'text_bubble.dart';
import 'image_bubble.dart';
import 'video_bubble.dart';
import 'file_bubble.dart';
import 'reply_bubble.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onImageTap;
  final VoidCallback? onVideoTap;
  final VoidCallback? onFileTap;
  final String? baseUrl;
  final double? uploadProgress;
  final FileDownloadInfo? fileDownloadInfo;
  final int? peerReadSeq;
  final Map<String, int> membersReadSeq;
  final String? currentUserId;
  final bool isGroup;
  final VoidCallback? onReadCountTap;
  final void Function(BuildContext bubbleContext)? onLongPress;
  final bool isMultiSelect;
  final bool isSelected;
  final VoidCallback? onToggleSelect;
  final void Function(String content)? onReEdit;

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
    this.peerReadSeq,
    this.membersReadSeq = const {},
    this.currentUserId,
    this.isGroup = false,
    this.onReadCountTap,
    this.onLongPress,
    this.isMultiSelect = false,
    this.isSelected = false,
    this.onToggleSelect,
    this.onReEdit,
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

    // 已撤回消息：居中灰色标签
    if (message.isRecalled) {
      final originalContent = message.extra?['_original_content'] as String?;
      final showReEdit = isMe && originalContent != null && onReEdit != null;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.content,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
                if (showReEdit) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => onReEdit!(originalContent),
                    child: const Text(
                      '重新编辑',
                      style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                    ),
                  ),
                ],
              ],
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
            if (isMe && _shouldShowReadIndicator()) ...[
              const SizedBox(width: 4),
              _buildReadReceiptIndicator(),
            ],
            if (isMe) const SizedBox(width: 4),
            Flexible(child: Builder(
              builder: (bubbleCtx) => GestureDetector(
                onLongPressStart: onLongPress != null ? (_) => onLongPress!(bubbleCtx) : null,
                child: _buildBubble(),
              ),
            )),
          ],
        ),
      ],
    );
  }

  bool _shouldShowReadIndicator() {
    return message.status == MessageStatus.sent && message.seq > 0;
  }

  Widget _buildReadReceiptIndicator() {
    if (isGroup) {
      return _buildGroupReadIndicator();
    } else {
      return _buildPrivateReadIndicator();
    }
  }

  Widget _buildPrivateReadIndicator() {
    final isRead = (peerReadSeq ?? 0) >= message.seq;
    return isRead ? const _AllReadIcon() : const _UnreadCircle();
  }

  Widget _buildGroupReadIndicator() {
    final readCount = membersReadSeq.entries
        .where((e) => e.key != currentUserId && e.value >= message.seq)
        .length;
    final totalMembers = membersReadSeq.entries
        .where((e) => e.key != currentUserId)
        .length;

    if (totalMembers > 0 && readCount >= totalMembers) {
      return const _AllReadIcon();
    }
    if (readCount == 0) {
      return const _UnreadCircle();
    }
    return GestureDetector(
      onTap: onReadCountTap,
      child: _ReadCountCircle(count: readCount),
    );
  }

  Widget _buildBubble() {
    // 引用气泡
    final replyTo = message.extra?['reply_to'] as Map<String, dynamic>?;
    Widget? replyWidget;
    if (replyTo != null) {
      replyWidget = ReplyBubble(
        senderName: replyTo['sender_name'] as String? ?? '?',
        content: replyTo['content'] as String? ?? '',
        msgType: replyTo['msg_type'] as int? ?? 0,
      );
    }

    final bubble = switch (message.type) {
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

    if (replyWidget != null) {
      return Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [bubble, replyWidget],
      );
    }
    return bubble;
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

class _AllReadIcon extends StatelessWidget {
  const _AllReadIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.check_circle, size: 14, color: Color(0xFFB8D9F5));
  }
}

class _UnreadCircle extends StatelessWidget {
  const _UnreadCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF177EE6), width: 1.5),
      ),
    );
  }
}

class _ReadCountCircle extends StatelessWidget {
  final int count;
  const _ReadCountCircle({required this.count});

  @override
  Widget build(BuildContext context) {
    final digits = count.toString().length;
    final size = digits == 1 ? 16.0 : 18.0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: digits <= 1 ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: digits > 1 ? BorderRadius.circular(size / 2) : null,
        border: Border.all(color: const Color(0xFF177EE6), width: 1.5),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w500,
          color: Color(0xFF177EE6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
