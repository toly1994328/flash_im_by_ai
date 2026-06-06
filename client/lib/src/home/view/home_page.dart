import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tolyui_rx_layout/tolyui_rx_layout.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_friend/flash_im_friend.dart';
import 'package:flash_im_group/flash_im_group.dart';
import 'package:flash_im_chat/flash_im_chat.dart';
import '../../../main.dart' show globalSyncEngine;
import '../../update/update_trigger.dart';
import 'home_actions_mixin.dart';
import 'mobile_layout.dart';
import 'desktop/desktop_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with HomeActionsMixin {
  bool _hasShownPasswordGuide = false;
  late final ConversationListCubit _convCubit;
  late final GroupNotificationCubit _groupNotifCubit;

  @override
  ConversationListCubit get convCubit => _convCubit;

  GroupNotificationCubit get groupNotifCubit => _groupNotifCubit;

  @override
  void initState() {
    super.initState();
    _convCubit = ConversationListCubit(
      context.read<ConversationRepository>(),
      wsClient: context.read<WsClient>(),
    )..loadConversations();
    context.read<FriendCubit>().loadFriends();

    final se = globalSyncEngine;
    if (se != null) {
      se.onConversationChanged = () => _convCubit.loadConversations();
      se.onFriendListChanged = () => context.read<FriendCubit>().loadFriends();
      se.onMentionMe = (convId, mentionId) {
        final isAll = mentionId.endsWith(':all');
        final msgId = mentionId.split(':').first;
        _convCubit.addMentionMe(convId, MentionMeRecord(
          messageId: msgId,
          type: isAll ? MentionType.all : MentionType.me,
        ));
      };
    }
    _groupNotifCubit = GroupNotificationCubit(
      repository: context.read<GroupRepository>(),
      groupJoinRequestStream: context.read<WsClient>().groupJoinRequestStream,
    )..loadPendingCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPasswordGuide();
      _checkUpdate();
    });
  }

  void _checkUpdate() {
    UpdateTrigger(dio: context.read<MessageRepository>().dio)
        .checkAndPrompt(context);
  }

  void _checkPasswordGuide() {
    final state = context.read<SessionCubit>().state;
    if (state.status == SessionStatus.active &&
        !state.hasPassword &&
        !_hasShownPasswordGuide) {
      _hasShownPasswordGuide = true;
      _showPasswordGuideDialog();
    }
  }

  void _showPasswordGuideDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.white,
        title: const Text('设置密码'),
        content: const Text('建议设置密码，方便下次快速登录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('跳过'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<SessionCubit>(),
                    child: const SetPasswordPage(),
                  ),
                ),
              );
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Rx$(
      mobile: (_) => MobileLayout(homeState: this),
      desktop: (_) => DesktopLayout(homeState: this),
    );
  }
}
