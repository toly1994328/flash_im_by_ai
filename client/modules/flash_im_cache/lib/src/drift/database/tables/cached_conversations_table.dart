import 'package:drift/drift.dart';

class CachedConversationsTable extends Table {
  TextColumn get id => text()();
  IntColumn get type => integer()();
  TextColumn get name => text().nullable()();
  TextColumn get avatar => text().nullable()();
  TextColumn get peerUserId => text().nullable()();
  TextColumn get peerNickname => text().nullable()();
  TextColumn get peerAvatar => text().nullable()();
  IntColumn get lastMessageAt => integer().nullable()();
  TextColumn get lastMessagePreview => text().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  IntColumn get isPinned => integer().withDefault(const Constant(0))();
  IntColumn get isMuted => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
