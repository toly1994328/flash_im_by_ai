import 'dart:math';
import 'package:flutter/material.dart';

class Star {
  final double x, y, baseRadius;
  final double twinkleSpeed; // 闪烁速度
  double phase; // 闪烁相位

  Star({
    required this.x,
    required this.y,
    required this.baseRadius,
    required this.twinkleSpeed,
    required this.phase,
  });
}

class StarSky {
  final List<Star> stars = [];
  final Random _random = Random(42);

  StarSky() {
    for (int i = 0; i < 100; i++) {
      stars.add(Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        baseRadius: 0.3 + _random.nextDouble() * 1.2,
        twinkleSpeed: 0.02 + _random.nextDouble() * 0.04,
        phase: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  void update() {
    for (final s in stars) {
      s.phase += s.twinkleSpeed;
    }
  }
}

class StarSkyPainter extends CustomPainter {
  final List<Star> stars;
  StarSkyPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in stars) {
      final alpha = 0.3 + 0.4 * ((sin(s.phase) + 1) / 2); // 0.3~0.7 闪烁
      final radius = s.baseRadius * (0.8 + 0.2 * sin(s.phase));
      paint.color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
