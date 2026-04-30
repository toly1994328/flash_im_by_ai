import 'dart:async';

import 'models/cached_message.dart';
import 'models/cached_conversation.dart';
import 'models/cached_friend.dart';

/// 缓存变更类型
enum CacheChangeType { messages, conversations, friends }

/// 缓存变更事件
class CacheChangeEvent {
  final CacheChangeType type;
  final String? conversationId;
  const CacheChangeEvent(this.type, {this.conversationId});
}

/// 本地存储抽象接口
///
/// 定义读写契约，不绑定任何 ORM。
/// 当前实现：DriftLocalStore（drift + SQLite）。
/// 未来可替换为 Hive / Isar / 其他实现。
abstract class LocalStore {
  /// 数据变更通知流
  Stream<CacheChangeEvent> get changeStream;

  // ─── 消息 ───

  /// 批量写入消息（upsert 语义，幂等）
  Future<void> cacheMessages(List<CachedMessage> messages,
      {String? conversationId});

  /// 按会话查询消息（before_seq 向上翻页，按 seq DESC）
  Future<List<CachedMessage>> getMessages(String conversationId,
      {int? beforeSeq, int limit = 50});

  /// 查询会话的本地最大 seq（增量同步用）
  Future<int> getMaxSeq(String conversationId);

  /// 查询所有有缓存消息的会话 ID（重连同步用）
  Future<List<String>> getCachedConversationIds();

  // ─── 会话 ───

  /// 批量写入会话（upsert）
  Future<void> cacheConversations(List<CachedConversation> conversations);

  /// 查询会话列表（按 lastMessageAt 降序）
  Future<List<CachedConversation>> getConversations(
      {int limit = 100, int offset = 0});

  /// 按 ID 查询单个会话
  Future<CachedConversation?> getConversation(String id);

  /// 更新会话部分字段
  Future<void> updateConversation(String id,
      {int? unreadCount, String? lastMessagePreview, int? lastMessageAt});

  /// 全量同步会话：删除本地多余的 + upsert 远程数据
  Future<void> syncConversations(List<CachedConversation> remote);

  /// 删除单个会话
  Future<void> deleteConversation(String id);

  // ─── 好友 ───

  /// 批量写入好友（upsert）
  Future<void> cacheFriends(List<CachedFriend> friends);

  /// 查询全部好友
  Future<List<CachedFriend>> getFriends();

  /// 全量同步好友：删除本地多余的 + upsert 远程数据
  Future<void> syncFriends(List<CachedFriend> remote);

  /// 删除单个好友
  Future<void> deleteFriend(String friendId);

  // ─── 管理 ───

  /// 是否首次登录（本地无会话数据）
  Future<bool> isFirstLogin();

  /// 清空所有缓存
  Future<void> clearAll();

  /// 释放资源
  void dispose();
}
