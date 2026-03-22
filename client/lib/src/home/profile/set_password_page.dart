import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oktoast/oktoast.dart';
import '../../auth/logic/auth/auth_cubit.dart';
import '../../auth/data/repository/auth_repository.dart';
import '../../auth/view/components/action_button.dart';

class SetPasswordPage extends StatefulWidget {
  final AuthRepository authRepository;
  final bool hasPassword;

  const SetPasswordPage({
    super.key,
    required this.authRepository,
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
      await widget.authRepository.setPassword(_controller.text.trim());
      if (!mounted) return;
      context.read<AuthCubit>().onPasswordSet();
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
            ActionButton(
              enabled: _canSubmit,
              loading: _loading,
              text: '确认',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
