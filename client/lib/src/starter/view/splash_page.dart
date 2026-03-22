import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../data/model/startup_result.dart';
import '../data/repository/startup_repository.dart';

class SplashPage extends StatefulWidget {
  final StartupRepository startupRepository;
  final ValueChanged<StartupResult> onStartupComplete;

  const SplashPage({
    super.key,
    required this.startupRepository,
    required this.onStartupComplete,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    setState(() => _error = null);

    final completer = Completer<StartupEvent>();
    final subscription = widget.startupRepository.stream.listen((event) {
      if (event is! StartupLoading && !completer.isCompleted) {
        completer.complete(event);
      }
    });

    widget.startupRepository.initialize();

    final results = await Future.wait([
      completer.future,
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);

    await subscription.cancel();
    final event = results[0] as StartupEvent;

    if (!mounted) return;

    if (event is StartupReady) {
      widget.onStartupComplete(event.result);
      if (event.result.authenticated) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    } else if (event is StartupFailed) {
      setState(() => _error = event.message);
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
                  onPressed: _startInitialization,
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
