import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'storage_quota_cubit.dart';
import 'storage_repository.dart';

/// 云空间详情页
class CloudStoragePage extends StatelessWidget {
  const CloudStoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('云空间'), elevation: 0),
      body: BlocBuilder<StorageQuotaCubit, StorageQuotaState>(
        builder: (context, state) {
          if (state.status == StorageQuotaStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.quota == null) {
            return const Center(child: Text('暂无数据'));
          }
          return _buildContent(state.quota!);
        },
      ),
    );
  }

  Widget _buildContent(StorageQuota quota) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRingChart(quota),
        const SizedBox(height: 24),
        _buildCategoryList(quota),
      ],
    );
  }

  Widget _buildRingChart(StorageQuota quota) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _RingPainter(quota: quota),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      quota.usedFormatted,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '/ ${quota.quotaFormatted}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '剩余 ${quota.remainFormatted}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(StorageQuota quota) {
    final List<_CategoryItem> items = [
      _CategoryItem('图片', Icons.image_outlined, const Color(0xFF2196F3), quota.breakdown['image']),
      _CategoryItem('视频', Icons.videocam_outlined, const Color(0xFFFFC107), quota.breakdown['video']),
      _CategoryItem('音频', Icons.audiotrack_outlined, const Color(0xFFF44336), quota.breakdown['audio']),
      _CategoryItem('文件', Icons.insert_drive_file_outlined, const Color(0xFF4CAF50), quota.breakdown['file']),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.map((item) {
          final CategoryUsage usage = item.usage ?? CategoryUsage(size: 0, count: 0);
          return ListTile(
            leading: Icon(item.icon, color: item.color, size: 24),
            title: Text(item.label, style: const TextStyle(fontSize: 15)),
            trailing: Text(
              '${usage.sizeFormatted}  ·  ${usage.count} 个',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final IconData icon;
  final Color color;
  final CategoryUsage? usage;
  const _CategoryItem(this.label, this.icon, this.color, this.usage);
}

class _RingPainter extends CustomPainter {
  final StorageQuota quota;
  _RingPainter({required this.quota});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 12;
    final Rect rect = Rect.fromLTWH(
      strokeWidth / 2, strokeWidth / 2,
      size.width - strokeWidth, size.height - strokeWidth,
    );

    // 背景环
    final Paint bgPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, bgPaint);

    // 各类型扇区
    final Map<String, Color> colors = {
      'image': const Color(0xFF2196F3),
      'video': const Color(0xFFFFC107),
      'audio': const Color(0xFFF44336),
      'file': const Color(0xFF4CAF50),
    };

    double startAngle = -pi / 2;
    for (final MapEntry<String, Color> entry in colors.entries) {
      final CategoryUsage? usage = quota.breakdown[entry.key];
      if (usage == null || usage.size <= 0 || quota.quotaBytes <= 0) continue;
      final double sweep = (usage.size / quota.quotaBytes) * 2 * pi;
      final Paint paint = Paint()
        ..color = entry.value
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => true;
}
