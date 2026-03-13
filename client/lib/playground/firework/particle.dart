import 'package:flutter/material.dart';
import 'dart:math';

/// 基础粒子类
abstract class BaseParticle {
  double x, y;
  Color color;
  double size;
  double speed;
  double direction;
  double life;
  double maxLife;
  int age;

  BaseParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speed,
    required this.direction,
    required this.life,
    required this.maxLife,
    this.age = 0,
  });

  void update();
  void reset();
}

class Particle extends BaseParticle {
  double birthTime;

  Particle({
    required super.x,
    required super.y,
    required super.color,
    required super.size,
    required super.speed,
    required super.direction,
    required super.life,
    required super.maxLife,
    required this.birthTime,
    super.age = 0,
  });

  @override
  void update() {
    age++;
    life = 1.0 - (age / maxLife);
    x += cos(direction) * speed;
    y += sin(direction) * speed;
    speed *= 0.98;
  }

  @override
  void reset() {
    age = 0;
    life = 1.0;
  }
}
