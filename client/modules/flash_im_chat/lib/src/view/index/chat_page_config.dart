/// 聊天目标（会话身份 + 对端描述）
class ChatTarget {
  final String conversationId;
  final bool isGroup;
  final String peerName;
  final String? peerAvatar;
  final String? peerUserId;

  const ChatTarget({
    required this.conversationId,
    required this.peerName,
    this.isGroup = false,
    this.peerAvatar,
    this.peerUserId,
  });
}

/// View 层显示选项
class ChatViewOptions {
  /// 嵌入模式（桌面端面板内使用）：紧凑标题、无返回按钮、支持拖拽
  final bool embedded;

  /// 文件/图片等资源的 baseUrl 前缀
  final String? baseUrl;

  const ChatViewOptions({
    this.embedded = false,
    this.baseUrl,
  });
}
