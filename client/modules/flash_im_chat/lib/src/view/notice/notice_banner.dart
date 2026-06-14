import 'package:flutter/material.dart';

/// 群公告横幅
class NoticeBanner extends StatelessWidget {
  final String notice;
  final VoidCallback? onTap;

  const NoticeBanner({super.key, required this.notice, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF9E6),
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEE6CC), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: Color(0xFFE6A817), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 16),
          ],
        ),
      ),
    );
  }
}
