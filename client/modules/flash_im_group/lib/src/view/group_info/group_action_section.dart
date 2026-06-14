import 'package:flutter/material.dart';

/// 群详情页底部操作按钮（转让/解散/退出）
class GroupActionSection extends StatelessWidget {
  final bool isOwner;
  final VoidCallback onTransfer;
  final VoidCallback onDisband;
  final VoidCallback onLeave;

  const GroupActionSection({
    super.key,
    required this.isOwner,
    required this.onTransfer,
    required this.onDisband,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        if (isOwner) ...[
          _ActionButton(label: '转让群主', color: const Color(0xFF3B82F6), onTap: onTransfer),
          const SizedBox(height: 10),
          _ActionButton(label: '解散群聊', color: const Color(0xFFF44336), onTap: onDisband),
        ] else
          _ActionButton(label: '退出群聊', color: const Color(0xFFF44336), onTap: onLeave),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 16, color: color)),
      ),
    );
  }
}
