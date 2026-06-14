import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 设置项（带箭头 + 可选值）
class SettingItem extends StatelessWidget {
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingItem({super.key, required this.title, this.value, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: Colors.white,
        child: ListTile(
          title: Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF333333))),
          trailing: trailing ?? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(value!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                color: onTap != null ? const Color(0xFFCCCCCC) : Colors.transparent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Switch 设置项（iOS 风格）
class SwitchItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SwitchItem({super.key, required this.title, this.subtitle, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF333333))),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 56, height: 32,
            child: FittedBox(
              fit: BoxFit.contain,
              child: CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: const Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 分割线
class SettingDivider extends StatelessWidget {
  const SettingDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16),
      child: Divider(height: 0.5, thickness: 0.5, color: Colors.grey[200]),
    );
  }
}
