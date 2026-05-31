import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/auth_repository.dart';
import '../../data/login_result.dart';
import '../../data/scan_models.dart';
import '../login_page.dart';

/// 扫码登录表单：展示二维码 + 轮询状态 + 自动登录
class QrLoginForm extends StatefulWidget {
  final AuthRepository authRepository;
  final OnLoginSuccess onLoginSuccess;

  const QrLoginForm({
    super.key,
    required this.authRepository,
    required this.onLoginSuccess,
  });

  @override
  State<QrLoginForm> createState() => _QrLoginFormState();
}

class _QrLoginFormState extends State<QrLoginForm> {
  String? _qrContent;
  String? _scanToken;
  String _status = 'loading'; // loading/pending/scanned/expired/error
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _createSession() async {
    setState(() => _status = 'loading');
    try {
      final result = await widget.authRepository.createScanSession();
      if (!mounted) return;
      setState(() {
        _scanToken = result.token;
        _qrContent = result.qrContent;
        _status = 'pending';
      });
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'error');
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollStatus());
  }

  Future<void> _pollStatus() async {
    if (_scanToken == null) return;
    try {
      final result = await widget.authRepository.getScanStatus(_scanToken!);
      if (!mounted) return;
      switch (result.status) {
        case 'pending':
          break;
        case 'scanned':
          setState(() => _status = 'scanned');
        case 'confirmed':
          _pollTimer?.cancel();
          final loginResult = LoginResult(
            token: result.token!,
            userId: result.userId!,
            hasPassword: false,
          );
          widget.onLoginSuccess(loginResult);
        case 'expired':
          _pollTimer?.cancel();
          setState(() => _status = 'expired');
        case 'cancelled':
          setState(() => _status = 'pending');
        default:
          break;
      }
    } catch (_) {
      // 网络错误时继续轮询，不中断
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        _buildQrArea(),
        const SizedBox(height: 16),
        _buildStatusText(),
      ],
    );
  }

  Widget _buildQrArea() {
    if (_status == 'loading') {
      return const SizedBox(
        width: 220,
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_status == 'error') {
      return SizedBox(
        width: 220,
        height: 220,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              TextButton(onPressed: _createSession, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        QrImageView(
          data: _qrContent ?? '',
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
          size: 220,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(8),
        ),
        if (_status == 'expired')
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh, size: 36, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('二维码已过期', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _createSession,
                  child: const Text('点击刷新'),
                ),
              ],
            ),
          ),
        if (_status == 'scanned')
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 48, color: Colors.green),
                SizedBox(height: 8),
                Text('已扫码', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('请在手机上确认登录', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusText() {
    switch (_status) {
      case 'pending':
        return const Text(
          '请使用手机闪讯扫描二维码登录',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        );
      case 'scanned':
        return const Text(
          '等待手机确认...',
          style: TextStyle(color: Colors.green, fontSize: 13),
        );
      case 'expired':
        return const Text(
          '二维码已过期，请刷新',
          style: TextStyle(color: Colors.orange, fontSize: 13),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
