import 'package:flutter/material.dart';

import 'storage_repository.dart';

/// "我的"页面云空间卡片（底部 6px 分色进度条）
class CloudStorageCard extends StatelessWidget {
  final StorageQuota quota;
  final VoidCallback? onTap;

  const CloudStorageCard({super.key, required this.quota, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // 前景内容
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  const Icon(Icons.cloud_outlined, size: 22, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('云空间', style: TextStyle(fontSize: 16)),
                  ),
                  Text(
                    '${quota.usedFormatted} / ${quota.quotaFormatted}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                ],
              ),
            ),
            // 底部 6px 分色进度条
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 3,
              child: _buildProgressBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final Map<String, CategoryUsage> bd = quota.breakdown;
    final int total = quota.quotaBytes;
    if (total <= 0) return const SizedBox.shrink();

    final Map<String, Color> colors = {
      'image': const Color(0xFF2196F3),
      'video': const Color(0xFFFFC107),
      'audio': const Color(0xFFF44336),
      'file': const Color(0xFF4CAF50),
    };

    final List<Widget> segments = [];
    for (final MapEntry<String, Color> entry in colors.entries) {
      final CategoryUsage? usage = bd[entry.key];
      if (usage != null && usage.size > 0) {
        segments.add(Expanded(
          flex: (usage.size * 1000 ~/ total).clamp(1, 1000),
          child: Container(color: entry.value),
        ));
      }
    }
    final int emptyFlex = ((1 - quota.usagePercent) * 1000).round().clamp(1, 1000);
    segments.add(Expanded(flex: emptyFlex, child: Container(color: Colors.white)));

    return Row(children: segments);
  }
}
