import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/message.dart';
import '../../logic/chat_cubit.dart';
import 'pinned_message_bar.dart';

/// 置顶消息作用域：自动监听 pinnedMessages 变化，有数据则显示 PinnedMessageBar
class PinnedScope extends StatelessWidget {
  const PinnedScope({super.key});

  @override
  Widget build(BuildContext context) {
    final List<PinnedMessage> pinned = context.select(
      (ChatCubit cubit) => cubit.pinnedMessages,
    );
    if (pinned.isEmpty) return const SizedBox.shrink();
    return PinnedMessageBar(
      pinnedMessages: pinned,
      isOwner: true,
      onUnpin: (pinId) => context.read<ChatCubit>().unpinMessage(pinId),
    );
  }
}
