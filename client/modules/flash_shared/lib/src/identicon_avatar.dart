import 'package:flutter/material.dart';

/// 基于 seed 生成 5x5 对称方块图案的 CustomPainter
class IdenticonPainter extends CustomPainter {
  final String seed;
  final Color backgroundColor;
  final double paddingRatio;

  IdenticonPainter({
    required this.seed,
    this.backgroundColor = const Color(0xFFEEEEEE),
    this.paddingRatio = 0.15,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hash = _hashSeed(seed);
    final Color fgColor;
    if (seed.contains(':')) {
      final hex = seed.split(':').last;
      final colorValue = int.tryParse(hex, radix: 16);
      if (colorValue != null) {
        fgColor = Color(0xFF000000 | colorValue);
      } else {
        final hue = (hash[0] + hash[1] * 256) % 360;
        fgColor = HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.5).toColor();
      }
    } else {
      final hue = (hash[0] + hash[1] * 256) % 360;
      fgColor = HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.5).toColor();
    }
    final padding = size.width * paddingRatio;
    final innerSize = size.width - padding * 2;
    final cellW = innerSize / 5;
    final cellH = innerSize / 5;
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    final paint = Paint()..color = fgColor;
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 3; col++) {
        final bitIndex = row * 3 + col;
        final byteIndex = 2 + (bitIndex ~/ 8);
        final bit = (hash[byteIndex] >> (bitIndex % 8)) & 1;
        if (bit == 1) {
          canvas.drawRect(
            Rect.fromLTWH(padding + col * cellW, padding + row * cellH, cellW, cellH), paint);
          final mirrorCol = 4 - col;
          if (mirrorCol != col) {
            canvas.drawRect(
              Rect.fromLTWH(padding + mirrorCol * cellW, padding + row * cellH, cellW, cellH), paint);
          }
        }
      }
    }
  }

  List<int> _hashSeed(String seed) {
    final result = List<int>.filled(16, 0);
    var h = 5381;
    for (final c in seed.codeUnits) {
      h = ((h << 5) + h + c) & 0xFFFFFFFF;
    }
    for (int i = 0; i < 16; i++) {
      result[i] = (h >> (i * 2)) & 0xFF;
      h = ((h << 3) + h + i + 1) & 0xFFFFFFFF;
    }
    return result;
  }

  @override
  bool shouldRepaint(IdenticonPainter oldDelegate) => oldDelegate.seed != seed;
}

class IdenticonAvatar extends StatelessWidget {
  final String seed;
  final double size;
  final double borderRadius;
  final Color backgroundColor;
  final double paddingRatio;

  const IdenticonAvatar({
    super.key,
    required this.seed,
    this.size = 56,
    this.borderRadius = 6,
    this.backgroundColor = const Color(0xFFEEEEEE),
    this.paddingRatio = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        size: Size(size, size),
        painter: IdenticonPainter(
          seed: seed,
          backgroundColor: backgroundColor,
          paddingRatio: paddingRatio,
        ),
      ),
    );
  }
}
