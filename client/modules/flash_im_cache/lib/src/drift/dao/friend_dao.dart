import 'package:drift/drift.dart';

import '../database/app_database.dart';

class FriendDao {
  final AppDatabase _db;
  FriendDao(this._db);

  /// 批量 upsert
  Future<void> upsertAll(List<CachedFriendsTableCompanion> friends) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.cachedFriendsTable, friends);
    });
  }

  /// 查询全部（按昵称排序）
  Future<List<CachedFriendsTableData>> getAll() async {
    return (_db.select(_db.cachedFriendsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.nickname)]))
        .get();
  }

  /// 全量同步：删除本地多余的 + upsert 远程数据
  Future<void> syncAll(List<CachedFriendsTableCompanion> remote) async {
    final remoteIds = remote.map((c) => c.friendId.value).toSet();
    await (_db.delete(_db.cachedFriendsTable)
          ..where((t) => t.friendId.isNotIn(remoteIds)))
        .go();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.cachedFriendsTable, remote);
    });
  }

  /// 删除单个
  Future<void> deleteById(String friendId) async {
    await (_db.delete(_db.cachedFriendsTable)
          ..where((t) => t.friendId.equals(friendId)))
        .go();
  }
}
