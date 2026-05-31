import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:flash_im_chat/flash_im_chat.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_friend/flash_im_friend.dart';
import 'package:flash_im_group/flash_im_group.dart';
import 'package:flash_im_search/flash_im_search.dart';
import 'package:flash_shared/flash_shared.dart';
import '../../profile/feedback_page.dart';
import '../../profile/settings_page.dart';

/// 桌面端弹窗操作 mixin
///
/// 集中管理所有 showDialog / showMenu 操作，避免主文件膨胀。
mixin DesktopActionsMixin<T extends StatefulWidget> on State<T> {
  /// 弹窗方式发起群聊
  void showCreateGroupDialog(BuildContext ctx, List<SelectableMember> members, ValueChanged<Conversation> onCreated) {
    final screenHeight = MediaQuery.of(ctx).size.height;
    final dialogHeight = (screenHeight * 0.8).clamp(0.0, 800.0);
    showDialog(
      context: ctx,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 420,
            height: dialogHeight,
            child: CreateGroupPage(
              members: members,
              onCreated: (result) async {
                Navigator.of(dialogContext).pop();
                try {
                  final conv = await ctx.read<GroupRepository>()
                      .createGroup(name: result.name, memberIds: result.memberIds);
                  if (!ctx.mounted) return;
                  onCreated(conv);
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('创建群聊失败：$e')),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 弹窗方式加好友/群
  void showAddFriendDialog(BuildContext ctx) {
    final screenHeight = MediaQuery.of(ctx).size.height;
    final dialogHeight = (screenHeight * 0.8).clamp(0.0, 800.0);
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 420,
            height: dialogHeight,
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => UserSearchPage(
                  repository: ctx.read<FriendRepository>(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 弹窗方式打开综合搜索
  void showSearchDialog(
    BuildContext ctx, {
    required void Function(String friendId) onFriendTap,
    required void Function(String conversationId) onGroupTap,
    required void Function(String conversationId, String? messageId) onMessageTap,
  }) {
    final screenHeight = MediaQuery.of(ctx).size.height;
    final dialogHeight = (screenHeight * 0.8).clamp(0.0, 800.0);
    showDialog(
      context: ctx,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 480,
            height: dialogHeight,
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => SearchPage(
                  repository: ctx.read<SearchRepository>(),
                  embedded: true,
                  onClose: () => Navigator.of(dialogContext).pop(),
                  onFriendTap: (id) {
                    Navigator.of(dialogContext).pop();
                    onFriendTap(id);
                  },
                  onGroupTap: (id) {
                    Navigator.of(dialogContext).pop();
                    onGroupTap(id);
                  },
                  onMessageTap: (convId, msgId) {
                    Navigator.of(dialogContext).pop();
                    onMessageTap(convId, msgId);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 底部菜单弹出
  void showSettingsMenu(BuildContext ctx) {
    final screenHeight = MediaQuery.of(ctx).size.height;
    final position = RelativeRect.fromLTRB(
      68,
      screenHeight - 220,
      0,
      40,
    );
    showMenu<String>(
      context: ctx,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      elevation: 8,
      items: [
        const PopupMenuItem(value: 'settings', child: Text('系统设置')),
        const PopupMenuItem(value: 'feedback', child: Text('意见反馈')),
        const PopupMenuItem(value: 'logout', child: Text('退出登录', style: TextStyle(color: Color(0xFFF44336)))),
      ],
    ).then((value) {
      if (value == null || !ctx.mounted) return;
      switch (value) {
        case 'settings':
          showSettingsDialogAction(ctx);
        case 'feedback':
          showFeedbackDialog(ctx);
        case 'logout':
          logoutAction(ctx);
      }
    });
  }

  void showSettingsDialogAction(BuildContext ctx) {
    final hasPassword = ctx.read<SessionCubit>().state.hasPassword;
    final screenHeight = MediaQuery.of(ctx).size.height;
    final dialogHeight = (screenHeight * 0.8).clamp(0.0, 800.0);
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 420,
            height: dialogHeight,
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: ctx.read<SessionCubit>(),
                  child: SettingsPage(hasPassword: hasPassword),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showFeedbackDialog(BuildContext ctx, {ValueChanged<String>? onSent}) {
    final screenHeight = MediaQuery.of(ctx).size.height;
    final dialogHeight = (screenHeight * 0.6).clamp(0.0, 500.0);
    showDialog(
      context: ctx,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 420,
            height: dialogHeight,
            child: MultiRepositoryProvider(
              providers: [
                RepositoryProvider.value(value: ctx.read<ConversationRepository>()),
                RepositoryProvider.value(value: ctx.read<MessageRepository>()),
                RepositoryProvider.value(value: ctx.read<WsClient>()),
              ],
              child: BlocProvider.value(
                value: ctx.read<SessionCubit>(),
                child: FeedbackPage(
                  onSent: (convId) {
                    Navigator.of(dialogContext).pop();
                    onSent?.call(convId);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> logoutAction(BuildContext ctx) async {
    ctx.read<WsClient>().disconnect();
    await ctx.read<SessionCubit>().deactivate();
    if (!ctx.mounted) return;
    GoRouter.of(ctx).go('/login');
  }
}
