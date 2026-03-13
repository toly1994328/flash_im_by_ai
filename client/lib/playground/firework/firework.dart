import 'package:flutter/material.dart';
import 'dart:math';
import 'particle.dart';

class Firework {
  double x, y, targetY;
  Color color;
  List<Particle> particles;
  bool exploded;
  int age;
  List<Offset> trail;

  Firework({
    required this.x,
    required this.y,
    required this.targetY,
    required this.color,
    required this.particles,
    required this.exploded,
    required this.age,
    required this.trail,
  });
}

class FireworkSystem {
  final Random random = Random();
  final List<Firework> fireworks = [];

  void addFirework(double tapX, double tapY) {
    final count = 1 + random.nextInt(2);
    for (int i = 0; i < count; i++) {
      fireworks.add(Firework(
        x: tapX + (random.nextDouble() - 0.5) * 0.04,
        y: 1.0 + random.nextDouble() * 0.1,
        targetY: tapY,
        color: _getRandomColor(),
        particles: [],
        exploded: false,
        age: 0,
        trail: [],
      ));
    }
  }

  void update() {
    for (var firework in fireworks) {
      firework.age++;

      if (!firework.exploded) {
        firework.trail.add(Offset(firework.x, firework.y));
        if (firework.trail.length > 8) {
          firework.trail.removeAt(0);
        }

        firework.y -= 0.008;
        if (firework.y <= firework.targetY) {
          firework.exploded = true;
          for (int i = 0; i < 30; i++) {
            firework.particles.add(Particle(
              x: firework.x,
              y: firework.y,
              color: _getRandomColor(),
              size: random.nextDouble() * 3 + 1,
              speed: random.nextDouble() * 0.01 + 0.005,
              direction: random.nextDouble() * 2 * pi,
              life: 1.0,
              maxLife: random.nextDouble() * 100 + 50,
              birthTime: 0,
            ));
          }
        }
      } else {
        for (var particle in firework.particles) {
          particle.update();
        }
        firework.particles.removeWhere((p) => p.life <= 0);
      }
    }

    fireworks.removeWhere((fw) => fw.exploded && fw.particles.isEmpty);
  }

  Color _getRandomColor() {
    final hue = random.nextDouble() * 360;
    return HSVColor.fromAHSV(1.0, hue, 0.8, 1.0).toColor();
  }
}
