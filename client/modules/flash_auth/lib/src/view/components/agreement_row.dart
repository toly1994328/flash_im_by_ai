import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fx_env/fx_env.dart';
import 'package:url_launcher/url_launcher.dart';

import '../policy_page.dart';

const _kPrimary = Color(0xFF3B82F6);

/// 用户协议 + 隐私政策勾选行
class AgreementRow extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;
  final String baseUrl;

  const AgreementRow({
    super.key,
    required this.checked,
    required this.onTap,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CheckIcon(checked: checked),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                children: [
                  const TextSpan(text: '登录即代表您同意'),
                  _linkSpan(context, '《用户协议》', '用户协议', '$baseUrl/static/agreement.html'),
                  const TextSpan(text: '和'),
                  _linkSpan(context, '《隐私政策》', '隐私政策', '$baseUrl/static/privacy.html'),
                  const TextSpan(text: '，未注册绑定的手机号验证成功后将自动注册'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _linkSpan(BuildContext context, String text, String title, String url) {
    return TextSpan(
      text: text,
      style: const TextStyle(color: _kPrimary),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          if (kApp.isDesktop) {
            launchUrl(Uri.parse(url));
          } else {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PolicyPage(title: title, url: url),
            ));
          }
        },
    );
  }
}

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
      child: checked ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
    );
  }
}
