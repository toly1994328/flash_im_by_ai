import 'package:flutter/material.dart';

import 'storage_repository.dart';

/// "我的"页面云空间卡片
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: 10),
              _buildProgressBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final Map<String, CategoryUsage> bd = quota.breakdown;
    final int total = quota.quotaBytes;
    if (total <= 0) return const SizedBox.shrink();

    final List<_BarSegment> segments = [];
    final Map<String, Color> colors = {
      'image': const Color(0xFF2196F3),
      'video': const Color(0xFFFFC107),
      'audio': const Color(0xFFF44336),
      'file': const Color(0xFF4CAF50),
    };

    for (final MapEntry<String, Color> entry in colors.entries) {
      final CategoryUsage? usage = bd[entry.key];
      if (usage != null && usage.size > 0) {
        segments.add(_BarSegment(
          fraction: usage.size / total,
          color: entry.value,
        ));
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 6,
        color: const Color(0xFFEEEEEE),
        child: Row(
          children: segments.map((s) {
            return Expanded(
              flex: (s.fraction * 1000).round().clamp(1, 1000),
              child: Container(color: s.color),
            );
          }).toList()
            ..add(Expanded(
              flex: ((1 - quota.usagePercent) * 1000).round().clamp(1, 1000),
              child: const SizedBox.shrink(),
            )),
        ),
      ),
    );
  }
}

class _BarSegment {
  final double fraction;
  final Color color;
  const _BarSegment({required this.fraction, required this.color});
}
