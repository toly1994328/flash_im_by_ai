import 'package:flutter/material.dart';

/// 暂无消息占位
class ChatEmpty extends StatelessWidget {
  const ChatEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('暂无消息', style: TextStyle(color: Colors.grey)),
    );
  }
}

/// 加载失败 + 重试
class ChatErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ChatErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
