import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flash_session/flash_session.dart';

class SetPasswordPage extends StatefulWidget {
  final bool hasPassword;

  const SetPasswordPage({
    super.key,
    required this.hasPassword,
  });

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _controller = TextEditingController();
  bool _loading = false;

  bool get _canSubmit => _controller.text.trim().length >= 6 && !_loading;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await context.read<SessionCubit>().setPassword(_controller.text.trim());
      if (!mounted) return;
      showToast('密码设置成功');
      Navigator.of(context).pop();
    } catch (e) {
      showToast('设置失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.hasPassword ? '修改密码' : '设置密码';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.hasPassword ? '请输入新密码' : '为账号设置一个密码',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: TextField(
                controller: _controller,
                obscureText: true,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: '请输入密码（至少6位）',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    const primary = Color(0xFF3B82F6);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: _canSubmit
          ? ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('确认', style: TextStyle(fontSize: 16)),
            )
          : OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Text('确认', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
            ),
    );
  }
}
