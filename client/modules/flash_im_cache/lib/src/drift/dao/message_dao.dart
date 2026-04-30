import 'package:drift/drift.dart';

import '../database/app_database.dart';

class MessageDao {
  final AppDatabase _db;
  MessageDao(this._db);

  /// 批量 upsert
  Future<void> upsertAll(List<CachedMessagesTableCompanion> messages) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.cachedMessagesTable, messages);
    });
  }

  /// 按会话查询（before_seq 向上翻页，按 seq DESC）
  Future<List<CachedMessagesTableData>> getByConversation(
    String conversationId, {
    int? beforeSeq,
    int limit = 50,
  }) async {
    final query = _db.select(_db.cachedMessagesTable)
      ..where((t) => t.conversationId.equals(conversationId));
    if (beforeSeq != null) {
      query.where((t) => t.seq.isSmallerThanValue(beforeSeq));
    }
    query
      ..orderBy([(t) => OrderingTerm.desc(t.seq)])
      ..limit(limit);
    return query.get();
  }

  /// 查询会话的本地最大 seq
  Future<int> getMaxSeq(String conversationId) async {
    final expr = _db.cachedMessagesTable.seq.max();
    final query = _db.selectOnly(_db.cachedMessagesTable)
      ..addColumns([expr])
      ..where(_db.cachedMessagesTable.conversationId.equals(conversationId));
    final result = await query.getSingleOrNull();
    return result?.read(expr) ?? 0;
  }

  /// 查询所有有缓存消息的会话 ID
  Future<List<String>> getCachedConversationIds() async {
    final col = _db.cachedMessagesTable.conversationId;
    final query = _db.selectOnly(_db.cachedMessagesTable, distinct: true)
      ..addColumns([col]);
    final rows = await query.get();
    return rows.map((r) => r.read(col)!).toList();
  }
}
