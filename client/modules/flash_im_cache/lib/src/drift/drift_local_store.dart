import 'dart:async';

import '../local_store.dart';
import '../models/cached_message.dart';
import '../models/cached_conversation.dart';
import '../models/cached_friend.dart';
import 'database/app_database.dart';
import 'dao/message_dao.dart';
import 'dao/conversation_dao.dart';
import 'dao/friend_dao.dart';
import 'converters.dart';

/// LocalStore 的 drift 实现
///
/// 内部使用 drift + SQLite，对外只暴露纯 Dart 模型。
/// drift 的类型（Companion、TableData）不会泄漏到接口之外。
class DriftLocalStore implements LocalStore {
  final AppDatabase _db;
  late final MessageDao _messageDao;
  late final ConversationDao _conversationDao;
  late final FriendDao _friendDao;
  final _changeController = StreamController<CacheChangeEvent>.broadcast();

  @override
  Stream<CacheChangeEvent> get changeStream => _changeController.stream;

  DriftLocalStore(this._db) {
    _messageDao = MessageDao(_db);
    _conversationDao = ConversationDao(_db);
    _friendDao = FriendDao(_db);
  }

  /// 按 userId 打开独立数据库
  static Future<DriftLocalStore> open(int userId) async {
    final db = await AppDatabase.open(userId);
    return DriftLocalStore(db);
  }

  // ─── 消息 ───

  @override
  Future<void> cacheMessages(List<CachedMessage> messages,
      {String? conversationId}) async {
    await _messageDao.upsertAll(messages.map(toMessageCompanion).toList());
    _changeController.add(CacheChangeEvent(CacheChangeType.messages,
        conversationId: conversationId));
  }

  @override
  Future<List<CachedMessage>> getMessages(String conversationId,
      {int? beforeSeq, int limit = 50}) async {
    final rows = await _messageDao.getByConversation(conversationId,
        beforeSeq: beforeSeq, limit: limit);
    return rows.map(fromMessageRow).toList();
  }

  @override
  Future<int> getMaxSeq(String conversationId) {
    return _messageDao.getMaxSeq(conversationId);
  }

  @override
  Future<List<String>> getCachedConversationIds() {
    return _messageDao.getCachedConversationIds();
  }

  // ─── 会话 ───

  @override
  Future<void> cacheConversations(List<CachedConversation> conversations) async {
    await _conversationDao
        .upsertAll(conversations.map(toConversationCompanion).toList());
    _changeController
        .add(const CacheChangeEvent(CacheChangeType.conversations));
  }

  @override
  Future<List<CachedConversation>> getConversations(
      {int limit = 100, int offset = 0}) async {
    final rows = await _conversationDao.getAll(limit: limit, offset: offset);
    return rows.map(fromConversationRow).toList();
  }

  @override
  Future<CachedConversation?> getConversation(String id) async {
    final row = await _conversationDao.getById(id);
    return row != null ? fromConversationRow(row) : null;
  }

  @override
  Future<void> updateConversation(String id,
      {int? unreadCount,
      String? lastMessagePreview,
      int? lastMessageAt}) async {
    await _conversationDao.updateFields(id,
        unreadCount: unreadCount,
        lastMessagePreview: lastMessagePreview,
        lastMessageAt: lastMessageAt);
    _changeController
        .add(const CacheChangeEvent(CacheChangeType.conversations));
  }

  @override
  Future<void> syncConversations(List<CachedConversation> remote) async {
    await _conversationDao
        .syncAll(remote.map(toConversationCompanion).toList());
    _changeController
        .add(const CacheChangeEvent(CacheChangeType.conversations));
  }

  @override
  Future<void> deleteConversation(String id) async {
    await _conversationDao.deleteById(id);
    _changeController
        .add(const CacheChangeEvent(CacheChangeType.conversations));
  }

  // ─── 好友 ───

  @override
  Future<void> cacheFriends(List<CachedFriend> friends) async {
    await _friendDao.upsertAll(friends.map(toFriendCompanion).toList());
    _changeController.add(const CacheChangeEvent(CacheChangeType.friends));
  }

  @override
  Future<List<CachedFriend>> getFriends() async {
    final rows = await _friendDao.getAll();
    return rows.map(fromFriendRow).toList();
  }

  @override
  Future<void> syncFriends(List<CachedFriend> remote) async {
    await _friendDao.syncAll(remote.map(toFriendCompanion).toList());
    _changeController.add(const CacheChangeEvent(CacheChangeType.friends));
  }

  @override
  Future<void> deleteFriend(String friendId) async {
    await _friendDao.deleteById(friendId);
    _changeController.add(const CacheChangeEvent(CacheChangeType.friends));
  }

  // ─── 管理 ───

  @override
  Future<bool> isFirstLogin() {
    return _conversationDao.isEmpty();
  }

  @override
  Future<void> clearAll() async {
    await _db.delete(_db.cachedMessagesTable).go();
    await _db.delete(_db.cachedConversationsTable).go();
    await _db.delete(_db.cachedFriendsTable).go();
  }

  @override
  void dispose() {
    _changeController.close();
    _db.close();
  }
}
