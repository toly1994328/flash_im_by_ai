import 'dart:async';

import 'package:flash_im_cache/flash_im_cache.dart';
import 'database/app_database.dart';
import 'dao/message_dao.dart';
import 'dao/conversation_dao.dart';
import 'dao/friend_dao.dart';
import 'dao/trash_dao.dart';
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
  late final TrashDao _trashDao;
  final _changeController = StreamController<CacheChangeEvent>.broadcast();
  bool _isClosed = false;

  @override
  Stream<CacheChangeEvent> get changeStream => _changeController.stream;

  void _emitChange(CacheChangeEvent event) {
    if (!_isClosed) _changeController.add(event);
  }

  DriftLocalStore(this._db) {
    _messageDao = MessageDao(_db);
    _conversationDao = ConversationDao(_db);
    _friendDao = FriendDao(_db);
    _trashDao = TrashDao(_db);
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
    _emitChange(CacheChangeEvent(CacheChangeType.messages,
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
    _emitChange(const CacheChangeEvent(CacheChangeType.conversations));
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
      int? lastMessageAt,
      String? lastMessageExtra}) async {
    await _conversationDao.updateFields(id,
        unreadCount: unreadCount,
        lastMessagePreview: lastMessagePreview,
        lastMessageAt: lastMessageAt,
        lastMessageExtra: lastMessageExtra);
    _emitChange(const CacheChangeEvent(CacheChangeType.conversations));
  }

  @override
  Future<void> syncConversations(List<CachedConversation> remote) async {
    await _conversationDao
        .syncAll(remote.map(toConversationCompanion).toList());
    _emitChange(const CacheChangeEvent(CacheChangeType.conversations));
  }

  @override
  Future<void> deleteConversation(String id) async {
    await _conversationDao.deleteById(id);
    _emitChange(const CacheChangeEvent(CacheChangeType.conversations));
  }

  // ─── 好友 ───

  @override
  Future<void> cacheFriends(List<CachedFriend> friends) async {
    await _friendDao.upsertAll(friends.map(toFriendCompanion).toList());
    _emitChange(const CacheChangeEvent(CacheChangeType.friends));
  }

  @override
  Future<List<CachedFriend>> getFriends() async {
    final rows = await _friendDao.getAll();
    return rows.map(fromFriendRow).toList();
  }

  @override
  Future<void> syncFriends(List<CachedFriend> remote) async {
    await _friendDao.syncAll(remote.map(toFriendCompanion).toList());
    _emitChange(const CacheChangeEvent(CacheChangeType.friends));
  }

  @override
  Future<void> deleteFriend(String friendId) async {
    await _friendDao.deleteById(friendId);
    _emitChange(const CacheChangeEvent(CacheChangeType.friends));
  }

  // ─── 管理 ───

  @override
  Future<bool> isFirstLogin() {
    return _conversationDao.isEmpty();
  }

  @override
  Future<void> moveToTrash(String entityId, String entityType) {
    return _trashDao.moveToTrash(entityId, entityType);
  }

  @override
  Future<void> restoreFromTrash(String entityId) {
    return _trashDao.restoreFromTrash(entityId);
  }

  @override
  Future<List<String>> getTrashIds({String? entityType}) {
    return _trashDao.getTrashIds(entityType: entityType);
  }

  @override
  Future<void> clearAll() async {
    await _db.delete(_db.cachedMessagesTable).go();
    await _db.delete(_db.cachedConversationsTable).go();
    await _db.delete(_db.cachedFriendsTable).go();
  }

  // ─── 文件缓存 ───

  @override
  Future<void> updateLocalData(String messageId, String? localDataJson) async {
    await _messageDao.updateLocalData(messageId, localDataJson);
  }

  @override
  Future<String?> getLocalData(String messageId) {
    return _messageDao.getLocalData(messageId);
  }

  @override
  Future<Map<String, String?>> batchGetLocalData(List<String> messageIds) {
    return _messageDao.batchGetLocalData(messageIds);
  }

  @override
  void dispose() {
    _isClosed = true;
    _changeController.close();
    _db.close();
  }
}
