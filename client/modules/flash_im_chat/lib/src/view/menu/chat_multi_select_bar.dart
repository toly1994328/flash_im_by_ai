import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tolyui_feedback_modal/tolyui_feedback_modal.dart';

import '../../logic/chat_cubit.dart';
import '../../logic/chat_state.dart';

/// 多选操作栏（底部：取消 / 已选 N 条 / 删除）
class ChatMultiSelectBar extends StatelessWidget {
  const ChatMultiSelectBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatCubit cubit = context.read<ChatCubit>();
    final int count = context.select(
      (ChatCubit c) => c.state is ChatLoaded ? (c.state as ChatLoaded).selectedIds.length : 0,
    );

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
        ),
        child: Row(
          children: [
            TextButton(
              onPressed: () => cubit.exitMultiSelect(),
              child: const Text('取消', style: TextStyle(color: Color(0xFF999999))),
            ),
            const Spacer(),
            Text('已选择 $count 条', style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
            const Spacer(),
            TextButton(
              onPressed: count > 0 ? () => _confirmDelete(context, cubit, count) : null,
              child: Text('删除', style: TextStyle(color: count > 0 ? Colors.red : const Color(0xFFCCCCCC))),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ChatCubit cubit, int count) {
    showTolyPopPicker<bool>(
      context: context,
      title: Text('确定删除选中的 $count 条消息？'),
      tasks: [
        TolyMenuItem(
          info: '删除',
          content: const Text('删除', style: TextStyle(color: Color(0xFFFF4D4F), fontSize: 16)),
          task: () {
            cubit.deleteSelected();
            return true;
          },
        ),
      ],
    );
  }
}
