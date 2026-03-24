import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF3B82F6);

/// 用户协议 + 隐私政策勾选行
class AgreementRow extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;

  const AgreementRow({
    super.key,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CheckIcon(checked: checked),
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
