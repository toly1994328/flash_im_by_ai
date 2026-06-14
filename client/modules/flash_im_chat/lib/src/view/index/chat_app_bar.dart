import 'package:flutter/material.dart';
import 'package:fx_env/fx_env.dart';
import 'package:window_manager/window_manager.dart';

import 'chat_page_config.dart';
import '../info/private_chat_info_page.dart';

/// 聊天页 AppBar（独立组件）
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatTarget target;
  final ChatViewOptions viewOptions;
  final String title;
  final bool isDisband;
  final bool isPeerOnline;
  final VoidCallback? onGroupInfo;
  final VoidCallback? onAddMember;
  final VoidCallback? onSearchChat;

  const ChatAppBar({
    super.key,
    required this.target,
    required this.title,
    this.viewOptions = const ChatViewOptions(),
    this.isDisband = false,
    this.isPeerOnline = false,
    this.onGroupInfo,
    this.onAddMember,
    this.onSearchChat,
  });

  bool get _embedded => viewOptions.embedded;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (_embedded ? 0.5 : 0),
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: _embedded ? const DragToMoveArea(child: SizedBox.expand()) : null,
      backgroundColor: _embedded ? Colors.white : null,
      centerTitle: !_embedded,
      titleSpacing: _embedded ? 24 : null,
      automaticallyImplyLeading: !_embedded,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: _embedded
          ? const PreferredSize(
              preferredSize: Size.fromHeight(0.5),
              child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFE8E8E8)),
            )
          : null,
      title: _buildTitle(),
      actions: _buildActions(context),
    );
  }

  Widget _buildTitle() {
    if (!target.isGroup && target.peerUserId != null) {
      return Column(
        crossAxisAlignment: _embedded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: _embedded ? 14 : 16)),
          Text(
            isPeerOnline ? '在线' : '离线',
            style: TextStyle(
              fontSize: 11,
              color: isPeerOnline ? const Color(0xFF4CAF50) : const Color(0xFFBBBBBB),
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      );
    }
    return Text(title, style: TextStyle(fontSize: _embedded ? 14 : null));
  }

  List<Widget> _buildActions(BuildContext context) {
    if (_embedded) {
      return [
        if (kApp.isWindows) const SizedBox(width: 174),
      ];
    }
    return [
      if (!target.isGroup)
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PrivateChatInfoPage(
                  peerName: target.peerName,
                  peerAvatar: target.peerAvatar,
                  peerUserId: target.peerUserId,
                  onAddMember: onAddMember,
                  onSearchChat: onSearchChat,
                ),
              ),
            );
          },
        ),
      if (target.isGroup && !isDisband)
        IconButton(
          icon: const Icon(Icons.group),
          onPressed: () => onGroupInfo?.call(),
        ),
    ];
  }
}
