import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF3B82F6);

/// 带 label + 竖线分隔的底线输入行
class LabeledInput extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;

  const LabeledInput({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
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
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
