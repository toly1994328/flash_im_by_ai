import 'package:flutter/material.dart';

import 'update_info.dart';

/// 更新提示对话框
///
/// 参考 LinkNode 风格：顶部渐变色头部 + 更新内容 + 底部按钮栏
class UpdateDialog extends StatelessWidget {
  final UpdateInfo info;
  final VoidCallback onUpdate;
  final VoidCallback? onDismiss;

  const UpdateDialog({
    super.key,
    required this.info,
    required this.onUpdate,
    this.onDismiss,
  });

  /// 便捷方法：弹出更新对话框
  static Future<void> show(
    BuildContext context, {
    required UpdateInfo info,
    required VoidCallback onUpdate,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (_) => UpdateDialog(
        info: info,
        onUpdate: onUpdate,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildContent(),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '发现新版本 v${info.version}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 200),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info.fileSizeText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      info.fileSizeText,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            const Text(
              '更新内容：',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              info.releaseNotes.isNotEmpty ? info.releaseNotes : '修复已知问题，提升稳定性',
              style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (!info.forceUpdate)
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  onDismiss?.call();
                },
                child: const Center(
                  child: Text(
                    '稍后再说',
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ),
              ),
            ),
          if (!info.forceUpdate)
            Container(width: 1, height: 50, color: Colors.grey.shade200),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                onUpdate();
              },
              child: const Center(
                child: Text(
                  '立即升级',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
