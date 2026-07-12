import 'package:flutter/material.dart';
import 'package:tolyui_feedback_modal/tolyui_feedback_modal.dart';

/// 删除会话确认弹窗 & 清空所有会话确认弹窗
class ConversationDeleteDialog {
  /// 删除单个会话确认
  static Future<bool> showDeleteConfirm(
    BuildContext context, {
    required String name,
  }) async {
    final result = await showTolyPopPicker<bool>(
      context: context,
      title: Text('确定删除与「$name」的会话？'),
      tasks: [
        TolyMenuItem(
          info: '删除',
          content: const Text(
            '删除',
            style: TextStyle(color: Color(0xFFFF4D4F), fontSize: 16),
          ),
          task: () => true,
        ),
      ],
    );
    return result == true;
  }

  /// 清空当前会话聊天记录确认
  static Future<bool> showClearAllConfirm(BuildContext context, {required String name}) async {
    final result = await showTolyPopPicker<bool>(
      context: context,
      title: Text('确定清空与「$name」的聊天记录？'),
      tasks: [
        TolyMenuItem(
          info: '清空聊天记录',
          content: const Text(
            '清空聊天记录',
            style: TextStyle(color: Color(0xFFFF4D4F), fontSize: 16),
          ),
          task: () => true,
        ),
      ],
    );
    return result == true;
  }
}
