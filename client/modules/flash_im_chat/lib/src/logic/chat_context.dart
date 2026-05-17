/// 聊天会话的上下文信息。
///
/// 封装当前用户在某个会话中的基本元素，
/// 避免 ChatCubit 构造函数参数过多。
class ChatContext {
  final String conversationId;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserAvatar;
  final bool isGroup;

  const ChatContext({
    required this.conversationId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatar,
    this.isGroup = false,
  });
}
