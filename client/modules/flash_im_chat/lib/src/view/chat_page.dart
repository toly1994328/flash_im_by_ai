import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
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

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String peerName;
  final String? peerAvatar;
  final String? baseUrl;
  final bool isGroup;
  final String? peerUserId;
  final VoidCallback? onAddMember;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.peerName,
    this.peerAvatar,
    this.baseUrl,
    this.isGroup = false,
    this.peerUserId,
    this.onAddMember,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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
          title: Text(widget.peerName),
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
            if (widget.isGroup)
              IconButton(
                icon: const Icon(Icons.group),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('群详情页将在下一版本实现')),
                  );
                },
              ),
          ],
        ),
        body: Container(
          color: Colors.white,
          child: Column(
            children: [
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
        final chatState = context.read<ChatCubit>().state;
        final progress = (chatState is ChatLoaded) ? chatState.uploadProgress : null;

        String fullUrl(String url) =>
            (widget.baseUrl != null && url.startsWith('/')) ? '${widget.baseUrl}$url' : url;

        return MessageBubble(
          message: msg,
          isMe: isMe,
          baseUrl: widget.baseUrl,
          uploadProgress: (msg.status == MessageStatus.sending) ? progress : null,
          fileDownloadInfo: (chatState is ChatLoaded) ? chatState.fileDownloads[msg.id] : null,
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
