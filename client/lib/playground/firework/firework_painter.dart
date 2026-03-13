import 'package:flutter/material.dart';
import 'firework.dart';

class FireworkPainter extends CustomPainter {
  final List<Firework> fireworks;

  FireworkPainter(this.fireworks);

  @override
  void paint(Canvas canvas, Size size) {
    for (var firework in fireworks) {
      if (!firework.exploded) {
        // 绘制轨迹
        for (int i = 0; i < firework.trail.length - 1; i++) {
          final paint = Paint()
            ..color = firework.color.withOpacity((i / firework.trail.length) * 0.8)
            ..strokeWidth = 2;
          canvas.drawLine(
            Offset(firework.trail[i].dx * size.width, firework.trail[i].dy * size.height),
            Offset(firework.trail[i + 1].dx * size.width, firework.trail[i + 1].dy * size.height),
            paint,
          );
        }

        // 绘制火箭
        final paint = Paint()..color = firework.color;
        canvas.drawCircle(
          Offset(firework.x * size.width, firework.y * size.height),
          3,
          paint,
        );
      } else {
        // 绘制爆炸粒子
        for (var particle in firework.particles) {
          final paint = Paint()
            ..color = particle.color.withOpacity(particle.life.clamp(0.0, 1.0));
          canvas.drawCircle(
            Offset(particle.x * size.width, particle.y * size.height),
            particle.size,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
