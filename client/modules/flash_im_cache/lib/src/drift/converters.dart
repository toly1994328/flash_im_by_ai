import 'package:drift/drift.dart';

import '../../src/models/cached_message.dart';
import '../../src/models/cached_conversation.dart';
import '../../src/models/cached_friend.dart';
import 'database/app_database.dart';

// ─── 消息 ───

CachedMessage fromMessageRow(CachedMessagesTableData row) {
  return CachedMessage(
    id: row.id,
    conversationId: row.conversationId,
    senderId: row.senderId,
    senderName: row.senderName,
    senderAvatar: row.senderAvatar,
    seq: row.seq,
    msgType: row.msgType,
    content: row.content,
    extra: row.extra,
    status: row.status,
    createdAt: row.createdAt,
  );
}

CachedMessagesTableCompanion toMessageCompanion(CachedMessage m) {
  return CachedMessagesTableCompanion(
    id: Value(m.id),
    conversationId: Value(m.conversationId),
    senderId: Value(m.senderId),
    senderName: Value(m.senderName),
    senderAvatar: Value(m.senderAvatar),
    seq: Value(m.seq),
    msgType: Value(m.msgType),
    content: Value(m.content),
    extra: Value(m.extra),
    status: Value(m.status),
    createdAt: Value(m.createdAt),
  );
}

// ─── 会话 ───

CachedConversation fromConversationRow(CachedConversationsTableData row) {
  return CachedConversation(
    id: row.id,
    type: row.type,
    name: row.name,
    avatar: row.avatar,
    peerUserId: row.peerUserId,
    peerNickname: row.peerNickname,
    peerAvatar: row.peerAvatar,
    lastMessageAt: row.lastMessageAt,
    lastMessagePreview: row.lastMessagePreview,
    unreadCount: row.unreadCount,
    isPinned: row.isPinned == 1,
    isMuted: row.isMuted == 1,
    createdAt: row.createdAt,
  );
}

CachedConversationsTableCompanion toConversationCompanion(CachedConversation c) {
  return CachedConversationsTableCompanion(
    id: Value(c.id),
    type: Value(c.type),
    name: Value(c.name),
    avatar: Value(c.avatar),
    peerUserId: Value(c.peerUserId),
    peerNickname: Value(c.peerNickname),
    peerAvatar: Value(c.peerAvatar),
    lastMessageAt: Value(c.lastMessageAt),
    lastMessagePreview: Value(c.lastMessagePreview),
    unreadCount: Value(c.unreadCount),
    isPinned: Value(c.isPinned ? 1 : 0),
    isMuted: Value(c.isMuted ? 1 : 0),
    createdAt: Value(c.createdAt),
  );
}

// ─── 好友 ───

CachedFriend fromFriendRow(CachedFriendsTableData row) {
  return CachedFriend(
    friendId: row.friendId,
    nickname: row.nickname,
    avatar: row.avatar,
    bio: row.bio,
    createdAt: row.createdAt,
  );
}

CachedFriendsTableCompanion toFriendCompanion(CachedFriend f) {
  return CachedFriendsTableCompanion(
    friendId: Value(f.friendId),
    nickname: Value(f.nickname),
    avatar: Value(f.avatar),
    bio: Value(f.bio),
    createdAt: Value(f.createdAt),
  );
}
