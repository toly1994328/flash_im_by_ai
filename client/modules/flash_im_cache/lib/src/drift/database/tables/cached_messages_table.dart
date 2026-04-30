import 'package:drift/drift.dart';

class CachedMessagesTable extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get senderId => text()();
  TextColumn get senderName => text()();
  TextColumn get senderAvatar => text().nullable()();
  IntColumn get seq => integer()();
  IntColumn get msgType => integer()();
  TextColumn get content => text()();
  TextColumn get extra => text().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {conversationId, seq}
      ];
}
