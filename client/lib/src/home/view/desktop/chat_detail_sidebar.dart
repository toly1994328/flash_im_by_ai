import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_im_chat/flash_im_chat.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_group/flash_im_group.dart';
import 'package:flash_im_search/flash_im_search.dart';
import '../../../application/config.dart';
import '../home_page.dart';

/// 桌面端聊天详情侧栏内容（独立 Navigator）
class ChatDetailSidebar extends StatelessWidget {
  final Conversation conversation;
  final HomePageState homeState;
  final VoidCallback onLeaveOrDisband;

  const ChatDetailSidebar({
    super.key,
    required this.conversation,
    required this.homeState,
    required this.onLeaveOrDisband,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: ValueKey('detail_${conversation.id}'),
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (navContext) {
          if (conversation.isGroup) {
            return GroupChatInfoPage(
              repository: context.read<GroupRepository>(),
              conversationId: conversation.id,
              baseUrl: AppConfig.baseUrl,
              currentUserId: context.read<SessionCubit>().state.user?.userId.toString(),
              friendsFetcher: () async => homeState.friendsToMembers(),
              showAppBar: false,
              onLeaveOrDisband: onLeaveOrDisband,
              onSearchChat: () => _pushSearch(navContext, context),
            );
          }
          return PrivateChatInfoPage(
            peerName: conversation.displayName,
            peerAvatar: conversation.displayAvatar,
            peerUserId: conversation.peerUserId,
            showAppBar: false,
            onAddMember: () => homeState.createGroupFromChat(context, conversation),
            onSearchChat: () => _pushSearch(navContext, context),
          );
        },
      ),
    );
  }

  void _pushSearch(BuildContext navContext, BuildContext rootContext) {
    Navigator.of(navContext).push(MaterialPageRoute(
      builder: (_) => ConversationSearchPage(
        conversationId: conversation.id,
        conversationName: conversation.displayName,
        repository: rootContext.read<SearchRepository>(),
        onMessageTap: (convId, msgId) => Navigator.of(navContext).pop(),
      ),
    ));
  }
}
