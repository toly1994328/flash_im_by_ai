import 'package:drift/drift.dart';

import '../database/app_database.dart';

class TrashDao {
  final AppDatabase _db;
  TrashDao(this._db);

  /// 移入回收站
  Future<void> moveToTrash(String entityId, String entityType) async {
    await _db.into(_db.localTrashTable).insertOnConflictUpdate(
      LocalTrashTableCompanion(
        entityId: Value(entityId),
        entityType: Value(entityType),
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// 从回收站恢复
  Future<void> restoreFromTrash(String entityId) async {
    await (_db.delete(_db.localTrashTable)
          ..where((t) => t.entityId.equals(entityId)))
        .go();
  }

  /// 是否在回收站中
  Future<bool> isInTrash(String entityId) async {
    final count = await (_db.selectOnly(_db.localTrashTable)
          ..addColumns([_db.localTrashTable.entityId.count()])
          ..where(_db.localTrashTable.entityId.equals(entityId)))
        .map((row) => row.read(_db.localTrashTable.entityId.count()))
        .getSingle();
    return (count ?? 0) > 0;
  }

  /// 获取回收站中的 ID 列表
  Future<List<String>> getTrashIds({String? entityType}) async {
    final query = _db.select(_db.localTrashTable);
    if (entityType != null) {
      query.where((t) => t.entityType.equals(entityType));
    }
    final rows = await query.get();
    return rows.map((r) => r.entityId).toList();
  }
}
