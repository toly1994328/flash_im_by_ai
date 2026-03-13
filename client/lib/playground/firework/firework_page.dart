import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'firework.dart';
import 'firework_painter.dart';
import 'star_sky.dart';

class FireworkPage extends StatefulWidget {
  const FireworkPage({super.key});

  @override
  State<FireworkPage> createState() => _FireworkPageState();
}

class _FireworkPageState extends State<FireworkPage>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final FireworkSystem _system = FireworkSystem();
  final StarSky _starSky = StarSky();
  Duration _lastUpdate = Duration.zero;
  // 固定 20fps 物理更新，和参考案例一致
  static const _interval = Duration(milliseconds: 16);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (elapsed - _lastUpdate >= _interval) {
      _system.update();
      _starSky.update();
      _lastUpdate = elapsed;
      setState(() {});
    }
  }

  void _onTapDown(TapDownDetails details) {
    final size = MediaQuery.of(context).size;
    final nx = details.localPosition.dx / size.width;
    final ny = details.localPosition.dy / size.height;
    _system.addFirework(nx, ny);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('🎆 烟花秀',
            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w300)),
      ),
      body: GestureDetector(
        onTapDown: _onTapDown,
        child: Stack(
          children: [
            CustomPaint(
              painter: StarSkyPainter(_starSky.stars),
              size: Size.infinite,
            ),
            CustomPaint(
              painter: FireworkPainter(_system.fireworks),
              size: Size.infinite,
            ),
          ],
        ),
      ),
    );
  }
}
