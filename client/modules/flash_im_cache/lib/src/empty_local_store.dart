import 'dart:async';

import 'local_store.dart';
import 'models/cached_message.dart';
import 'models/cached_conversation.dart';
import 'models/cached_friend.dart';

/// LocalStore 空实现
///
/// 所有读操作返回空，写操作 no-op。
/// 用于不需要本地缓存的平台（如鸿蒙初期适配）。
class EmptyLocalStore implements LocalStore {
  final _changeController = StreamController<CacheChangeEvent>.broadcast();

  @override
  Stream<CacheChangeEvent> get changeStream => _changeController.stream;

  // ─── 消息 ───

  @override
  Future<void> cacheMessages(List<CachedMessage> messages, {String? conversationId}) async {}

  @override
  Future<List<CachedMessage>> getMessages(String conversationId, {int? beforeSeq, int limit = 50}) async => [];

  @override
  Future<int> getMaxSeq(String conversationId) async => 0;

  @override
  Future<List<String>> getCachedConversationIds() async => [];

  @override
  Future<void> clearConversationMessages(String conversationId) async {}

  // ─── 会话 ───

  @override
  Future<void> cacheConversations(List<CachedConversation> conversations) async {}

  @override
  Future<List<CachedConversation>> getConversations({int limit = 100, int offset = 0}) async => [];

  @override
  Future<CachedConversation?> getConversation(String id) async => null;

  @override
  Future<void> updateConversation(String id, {int? unreadCount, String? lastMessagePreview, int? lastMessageAt, String? lastMessageExtra}) async {}

  @override
  Future<void> syncConversations(List<CachedConversation> remote) async {}

  @override
  Future<void> deleteConversation(String id) async {}

  // ─── 好友 ───

  @override
  Future<void> cacheFriends(List<CachedFriend> friends) async {}

  @override
  Future<List<CachedFriend>> getFriends() async => [];

  @override
  Future<void> syncFriends(List<CachedFriend> remote) async {}

  @override
  Future<void> deleteFriend(String friendId) async {}

  // ─── 管理 ───

  @override
  Future<bool> isFirstLogin() async => true;

  @override
  Future<void> moveToTrash(String entityId, String entityType) async {}

  @override
  Future<void> restoreFromTrash(String entityId) async {}

  @override
  Future<List<String>> getTrashIds({String? entityType}) async => [];

  @override
  Future<void> clearAll() async {}

  // ─── 文件缓存 ───

  @override
  Future<void> updateLocalData(String messageId, String? localDataJson) async {}

  @override
  Future<String?> getLocalData(String messageId) async => null;

  @override
  Future<Map<String, String?>> batchGetLocalData(List<String> messageIds) async => {};

  @override
  void dispose() {
    _changeController.close();
  }
}
