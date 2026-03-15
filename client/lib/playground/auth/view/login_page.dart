import 'dart:async';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import '../api/auth_api.dart';
import 'profile_page.dart';

/// 主题色
const _kPrimary = Color(0xFF3B82F6);

/// 登录页
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthApi _api = AuthApi();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _smsSent = false;
  bool _smsLoading = false;
  bool _loginLoading = false;
  bool _agreed = false;
  int _countdown = 0;
  Timer? _timer;

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() { _countdown--; });
      if (_countdown <= 0) t.cancel();
    });
  }

  bool get _canSendSms => !_smsLoading && _countdown <= 0;

  Future<void> _sendSms() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 11 || !phone.startsWith('1')) {
      showToast('请输入正确的手机号');
      return;
    }
    setState(() { _smsLoading = true; });
    try {
      debugPrint('📱 发送验证码: $phone');
      final code = await _api.sendSms(phone);
      debugPrint('✅ 验证码返回: $code');
      _codeCtrl.text = code; // 模拟阶段自动填入
      _startCountdown();
      debugPrint('⏱️ 倒计时启动: $_countdown');
      setState(() { _smsSent = true; _smsLoading = false; });
    } catch (e) {
      debugPrint('❌ 发送失败: $e');
      showToast('发送失败: $e');
      setState(() => _smsLoading = false);
    }
  }

  Future<void> _login() async {
    if (!_agreed) {
      showToast('请先同意用户协议');
      return;
    }
    setState(() { _loginLoading = true; });
    try {
      await _api.login(_phoneCtrl.text.trim(), _codeCtrl.text.trim());
      final profile = await _api.getProfile();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProfilePage(api: _api, profile: profile)),
      );
    } catch (e) {
      showToast('登录失败，请检查验证码');
      setState(() => _loginLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 关闭按钮
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 24),
                  ),
                ),
                const SizedBox(height: 24),

                // 品牌标题
                const Text(
                  'FLASH IM',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '即时通信练习场',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], letterSpacing: 4),
                ),
                const SizedBox(height: 56),

                // 手机号输入
                _buildInputRow(
                  label: '+86',
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: '请输入手机号',
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 验证码输入
                _buildInputRow(
                  label: '验证码',
                  trailing: GestureDetector(
                    onTap: _canSendSms ? _sendSms : null,
                    child: Text(
                      _countdown > 0 ? '${_countdown}s' : (_smsSent ? '重新发送' : '获取验证码'),
                      style: TextStyle(
                        fontSize: 14,
                        color: _canSendSms ? _kPrimary : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  child: TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: '请输入验证码',
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 协议勾选
                GestureDetector(
                  onTap: () => setState(() => _agreed = !_agreed),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CheckIcon(checked: _agreed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            children: const [
                              TextSpan(text: '登录即代表您同意'),
                              TextSpan(text: '《用户协议》', style: TextStyle(color: _kPrimary)),
                              TextSpan(text: '和'),
                              TextSpan(text: '《隐私政策》', style: TextStyle(color: _kPrimary)),
                              TextSpan(text: '，未注册绑定的手机号验证成功后将自动注册'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 登录按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: (_loginLoading || !_smsSent) ? null : _login,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: _loginLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('登录', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 底部分割线风格的输入行
  Widget _buildInputRow({required String label, required Widget child, Widget? trailing}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.only(right: 12),
            color: _kPrimary.withValues(alpha: 0.4),
          ),
          Expanded(child: child),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

/// 自定义圆角勾选图标
class _CheckIcon extends StatelessWidget {
  final bool checked;
  const _CheckIcon({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: checked ? _kPrimary : Colors.transparent,
        border: Border.all(
          color: checked ? _kPrimary : Colors.grey[400]!,
          width: 1.2,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 10, color: Colors.white)
          : null,
    );
  }
}
