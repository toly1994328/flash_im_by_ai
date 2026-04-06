import 'package:flutter/material.dart';
import '../../data/message.dart';

class TextBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const TextBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
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
}
