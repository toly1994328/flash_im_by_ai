import 'package:flutter/material.dart';

/// 基于 seed 生成 5×5 对称方块图案的 CustomPainter
class IdenticonPainter extends CustomPainter {
  final String seed;

  IdenticonPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final hash = _hashSeed(seed);
    final bgColor = const Color(0xFFEEEEEE);
    final hue = (hash[0] + hash[1] * 256) % 360;
    final fgColor = HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.5).toColor();

    final padding = size.width * 0.15;
    final innerSize = size.width - padding * 2;
    final cellW = innerSize / 5;
    final cellH = innerSize / 5;

    // 背景
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

    final paint = Paint()..color = fgColor;

    // 只计算左 3 列（col 0,1,2），右 2 列镜像
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 3; col++) {
        final bitIndex = row * 3 + col;
        final byteIndex = 2 + (bitIndex ~/ 8);
        final bit = (hash[byteIndex] >> (bitIndex % 8)) & 1;
        if (bit == 1) {
          canvas.drawRect(
            Rect.fromLTWH(padding + col * cellW, padding + row * cellH, cellW, cellH),
            paint,
          );
          final mirrorCol = 4 - col;
          if (mirrorCol != col) {
            canvas.drawRect(
              Rect.fromLTWH(padding + mirrorCol * cellW, padding + row * cellH, cellW, cellH),
              paint,
            );
          }
        }
      }
    }
  }

  /// DJB2 变体哈希，生成 16 字节
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

/// 封装 IdenticonPainter 的便捷 Widget
class IdenticonAvatar extends StatelessWidget {
  final String seed;
  final double size;
  final double borderRadius;

  const IdenticonAvatar({
    super.key,
    required this.seed,
    this.size = 56,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        size: Size(size, size),
        painter: IdenticonPainter(seed: seed),
      ),
    );
  }
}
