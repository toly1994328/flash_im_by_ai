import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/cached_messages_table.dart';
import 'tables/cached_conversations_table.dart';
import 'tables/cached_friends_table.dart';
import 'tables/local_trash_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
    tables: [CachedMessagesTable, CachedConversationsTable, CachedFriendsTable, LocalTrashTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(localTrashTable);
      }
    },
  );

  /// 按 userId 打开独立数据库文件
  static Future<AppDatabase> open(int userId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'im_cache_$userId.db'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }
}
