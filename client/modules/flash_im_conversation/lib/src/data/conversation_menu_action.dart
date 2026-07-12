import 'package:flutter/material.dart';
import '../data/conversation.dart';

/// 会话菜单操作枚举（统一移动端滑动/长按/桌面端右键）
enum ConversationMenuAction {
  pin,        // 置顶/取消置顶
  mute,       // 免打扰/取消免打扰
  markRead,   // 标为已读
  markUnread, // 标为未读
  delete,     // 删除会话
  clearAll,   // 清空当前会话聊天记录
}

/// 根据上下文返回可用操作列表
List<ConversationMenuAction> getConversationActions({
  required Conversation conv,
  required bool isSlidableView,
}) {
  if (isSlidableView) {
    // 滑动菜单：4 个固定按钮
    return [
      ConversationMenuAction.pin,
      ConversationMenuAction.mute,
      if (conv.unreadCount > 0) ConversationMenuAction.markRead,
      ConversationMenuAction.delete,
    ];
  }
  // 全量菜单（长按/右键）
  return [
    ConversationMenuAction.pin,
    ConversationMenuAction.mute,
    if (conv.unreadCount > 0) ConversationMenuAction.markRead,
    ConversationMenuAction.markUnread,
    ConversationMenuAction.delete,
    ConversationMenuAction.clearAll,
  ];
}

/// 菜单动作的显示信息
(IconData, String) actionInfo(ConversationMenuAction action, Conversation conv) {
  return switch (action) {
    ConversationMenuAction.pin => conv.isPinned
        ? (Icons.push_pin, '取消置顶')
        : (Icons.push_pin_outlined, '置顶'),
    ConversationMenuAction.mute => conv.isMuted
        ? (Icons.volume_up, '取消免打扰')
        : (Icons.volume_off, '免打扰'),
    ConversationMenuAction.markRead => (Icons.done_all, '标为已读'),
    ConversationMenuAction.markUnread => (Icons.mark_chat_unread_outlined, '标为未读'),
    ConversationMenuAction.delete => (Icons.delete_outline, '删除'),
    ConversationMenuAction.clearAll => (Icons.clear_all, '清空聊天记录'),
  };
}

/// 滑动按钮的颜色
Color slideActionColor(ConversationMenuAction action) {
  return switch (action) {
    ConversationMenuAction.pin => const Color(0xFF3B82F6),
    ConversationMenuAction.mute => const Color(0xFFF59E0B),
    ConversationMenuAction.markRead => const Color(0xFF10B981),
    ConversationMenuAction.delete => const Color(0xFFFF4D4F),
    _ => Colors.grey,
  };
}
