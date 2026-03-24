import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'task.dart';

class SplashPage extends StatefulWidget {
  final List<StartupTask> tasks;
  final OnStartupComplete onComplete;

  const SplashPage({
    super.key,
    required this.tasks,
    required this.onComplete,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _error = null);
    try {
      final results = <Type, dynamic>{};
      await Future.wait([
        _executeTasks(results),
        Future.delayed(const Duration(milliseconds: 1500)),
      ]);
      if (!mounted) return;
      widget.onComplete(results);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _executeTasks(Map<Type, dynamic> results) async {
    for (final task in widget.tasks) {
      results[task.runtimeType] = await task.execute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', width: 100, height: 100),
              const SizedBox(height: 16),
              const Text(
                'Flash IM',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              if (_error != null) ...[
                const SizedBox(height: 24),
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _run,
                  child: const Text('重试'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
