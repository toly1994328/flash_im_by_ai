import 'package:flutter/material.dart';
import '../data/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildStatusIcon(),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF3B82F6) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (isMe) _buildStatusIcon(),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    return switch (message.status) {
      MessageStatus.sending => const Padding(
        padding: EdgeInsets.only(left: 4, right: 4),
        child: SizedBox(width: 12, height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5)),
      ),
      MessageStatus.failed => const Padding(
        padding: EdgeInsets.only(left: 4, right: 4),
        child: Icon(Icons.error_outline, color: Colors.red, size: 16),
      ),
      _ => const SizedBox(width: 4),
    };
  }
}
