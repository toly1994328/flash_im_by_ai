import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

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

  /// 按 userId 打开独立数据库（自动适配原生/Web 平台）
  static Future<AppDatabase> open(int userId) async {
    return AppDatabase(
      driftDatabase(
        name: 'im_cache_$userId',
        native: DriftNativeOptions(
          databaseDirectory: getApplicationSupportDirectory,
        ),
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('/im/sqlite3.wasm'),
          driftWorker: Uri.parse('/im/drift_worker.js'),
        ),
      ),
    );
  }
}
