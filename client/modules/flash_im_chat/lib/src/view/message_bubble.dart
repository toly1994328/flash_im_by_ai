import 'package:flash_shared/flash_shared.dart';
import 'package:flutter/material.dart';
import '../data/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

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
            child: Text(
              message.senderName,
              style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
            ),
          ),
        _buildBubble(),
        _buildStatusIcon(),
      ],
    );
  }

  Widget _buildBubble() {
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
      child: Text(
        message.content,
        style: TextStyle(fontSize: 15, color: isMe ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return switch (message.status) {
      MessageStatus.sending => const Padding(
        padding: EdgeInsets.only(top: 2),
        child: SizedBox(width: 12, height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5)),
      ),
      MessageStatus.failed => const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(Icons.error_outline, color: Colors.red, size: 14),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
