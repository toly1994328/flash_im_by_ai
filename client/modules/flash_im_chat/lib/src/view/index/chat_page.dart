import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_shared/flash_shared.dart' show ViewUserProfileEvent;
import '../../data/message.dart';
import '../../data/message_ext.dart';
import '../../logic/chat_cubit.dart';
import '../../logic/chat_group_cubit.dart';
import '../../logic/peer_status_cubit.dart';
import '../../logic/chat_state.dart';
import '../../logic/handler/chat_media_handler.dart';
import '../../logic/handler/chat_menu_handler.dart';
import '../notice/notice_banner.dart';
import 'chat_app_bar.dart';
import 'chat_page_config.dart';
import 'chat_disband_bar.dart';
import 'chat_empty.dart';
import 'chat_skeleton.dart';
import '../bubble/message_bubble.dart';
import '../menu/chat_multi_select_bar.dart';
import '../menu/select_checkbox.dart';
import '../input/chat_input.dart';
import '../input/chat_input_desktop.dart';
import '../menu/message_action_menu.dart';
import '../input/reply_preview_bar.dart';
import '../pinned/pinned_scope.dart';
import '../input/mention_picker.dart';
import '../../data/video_thumbnail_service.dart';
import '../info/read_receipt_detail.dart';
import '../../data/message_repository.dart';

/// 聊天主页面。
///
/// 负责组装聊天相关的各个 UI 区域，自身不持有业务状态。
///
/// ## 页面结构
///
/// ```
/// ┌─────────────────────────────┐
/// │  ChatAppBar                 │  标题 / 在线状态 / 操作按钮
/// ├─────────────────────────────┤
/// │  NoticeBanner (群聊)        │  群公告横幅（可选）
/// ├─────────────────────────────┤
/// │  PinnedScope                │  置顶消息栏（可选）
/// ├─────────────────────────────┤
/// │                             │
/// │  MessageList                │  消息列表（反向滚动）
/// │                             │
/// ├─────────────────────────────┤
/// │  InputSection / DisbandBar  │  输入区 或 已解散提示
/// └─────────────────────────────┘
/// ```
///
/// ## 状态来源
///
/// - [ChatCubit] — 消息列表、发送、多选、已读
/// - [ChatGroupCubit] — 群名、公告、解散状态、成员列表（仅群聊）
/// - [PeerStatusCubit] — 对端在线/离线（仅单聊）
///
/// ## 事件委托
///
/// - [ChatMediaHandler] — 图片/视频/文件的打开与下载
/// - [ChatMenuHandler] — 长按菜单事件分发（复制、转发、撤回等）
class ChatPage extends StatefulWidget {
  final ChatTarget target;
  final ChatViewOptions viewOptions;

  final VoidCallback? onToggleDetail;
  final VoidCallback? onAddMember;
  final VoidCallback? onGroupInfo;
  final VoidCallback? onSearchChat;

  const ChatPage({
    super.key,
    required this.target,
    this.viewOptions = const ChatViewOptions(),
    this.onToggleDetail,
    this.onAddMember,
    this.onGroupInfo,
    this.onSearchChat,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  late final ChatMediaHandler _mediaHandler;
  late final ChatMenuHandler _menuHandler;

  ChatTarget get _target => widget.target;
  ChatViewOptions get _opts => widget.viewOptions;
  bool get _isGroup => _target.isGroup;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final ChatCubit cubit = context.read<ChatCubit>();
    _mediaHandler = ChatMediaHandler(cubit: cubit, baseUrl: _opts.baseUrl);
    _menuHandler = ChatMenuHandler(
      cubit: cubit,
      media: _mediaHandler,
      conversationId: _target.conversationId,
      repositoryGetter: (ctx) => ctx.read<MessageRepository>(),
      baseUrl: _opts.baseUrl,
    );
    if (_isGroup) {
      final ChatGroupCubit groupCubit = context.read<ChatGroupCubit>();
      groupCubit.loadGroupDetail();
      groupCubit.loadGroupMembers();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ChatCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF6F6F6),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: ChatAppBar(
          target: _target,
          viewOptions: _opts,
          title: _isGroup
              ? context.select((ChatGroupCubit c) => c.state.title)
              : _target.peerName,
          isDisband: _isGroup
              ? context.select((ChatGroupCubit c) => c.state.isDisband)
              : false,
          isPeerOnline: (!_isGroup && _target.peerUserId != null)
              ? context.select((PeerStatusCubit c) => c.state)
              : false,
          onGroupInfo: widget.onGroupInfo,
          onAddMember: widget.onAddMember,
          onSearchChat: widget.onSearchChat,
        ),
        body: Container(
          color: Colors.white,
          child: Column(
            children: [
              if (_isGroup) _buildAnnouncementBanner(),
              const PinnedScope(),
              Expanded(child: _buildMessageArea()),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementBanner() {
    final String? notice = context.select((ChatGroupCubit c) => c.notice);
    if (notice == null) return const SizedBox.shrink();
    return NoticeBanner(notice: notice, onTap: widget.onGroupInfo);
  }

  Widget _buildMessageArea() {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        return switch (state) {
          ChatInitial() => const SizedBox.shrink(),
          ChatLoading() => ChatSkeleton(enable: !_opts.embedded),
          ChatError(:final message) => ChatErrorView(
            message: message,
            onRetry: () => context.read<ChatCubit>().loadMessages(),
          ),
          ChatLoaded(:final messages, :final hasMore) => messages.isEmpty
              ? const ChatEmpty()
              : _buildMessageList(messages, hasMore),
        };
      },
    );
  }

  Widget _buildBottomSection() {
    if (_isGroup) {
      final bool isDisband = context.select((ChatGroupCubit c) => c.state.isDisband);
      if (isDisband) return const ChatDisbandBar();
    }
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, chatState) {
        final ChatCubit cubit = context.read<ChatCubit>();
        if (chatState is ChatLoaded && chatState.isMultiSelect) {
          return const ChatMultiSelectBar();
        }
        return _buildInputSection(cubit, chatState);
      },
    );
  }

  Widget _buildInputSection(ChatCubit cubit, ChatState chatState) {
    final List<MentionMember>? groupMembers = _isGroup
        ? context.read<ChatGroupCubit>().state.members
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (chatState is ChatLoaded && chatState.replyTo != null)
          ReplyPreviewBar(
            senderName: chatState.replyTo!.senderName,
            content: chatState.replyTo!.contentSummary,
            onClose: () => cubit.clearReplyTo(),
          ),
        _opts.embedded
            ? ChatInputDesktop(
                controller: _inputController,
                isGroup: _isGroup,
                groupMembers: groupMembers,
                membersFetcher: _isGroup ? context.read<ChatGroupCubit>().fetchGroupMembers : null,
                onSend: (content) => cubit.sendMessage(content),
                onSendWithMentions: (content, mentions) => cubit.sendMessage(content, mentions: mentions),
                onSendImage: (path) => cubit.sendImageFromFile(path),
                onSendFile: (path) => cubit.sendFileFromPicker(path),
              )
            : ChatInput(
                controller: _inputController,
                isGroup: _isGroup,
                groupAvatar: _target.peerAvatar,
                groupMembers: groupMembers,
                membersFetcher: _isGroup ? context.read<ChatGroupCubit>().fetchGroupMembers : null,
                onSend: (content) => cubit.sendMessage(content),
                onSendWithMentions: (content, mentions) => cubit.sendMessage(content, mentions: mentions),
                onSendImage: (path) => cubit.sendImageFromFile(path),
                onSendVideo: _handleSendVideo,
                onSendFile: (path) => cubit.sendFileFromPicker(path),
                onSendAudio: (path, durationMs) => cubit.sendAudioFromFile(path, durationMs),
              ),
      ],
    );
  }

  static const int _shrinkWrapThreshold = 15;

  Widget _buildMessageList(List<Message> messages, bool hasMore) {
    final int itemCount = messages.length + (hasMore ? 1 : 0);
    final bool useShrinkWrap = messages.length <= _shrinkWrapThreshold;

    Widget list = ListView.builder(
      controller: _scrollController,
      reverse: true,
      shrinkWrap: useShrinkWrap,
      padding: EdgeInsets.only(
        top: 12, bottom: 8,
        left: _opts.embedded ? 12 : 0,
        right: _opts.embedded ? 12 : 0,
      ),
      itemCount: itemCount,
      itemBuilder: (_, index) {
        if (index >= messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final Message msg = messages[messages.length - 1 - index];
        final ChatCubit chatCubit = context.read<ChatCubit>();
        final bool isMe = msg.senderId == chatCubit.currentUserId;
        final ChatState chatState = chatCubit.state;
        final double? progress = (chatState is ChatLoaded) ? chatState.uploadProgress : null;
        final bool isInMultiSelect = (chatState is ChatLoaded) && chatState.isMultiSelect;
        final bool isSelected = (chatState is ChatLoaded) && chatState.selectedIds.contains(msg.id);

        final Widget bubble = MessageBubble(
          message: msg,
          isMe: isMe,
          baseUrl: _opts.baseUrl,
          uploadProgress: (msg.status == MessageStatus.sending) ? progress : null,
          fileDownloadInfo: (chatState is ChatLoaded) ? chatState.fileDownloads[msg.id] : null,
          peerReadSeq: chatCubit.peerReadSeq,
          membersReadSeq: chatCubit.membersReadSeq,
          currentUserId: chatCubit.currentUserId,
          isGroup: _isGroup,
          isMultiSelect: isInMultiSelect,
          isSelected: isSelected,
          onToggleSelect: () => chatCubit.toggleSelect(msg.id),
          onLongPress: (bubbleCtx) => _showMessageMenu(context, bubbleCtx, msg, isMe),
          onAction: (action) => _menuHandler.handle(context, msg, isMe, action),
          onReEdit: _handleReEdit,
          onAvatarTap: _openUserProfile,
          onReadCountTap: _isGroup ? () => _showReadReceipt(msg.id) : null,
          onImageTap: () {
            final List<Message> imageList = messages.where((m) => m.type == MessageType.image && m.status != MessageStatus.sending).toList();
            final int idx = imageList.indexWhere((m) => m.id == msg.id);
            _mediaHandler.openImage(context, msg, imageMessages: imageList, index: idx >= 0 ? idx : 0);
          },
          onVideoTap: () => _mediaHandler.openVideo(context, msg),
          onFileTap: () => _mediaHandler.openFile(context, msg),
        );

        return GestureDetector(
          behavior: isInMultiSelect ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
          onTap: isInMultiSelect ? () => chatCubit.toggleSelect(msg.id) : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SelectCheckbox(visible: isInMultiSelect, selected: isSelected),
              Expanded(child: bubble),
            ],
          ),
        );
      },
    );

    if (useShrinkWrap) {
      list = Align(alignment: Alignment.topCenter, child: list);
    }
    return list;
  }


  Future<void> _handleSendVideo(String path) async {
    final info = await VideoThumbnailService().extractVideoInfo(path);
    if (!mounted) return;
    context.read<ChatCubit>().sendVideoFromFile(
      path, info.thumbnailPath, info.durationMs,
      width: info.width, height: info.height,
    );
  }

  void _handleReEdit(String content) {
    _inputController.text = content;
    _inputController.selection = TextSelection.collapsed(offset: content.length);
  }

  void _openUserProfile(String userId, String nickname, String? avatar) {
    ViewUserProfileEvent(userId: userId, nickname: nickname, avatar: avatar).emit();
  }

  void _showMessageMenu(BuildContext context, BuildContext bubbleContext, Message msg, bool isMe) {
    final ChatCubit chatCubit = context.read<ChatCubit>();
    final ChatState chatState = chatCubit.state;
    if (chatState is ChatLoaded && chatState.isMultiSelect) return;

    final RenderBox? renderBox = bubbleContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Size bubbleSize = renderBox.size;
    final Offset bubbleOffset = renderBox.localToGlobal(Offset.zero);

    final VoidCallback? dismiss = MessageActionMenu.show(
      context: context,
      position: Offset(bubbleOffset.dx, bubbleOffset.dy),
      bubbleSize: bubbleSize,
      message: msg,
      isMe: isMe,
      isGroup: _isGroup,
      isPinned: _menuHandler.isMessagePinned(msg.id),
      onAction: (action) => _menuHandler.handle(context, msg, isMe, action),
    );

    if (dismiss != null) {
      void onScroll() {
        dismiss();
        _scrollController.removeListener(onScroll);
      }
      _scrollController.addListener(onScroll);
    }
  }

  void _showReadReceipt(String messageId) {
    final MessageRepository repository = context.read<MessageRepository>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReadReceiptDetailSheet(
        messageId: messageId,
        conversationId: _target.conversationId,
        baseUrl: _opts.baseUrl,
        fetcher: () async {
          return await repository.getReadStatus(_target.conversationId, messageId);
        },
      ),
    );
  }

}
