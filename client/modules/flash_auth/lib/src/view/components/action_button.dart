import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF3B82F6);

/// 登录/确认按钮 — 灰色禁用态 / 蓝色可用态
class ActionButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final String text;
  final VoidCallback? onPressed;

  const ActionButton({
    super.key,
    required this.enabled,
    this.loading = false,
    this.text = '登录',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: enabled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(text, style: const TextStyle(fontSize: 16)),
            )
          : OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Text(text, style: TextStyle(fontSize: 16, color: Colors.grey[400])),
            ),
    );
  }
}
