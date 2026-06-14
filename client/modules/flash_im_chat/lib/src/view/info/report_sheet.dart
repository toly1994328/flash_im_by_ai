import 'package:flutter/material.dart';
import 'package:fx_env/fx_env.dart';

/// 举报原因枚举
enum ReportReason {
  pornography(0, '色情低俗'),
  violence(1, '暴力恐怖'),
  harassment(2, '骚扰辱骂'),
  fraud(3, '诈骗信息'),
  other(4, '其他');

  final int value;
  final String label;
  const ReportReason(this.value, this.label);
}

/// 举报原因选择（微信风格）
class ReportSheet extends StatefulWidget {
  final String targetId;
  final int targetType;
  final Future<void> Function(int reason, String? description) onSubmit;

  const ReportSheet({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.onSubmit,
  });

  static void show({
    required BuildContext context,
    required String targetId,
    required int targetType,
    required Future<void> Function(int reason, String? description) onSubmit,
  }) {
    final Widget sheet = ReportSheet(
      targetId: targetId,
      targetType: targetType,
      onSubmit: onSubmit,
    );

    if (kApp.isDesktop) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: sheet,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        builder: (_) => sheet,
      );
    }
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  ReportReason? _selected;
  final TextEditingController _descController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _submitting = true);
    try {
      final String? desc = _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim();
      await widget.onSubmit(_selected!.value, desc);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('举报已提交，我们会尽快处理'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部把手 + 标题
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('请选择举报原因', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          const SizedBox(height: 4),
          const Text('我们将在24小时内处理您的举报', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
          const SizedBox(height: 16),
          // 原因列表
          ...ReportReason.values.map(_buildReasonItem),
          // 补充说明
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _descController,
              maxLines: 2,
              maxLength: 200,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: '补充说明（可选）',
                hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                counterStyle: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
              ),
            ),
          ),
          // 提交按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: _selected == null || _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  disabledBackgroundColor: const Color(0xFFB0D4FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('提交', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonItem(ReportReason reason) {
    final bool isSelected = _selected == reason;
    return InkWell(
      onTap: () => setState(() => _selected = reason),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: const Color(0xFFF0F0F0), width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(reason.label, style: const TextStyle(fontSize: 16, color: Color(0xFF333333)))),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFCCCCCC),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
