import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 聊天消息列表骨架屏
class ChatSkeleton extends StatelessWidget {
  final bool enable;

  const ChatSkeleton({super.key, this.enable = true});

  @override
  Widget build(BuildContext context) {
    if (!enable) return const SizedBox.shrink();
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        reverse: true,
        itemCount: 8,
        itemBuilder: (_, index) {
          final bool isMe = index % 3 == 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Container(
                  width: 120 + (index % 3) * 40,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
