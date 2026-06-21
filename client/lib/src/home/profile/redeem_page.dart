import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_session/flash_session.dart';

/// 兑换码输入页
class RedeemPage extends StatefulWidget {
  const RedeemPage({super.key});

  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _resultMessage;
  bool _success = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onRedeem() async {
    final String code = _controller.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _resultMessage = null;
    });

    try {
      final RedeemResult result = await context.read<SubscriptionCubit>().redeem(code);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = true;
        _resultMessage = '✅ 已激活「${result.planName}」，到期 ${result.expiresAt.toLocal().toString().substring(0, 10)}';
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final String msg = (e.response?.data is Map)
          ? (e.response?.data['message'] as String? ?? '兑换失败')
          : '网络错误';
      setState(() {
        _loading = false;
        _success = false;
        _resultMessage = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('兑换码'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Text(
              '输入兑换码激活云空间订阅',
              style: TextStyle(fontSize: 16, color: Color(0xFF333333)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '请输入兑换码',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _onRedeem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('兑换', style: TextStyle(fontSize: 16)),
            ),
            if (_resultMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                _resultMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: _success ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
