import 'package:dio/dio.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// 注销账号页面（微信风格）
class DeleteAccountPage extends StatefulWidget {
  final Dio dio;
  const DeleteAccountPage({super.key, required this.dio});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _error = '请输入密码');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await widget.dio.post('/api/account/delete', data: {'password': password});
      if (!mounted) return;
      context.read<WsClient>().disconnect();
      await context.read<SessionCubit>().deactivate();
      if (!mounted) return;
      context.go('/login');
    } on DioException catch (e) {
      if (!mounted) return;
      final int? statusCode = e.response?.statusCode;
      setState(() {
        _submitting = false;
        _error = switch (statusCode) {
          401 => '密码错误',
          400 => '请先在设置中设置密码',
          _ => '网络错误，请重试',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('注销账号'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          // 警告卡片
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57C00), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('注销须知', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                  ],
                ),
                const SizedBox(height: 16),
                _buildWarningItem('账号信息与个人资料将被永久删除'),
                _buildWarningItem('所有聊天记录将无法恢复'),
                _buildWarningItem('好友关系将被解除'),
                _buildWarningItem('群聊成员身份将被移除'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 密码输入区
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('验证身份', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
                const SizedBox(height: 6),
                const Text('请输入账号密码以确认注销操作', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '输入密码',
                    hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    errorText: _error,
                    errorStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 注销按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336),
                  disabledBackgroundColor: const Color(0xFFEF9A9A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('确认注销', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('注销后数据无法恢复，请谨慎操作', style: TextStyle(fontSize: 12, color: Color(0xFF999999)))),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color(0xFFF44336)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF666666)))),
        ],
      ),
    );
  }
}
