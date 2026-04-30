import 'package:drift/drift.dart';

class CachedFriendsTable extends Table {
  TextColumn get friendId => text()();
  TextColumn get nickname => text()();
  TextColumn get avatar => text().nullable()();
  TextColumn get bio => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {friendId};
}
