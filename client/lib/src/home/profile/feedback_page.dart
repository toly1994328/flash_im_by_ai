import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_chat/flash_im_chat.dart';
import 'package:flash_im_core/flash_im_core.dart';

/// 意见反馈页面
///
/// 用户输入反馈内容后，以消息形式发送给"闪讯团队"会话。
/// 移动端全屏页面，桌面端通过 adaptivePush 弹窗显示。
class FeedbackPage extends StatefulWidget {
  /// 发送成功后的回调（传回会话 ID，用于激活会话）
  final ValueChanged<String>? onSent;

  const FeedbackPage({super.key, this.onSent});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    try {
      // 获取或创建与闪讯团队（userId=100000000）的私聊会话
      final convRepo = context.read<ConversationRepository>();
      final conv = await convRepo.createPrivate(100000000);
      if (!mounted) return;

      // 用 ChatCubit 发送消息（和输入框一样的流程）
      final wsClient = context.read<WsClient>();
      final msgRepo = context.read<MessageRepository>();
      final session = context.read<SessionCubit>().state;
      final user = session.user;
      if (user == null) return;

      final chatCubit = ChatCubit(
        repository: msgRepo,
        wsClient: wsClient,
        context: ChatContext(
          conversationId: conv.id,
          currentUserId: user.userId.toString(),
          currentUserName: user.nickname,
          currentUserAvatar: user.avatar,
          isGroup: false,
        ),
      )..loadMessages();

      // 等消息加载完再发送
      await Future.delayed(const Duration(milliseconds: 300));
      chatCubit.sendMessage('【意见反馈】\n$content');

      // 等 WS 回执入库
      await Future.delayed(const Duration(milliseconds: 500));
      await chatCubit.close();

      if (!mounted) return;
      widget.onSent?.call(conv.id);
      if (widget.onSent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('反馈已发送，感谢您的建议！')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('意见反馈'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '请描述您遇到的问题或建议：',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: '请输入反馈内容...',
                  hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: _isSending ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  disabledBackgroundColor: const Color(0xFFBBDEFB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('提交反馈', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
