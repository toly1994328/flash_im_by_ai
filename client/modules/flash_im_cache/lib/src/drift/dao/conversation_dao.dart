import 'package:drift/drift.dart';

import '../database/app_database.dart';

class ConversationDao {
  final AppDatabase _db;
  ConversationDao(this._db);

  /// 批量 upsert
  Future<void> upsertAll(
      List<CachedConversationsTableCompanion> conversations) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
          _db.cachedConversationsTable, conversations);
    });
  }

  /// 查询全部（按 lastMessageAt 降序）
  Future<List<CachedConversationsTableData>> getAll(
      {int limit = 100, int offset = 0}) async {
    final query = _db.select(_db.cachedConversationsTable)
      ..orderBy([(t) => OrderingTerm.desc(t.lastMessageAt)])
      ..limit(limit, offset: offset);
    return query.get();
  }

  /// 按 ID 查询单个
  Future<CachedConversationsTableData?> getById(String id) async {
    final query = _db.select(_db.cachedConversationsTable)
      ..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  /// 更新部分字段
  Future<void> updateFields(String id,
      {int? unreadCount,
      String? lastMessagePreview,
      int? lastMessageAt}) async {
    await (_db.update(_db.cachedConversationsTable)
          ..where((t) => t.id.equals(id)))
        .write(
      CachedConversationsTableCompanion(
        unreadCount: unreadCount != null
            ? Value(unreadCount)
            : const Value.absent(),
        lastMessagePreview: lastMessagePreview != null
            ? Value(lastMessagePreview)
            : const Value.absent(),
        lastMessageAt:
            lastMessageAt != null ? Value(lastMessageAt) : const Value.absent(),
      ),
    );
  }

  /// 全量同步：删除本地多余的 + upsert 远程数据
  Future<void> syncAll(
      List<CachedConversationsTableCompanion> remote) async {
    final remoteIds = remote.map((c) => c.id.value).toSet();
    await (_db.delete(_db.cachedConversationsTable)
          ..where((t) => t.id.isNotIn(remoteIds)))
        .go();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
          _db.cachedConversationsTable, remote);
    });
  }

  /// 删除单个
  Future<void> deleteById(String id) async {
    await (_db.delete(_db.cachedConversationsTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// 是否为空
  Future<bool> isEmpty() async {
    final count =
        await _db.cachedConversationsTable.count().getSingle();
    return count == 0;
  }
}
