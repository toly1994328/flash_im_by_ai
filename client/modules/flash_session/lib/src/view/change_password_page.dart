import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oktoast/oktoast.dart';
import 'package:dio/dio.dart';
import 'package:flash_session/flash_session.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  bool _loading = false;

  bool get _canSubmit =>
      _oldController.text.trim().isNotEmpty &&
      _newController.text.trim().length >= 6 &&
      !_loading;

  @override
  void initState() {
    super.initState();
    _oldController.addListener(() => setState(() {}));
    _newController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await context.read<SessionCubit>().changePassword(
        oldPassword: _oldController.text.trim(),
        newPassword: _newController.text.trim(),
      );
      if (!mounted) return;
      showToast('密码修改成功');
      Navigator.of(context).pop();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        showToast('旧密码错误');
      } else {
        showToast('修改失败: ${e.message}');
      }
    } catch (e) {
      showToast('修改失败: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('修改密码', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
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
            Text('请输入当前密码和新密码', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            _buildInput(_oldController, '请输入当前密码'),
            const SizedBox(height: 16),
            _buildInput(_newController, '请输入新密码（至少6位）'),
            const SizedBox(height: 48),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
