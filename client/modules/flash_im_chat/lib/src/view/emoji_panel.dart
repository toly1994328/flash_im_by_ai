import 'package:flutter/material.dart';

/// 常用 Emoji 表情列表
const _commonEmojis = [
  '😀', '😂', '🥹', '😊', '😍', '🥰', '😘', '😜',
  '🤔', '😅', '😢', '😭', '😤', '🤗', '👍', '👎',
  '👏', '🙏', '💪', '❤️', '💔', '🔥', '🎉', '✨',
  '😱', '🙄', '😴', '🤮', '💩', '👻', '🐶', '🐱',
  '🌹', '🍀', '🌈', '⭐', '🎵', '📷', '🎂', '🍻',
  '☕', '🏆', '💰', '🎁', '💡', '📌', '✅', '❌',
  '😎', '🤩', '🥳', '😇', '🤣', '😋', '😛', '🤑',
  '🤫', '🤭', '🫠', '🥺', '😈', '💀', '🤡', '👀',
  '🫶', '🤝', '✌️', '🤞', '👌', '🫡', '💅', '🙌',
  '🦋', '🐼', '🦊', '🐸', '🌸', '🍕', '🍔', '🎃',
  '⚡', '🌙', '☀️', '🫧', '🎯', '🧩', '💎', '🚀',
];

/// Emoji 表情面板
///
/// 展示常用表情网格，点击后通过 [onEmojiSelected] 回调。
class EmojiPanel extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;
  final double? height;

  const EmojiPanel({super.key, required this.onEmojiSelected, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _commonEmojis.length,
        itemBuilder: (_, index) {
          final emoji = _commonEmojis[index];
          return GestureDetector(
            onTap: () => onEmojiSelected(emoji),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }
}
