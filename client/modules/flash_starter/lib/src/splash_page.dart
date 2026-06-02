import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'privacy_consent_dialog.dart';
import 'task.dart';

class SplashPage extends StatefulWidget {
  final List<StartupTask> tasks;
  final OnStartupComplete onComplete;
  final String? baseUrl;
  final void Function(BuildContext context, String title, String url)? onViewPolicy;

  const SplashPage({
    super.key,
    required this.tasks,
    required this.onComplete,
    this.baseUrl,
    this.onViewPolicy,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? _error;
  Map<Type, dynamic>? _results;

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
      _results = results;
      _checkPrivacyConsent();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _executeTasks(Map<Type, dynamic> results) async {
    for (final task in widget.tasks) {
      results[task.runtimeType] = await task.execute();
    }
  }

  Future<void> _checkPrivacyConsent() async {
    // Web 端跳过隐私弹窗（浏览器环境无需 App 级隐私确认）
    if (kIsWeb) {
      widget.onComplete(_results!);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final agreed = prefs.getBool('privacy_agreed') ?? false;

    if (agreed) {
      widget.onComplete(_results!);
    } else {
      if (!mounted) return;
      _showPrivacyDialog();
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PrivacyConsentDialog(
        onAgree: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('privacy_agreed', true);
          if (!mounted) return;
          Navigator.of(context).pop();
          widget.onComplete(_results!);
        },
        onViewAgreement: widget.onViewPolicy != null
            ? () => widget.onViewPolicy!(context, '用户协议', '${widget.baseUrl}/static/agreement.html')
            : null,
        onViewPrivacy: widget.onViewPolicy != null
            ? () => widget.onViewPolicy!(context, '隐私政策', '${widget.baseUrl}/static/privacy.html')
            : null,
      ),
    );
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
