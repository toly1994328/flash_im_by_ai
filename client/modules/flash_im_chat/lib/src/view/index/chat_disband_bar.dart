import 'package:flutter/material.dart';

/// 群聊已解散提示栏
class ChatDisbandBar extends StatelessWidget {
  const ChatDisbandBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: const Color(0xFFF0F0F0),
      alignment: Alignment.center,
      child: const Text(
        '该群聊已解散',
        style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
      ),
    );
  }
}
