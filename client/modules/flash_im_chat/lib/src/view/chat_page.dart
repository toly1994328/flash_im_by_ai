import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flash_im_core/flash_im_core.dart' show WsClient, WsFrame, WsFrameType, GroupInfoUpdate, UserStatusNotification;
import '../data/message.dart';
import '../logic/chat_cubit.dart';
import '../logic/chat_state.dart';
import 'bubble/message_bubble.dart';
import 'chat_input.dart';
import 'image_preview_page.dart';
import 'video_player_page.dart';
import 'file_preview_page.dart';
import '../data/video_thumbnail_service.dart';
import 'private_chat_info_page.dart';
import 'read_receipt_detail.dart';
import '../data/message_repository.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String peerName;
  final String? peerAvatar;
  final String? baseUrl;
  final bool isGroup;
  final String? peerUserId;
  final VoidCallback? onAddMember;
  final VoidCallback? onGroupInfo;
  final bool isDisband;
  final String? announcement;

  /// 群详情获取器（群聊时由外部注入，返回 {status, announcement}）
  final Future<Map<String, dynamic>> Function()? groupDetailFetcher;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.peerName,
    this.peerAvatar,
    this.baseUrl,
    this.isGroup = false,
    this.peerUserId,
    this.onAddMember,
    this.onGroupInfo,
    this.isDisband = false,
    this.announcement,
    this.groupDetailFetcher,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scrollController = ScrollController();
  late String _title;
  late bool _isDisband;
  String? _announcement;
  StreamSubscription? _groupInfoSub;
  StreamSubscription? _onlineSub;
  StreamSubscription? _offlineSub;
  bool _isPeerOnline = false;

  @override
  void initState() {
    super.initState();
    _title = widget.peerName;
    _isDisband = widget.isDisband;
    _announcement = widget.announcement;
    _scrollController.addListener(_onScroll);
    // 监听 GROUP_INFO_UPDATE 推送，实时同步群名/公告/解散状态
    _groupInfoSub = context.read<WsClient>().groupInfoUpdateStream.listen((frame) {
      final update = GroupInfoUpdate.fromBuffer(frame.payload);
      if (update.conversationId != widget.conversationId) return;
      if (mounted) {
        setState(() {
          if (update.hasName()) _title = update.name;
          if (update.hasAnnouncement()) _announcement = update.announcement;
          if (update.hasStatus()) _isDisband = update.status == 1;
        });
      }
    });
    // 单聊：监听对方在线/离线状态
    if (!widget.isGroup && widget.peerUserId != null) {
      final wsClient = context.read<WsClient>();
      _isPeerOnline = wsClient.isUserOnline(widget.peerUserId!);
      _onlineSub = wsClient.userOnlineStream.listen((frame) {
        final notif = UserStatusNotification.fromBuffer(frame.payload);
        if (notif.userId == widget.peerUserId && mounted) {
          setState(() => _isPeerOnline = true);
        }
      });
      _offlineSub = wsClient.userOfflineStream.listen((frame) {
        final notif = UserStatusNotification.fromBuffer(frame.payload);
        if (notif.userId == widget.peerUserId && mounted) {
          setState(() => _isPeerOnline = false);
        }
      });
    }
    // 群聊时异步拉取群详情（公告 + 解散状态）
    if (widget.isGroup && widget.groupDetailFetcher != null) {
      _loadGroupDetail();
    }
  }

  Future<void> _loadGroupDetail() async {
    try {
      final detail = await widget.groupDetailFetcher!();
      if (!mounted) return;
      final status = detail['status'] as int? ?? 0;
      final announcement = detail['announcement'] as String?;
      setState(() {
        _isDisband = status == 1;
        _announcement = announcement;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _groupInfoSub?.cancel();
    _onlineSub?.cancel();
    _offlineSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // reverse 列表：position.pixels 接近 maxScrollExtent 时是往上滚（加载历史）
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
        appBar: AppBar(
          title: !widget.isGroup && widget.peerUserId != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_title, style: const TextStyle(fontSize: 16)),
                    Text(
                      _isPeerOnline ? '在线' : '离线',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isPeerOnline
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFBBBBBB),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                )
              : Text(_title),
          actions: [
            if (!widget.isGroup)
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PrivateChatInfoPage(
                      peerName: widget.peerName,
                      peerAvatar: widget.peerAvatar,
                      peerUserId: widget.peerUserId,
                      onAddMember: widget.onAddMember,
                    ),
                  ),
                ),
              ),
            if (widget.isGroup && !_isDisband)
              IconButton(
                icon: const Icon(Icons.group),
                onPressed: () => widget.onGroupInfo?.call(),
              ),
          ],
        ),
        body: Container(
          color: Colors.white,
          child: Column(
            children: [
              // 群公告横幅
              if (widget.isGroup && !_isDisband &&
                  _announcement != null && _announcement!.isNotEmpty)
                GestureDetector(
                  onTap: () => widget.onGroupInfo?.call(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF9E6),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEEE6CC), width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_outlined, color: Color(0xFFE6A817), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _announcement!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 16),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: BlocBuilder<ChatCubit, ChatState>(
                  builder: (context, state) {
                    return switch (state) {
                      ChatInitial() => const SizedBox.shrink(),
                      ChatLoading() => _buildSkeleton(),
                      ChatError(:final message) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(message, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.read<ChatCubit>().loadMessages(),
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                      ChatLoaded(:final messages, :final hasMore, :final isLoadingMore) =>
                        messages.isEmpty
                          ? const Center(child: Text('暂无消息', style: TextStyle(color: Colors.grey)))
                          : _buildMessageList(messages, hasMore),
                    };
                  },
                ),
              ),
              if (_isDisband)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: const Color(0xFFF0F0F0),
                  alignment: Alignment.center,
                  child: const Text(
                    '该群聊已解散',
                    style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  ),
                )
              else
                ChatInput(
                  onSend: (content) => context.read<ChatCubit>().sendMessage(content),
                  onSendImage: (path) => context.read<ChatCubit>().sendImageFromFile(path),
                  onSendVideo: (path) async {
                    final info = await VideoThumbnailService().extractVideoInfo(path);
                    if (context.mounted) {
                      context.read<ChatCubit>().sendVideoFromFile(
                        path, info.thumbnailPath, info.durationMs,
                        width: info.width, height: info.height,
                      );
                    }
                  },
                  onSendFile: (path) => context.read<ChatCubit>().sendFileFromPicker(path),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 消息少时 shrinkWrap 靠顶，消息多时普通滚动（避免性能问题）
  static const _shrinkWrapThreshold = 15;

  Widget _buildMessageList(List<Message> messages, bool hasMore) {
    final itemCount = messages.length + (hasMore ? 1 : 0);
    final useShrinkWrap = messages.length <= _shrinkWrapThreshold;

    Widget list = ListView.builder(
      controller: _scrollController,
      reverse: true,
      shrinkWrap: useShrinkWrap,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      itemCount: itemCount,
      itemBuilder: (_, index) {
        if (index >= messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
          );
        }
        final msg = messages[messages.length - 1 - index];
        final isMe = msg.senderId == context.read<ChatCubit>().currentUserId;
        final chatCubit = context.read<ChatCubit>();
        final chatState = chatCubit.state;
        final progress = (chatState is ChatLoaded) ? chatState.uploadProgress : null;

        String fullUrl(String url) =>
            (widget.baseUrl != null && url.startsWith('/')) ? '${widget.baseUrl}$url' : url;

        return MessageBubble(
          message: msg,
          isMe: isMe,
          baseUrl: widget.baseUrl,
          uploadProgress: (msg.status == MessageStatus.sending) ? progress : null,
          fileDownloadInfo: (chatState is ChatLoaded) ? chatState.fileDownloads[msg.id] : null,
          peerReadSeq: chatCubit.peerReadSeq,
          membersReadSeq: chatCubit.membersReadSeq,
          currentUserId: chatCubit.currentUserId,
          isGroup: widget.isGroup,
          onReadCountTap: widget.isGroup ? () {
            _showReadReceiptDetail(msg.id);
          } : null,
          onImageTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ImagePreviewPage(imageUrl: fullUrl(msg.content)),
          )),
          onVideoTap: () {
            final videoUrl = fullUrl(msg.content);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VideoPlayerPage(videoUrl: videoUrl),
            ));
          },
          onFileTap: () {
            final fileExtra = msg.fileExtra;
            if (fileExtra != null) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<ChatCubit>(),
                  child: FilePreviewPage(
                    messageId: msg.id,
                    fileExtra: fileExtra,
                    baseUrl: widget.baseUrl ?? '',
                  ),
                ),
              ));
            }
          },
        );
      },
    );

    if (useShrinkWrap) {
      list = Align(alignment: Alignment.topCenter, child: list);
    }
    return list;
  }

  void _showReadReceiptDetail(String messageId) {
    final repository = context.read<MessageRepository>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReadReceiptDetailSheet(
        messageId: messageId,
        conversationId: widget.conversationId,
        baseUrl: widget.baseUrl,
        fetcher: () async {
          final res = await repository.getReadStatus(
            widget.conversationId,
            messageId,
          );
          return res;
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        reverse: true,
        itemCount: 8,
        itemBuilder: (_, index) {
          final isMe = index % 3 == 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Container(
                  width: 120 + (index % 3) * 40,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
