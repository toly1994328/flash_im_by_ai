import 'package:drift/drift.dart';

class LocalTrashTable extends Table {
  TextColumn get entityId => text()();
  TextColumn get entityType => text()(); // message / conversation
  IntColumn get deletedAt => integer()();

  @override
  Set<Column> get primaryKey => {entityId};
}
