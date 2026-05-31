import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import '../data/auth_repository.dart';

/// 扫码确认页：手机端扫码后显示确认/取消
class ScanConfirmPage extends StatefulWidget {
  final String scanToken;
  final AuthRepository authRepository;

  const ScanConfirmPage({
    super.key,
    required this.scanToken,
    required this.authRepository,
  });

  @override
  State<ScanConfirmPage> createState() => _ScanConfirmPageState();
}

class _ScanConfirmPageState extends State<ScanConfirmPage> {
  bool _isLoading = false;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _markScanned();
  }

  Future<void> _markScanned() async {
    try {
      await widget.authRepository.confirmScan(widget.scanToken, 'scan');
      if (mounted) setState(() => _scanned = true);
    } catch (e) {
      if (mounted) {
        showToast('扫码失败，请重试');
        Navigator.pop(context);
      }
    }
  }

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    try {
      await widget.authRepository.confirmScan(widget.scanToken, 'confirm');
      if (!mounted) return;
      showToast('登录成功');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showToast('确认失败，请重试');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancel() async {
    try {
      await widget.authRepository.cancelScan(widget.scanToken);
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫码登录'),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.desktop_windows, size: 64, color: Color(0xFF3B82F6)),
              const SizedBox(height: 24),
              const Text(
                '即将登录桌面端闪讯',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '确认后，桌面端将自动登录你的账号',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              if (_scanned) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('确认登录', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _cancel,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('取消', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ] else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
