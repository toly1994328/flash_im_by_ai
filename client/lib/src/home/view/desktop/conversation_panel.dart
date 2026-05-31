import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_friend/flash_im_friend.dart';

/// 桌面端消息 Tab 左侧会话面板
class DesktopConversationPanel extends StatelessWidget {
  final ConversationListCubit convCubit;
  final String? activeConversationId;
  final VoidCallback onSearchTap;
  final VoidCallback onCreateGroupTap;
  final VoidCallback onAddFriendTap;
  final ValueChanged<Conversation> onConversationTap;

  const DesktopConversationPanel({
    super.key,
    required this.convCubit,
    this.activeConversationId,
    required this.onSearchTap,
    required this.onCreateGroupTap,
    required this.onAddFriendTap,
    required this.onConversationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(left: 12, right: 8, top: 14, bottom: 14),
          color: context.imTheme.headerColor,
          child: Row(
            children: [
              Expanded(
                child: DragMoveArea(
                  child: GestureDetector(
                    onTap: onSearchTap,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 16, color: Color(0xFFBBBBBB)),
                          SizedBox(width: 4),
                          Text('搜索', style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              WxPopupMenuButton(
                items: [
                  WxMenuItem(icon: Icons.group_add, text: '发起群聊', onTap: onCreateGroupTap),
                  WxMenuItem(icon: Icons.person_add, text: '加好友/群', onTap: onAddFriendTap),
                ],
                child: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocProvider.value(
            value: convCubit,
            child: BlocBuilder<FriendCubit, FriendState>(
              builder: (context, friendState) {
                return ConversationListPage(
                  onlineUserIds: friendState.onlineIds,
                  activeConversationId: activeConversationId,
                  onConversationTap: onConversationTap,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
