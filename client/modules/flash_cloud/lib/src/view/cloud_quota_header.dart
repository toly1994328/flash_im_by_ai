import 'dart:math';

import 'package:flutter/material.dart';

/// 云空间配额概览卡片（Tab 页顶部）
class CloudQuotaHeader extends StatelessWidget {
  final int usedBytes;
  final int quotaBytes;
  final Map<String, dynamic> breakdown;

  const CloudQuotaHeader({
    super.key,
    required this.usedBytes,
    required this.quotaBytes,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final double percent = quotaBytes > 0 ? usedBytes / quotaBytes : 0;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 左侧圆形进度环
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _QuotaRingPainter(
                percent: percent.clamp(0.0, 1.0),
                breakdown: breakdown,
                quotaBytes: quotaBytes,
              ),
              child: Center(
                child: Text(
                  '${(percent * 100).toInt()}%',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 右侧信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatBytes(usedBytes),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('/ ${_formatBytes(quotaBytes)}', style: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildLegend(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: _categoryColors.entries.map((entry) {
        final dynamic usage = breakdown[entry.key];
        final int size = (usage is Map) ? (usage['size'] as int? ?? 0) : 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: entry.value, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('${_categoryLabel(entry.key)} ${_formatBytes(size)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
          ],
        );
      }).toList(),
    );
  }

  static const Map<String, Color> _categoryColors = {
    'image': Color(0xFF2196F3),
    'video': Color(0xFFFFC107),
    'audio': Color(0xFFF44336),
    'file': Color(0xFF4CAF50),
  };

  static String _categoryLabel(String key) {
    return switch (key) {
      'image' => '图片',
      'video' => '视频',
      'audio' => '音频',
      'file' => '文件',
      _ => key,
    };
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _QuotaRingPainter extends CustomPainter {
  final double percent;
  final Map<String, dynamic> breakdown;
  final int quotaBytes;

  _QuotaRingPainter({required this.percent, required this.breakdown, required this.quotaBytes});

  static const Map<String, Color> _colors = {
    'image': Color(0xFF2196F3),
    'video': Color(0xFFFFC107),
    'audio': Color(0xFFF44336),
    'file': Color(0xFF4CAF50),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 7;
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
    canvas.drawArc(rect, -pi / 2, 2 * pi, false, bgPaint);

    if (quotaBytes <= 0) return;

    // 分色扇区
    double startAngle = -pi / 2;
    for (final MapEntry<String, Color> entry in _colors.entries) {
      final dynamic usage = breakdown[entry.key];
      if (usage is! Map) continue;
      final int size = usage['size'] as int? ?? 0;
      if (size <= 0) continue;

      final double sweep = (size / quotaBytes) * 2 * pi;
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
  bool shouldRepaint(covariant _QuotaRingPainter oldDelegate) => true;
}
