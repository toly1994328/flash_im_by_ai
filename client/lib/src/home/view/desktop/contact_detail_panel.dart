import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_friend/flash_im_friend.dart';
import 'package:flash_im_group/flash_im_group.dart';
import '../../../application/config.dart';
import '../home_page.dart';

/// 桌面端通讯录 Tab 右侧面板
class DesktopContactDetailPanel extends StatelessWidget {
  final String? panelType;
  final Friend? selectedFriend;
  final HomePageState homeState;
  final VoidCallback onAddFriendTap;
  final ValueChanged<Conversation> onConversationTap;
  final VoidCallback onFriendDeleted;
  final VoidCallback onSendMessage;

  const DesktopContactDetailPanel({
    super.key,
    this.panelType,
    this.selectedFriend,
    required this.homeState,
    required this.onAddFriendTap,
    required this.onConversationTap,
    required this.onFriendDeleted,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (panelType == 'requests') {
      return BlocProvider.value(
        value: context.read<FriendCubit>(),
        child: FriendRequestPage(
          showAppBar: false,
          onAddFriendTap: onAddFriendTap,
        ),
      );
    }
    if (panelType == 'groups') {
      return MyGroupsPage(
        repository: context.read<ConversationRepository>(),
        showAppBar: false,
        onGroupTap: onConversationTap,
      );
    }
    if (panelType == 'notifications') {
      return GroupNotificationsPage(
        repository: context.read<GroupRepository>(),
        baseUrl: AppConfig.baseUrl,
        notificationCubit: homeState.groupNotifCubit,
        showAppBar: false,
      );
    }

    if (selectedFriend == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 64, color: Color(0xFFDDDDDD)),
            SizedBox(height: 16),
            Text('选择一个好友查看详情', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
          ],
        ),
      );
    }

    return FriendDetailPage(
      key: ValueKey(selectedFriend!.friendId),
      friend: selectedFriend!,
      embedded: true,
      onSendMessage: onSendMessage,
      onDeleteFriend: onFriendDeleted,
    );
  }
}
