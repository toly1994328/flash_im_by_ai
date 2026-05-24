import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 首次启动隐私协议弹窗
///
/// 用户必须点击"同意并继续"才能使用应用。
/// 点击"不同意"弹出二次确认，确认后退出应用。
class PrivacyConsentDialog extends StatelessWidget {
  final VoidCallback onAgree;
  final VoidCallback? onViewAgreement;
  final VoidCallback? onViewPrivacy;

  const PrivacyConsentDialog({
    super.key,
    required this.onAgree,
    this.onViewAgreement,
    this.onViewPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '个人信息保护指引',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
            ),
            const SizedBox(height: 20),
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 15, color: Color(0xFF333333), height: 1.8),
                children: [
                  const TextSpan(text: '    欢迎使用闪讯。在使用前，请认真阅读'),
                  _linkSpan('《用户协议》', onViewAgreement),
                  const TextSpan(text: '和'),
                  _linkSpan('《隐私政策》', onViewPrivacy),
                  const TextSpan(text: '。我们将严格按照协议内容保护您的个人信息。闪讯的主要功能为即时通讯、好友管理、群聊等。\n    同意隐私政策仅代表同意使用主要功能时收集、处理相关必要信息。麦克风、相机等权限将在您使用具体功能时单独征求同意。'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // 不同意
            GestureDetector(
              onTap: () => _showDisagreeConfirm(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('不同意', style: TextStyle(fontSize: 15, color: Colors.grey[400])),
              ),
            ),
            const SizedBox(height: 12),
            // 同意并继续
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onAgree,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: const Text('同意并继续', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _linkSpan(String text, VoidCallback? onTap) {
    return TextSpan(
      text: text,
      style: const TextStyle(color: Color(0xFF3B82F6)),
      recognizer: onTap != null ? (TapGestureRecognizer()..onTap = onTap) : null,
    );
  }

  void _showDisagreeConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('提示', style: TextStyle(fontSize: 16)),
        content: const Text(
          '不同意将无法使用闪讯，确定退出吗？',
          style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('确定退出', style: TextStyle(color: Color(0xFF999999))),
          ),
        ],
      ),
    );
  }
}
