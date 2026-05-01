// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedMessagesTableTable extends CachedMessagesTable
    with TableInfo<$CachedMessagesTableTable, CachedMessagesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMessagesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderNameMeta = const VerificationMeta(
    'senderName',
  );
  @override
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
    'sender_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderAvatarMeta = const VerificationMeta(
    'senderAvatar',
  );
  @override
  late final GeneratedColumn<String> senderAvatar = GeneratedColumn<String>(
    'sender_avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _msgTypeMeta = const VerificationMeta(
    'msgType',
  );
  @override
  late final GeneratedColumn<int> msgType = GeneratedColumn<int>(
    'msg_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extraMeta = const VerificationMeta('extra');
  @override
  late final GeneratedColumn<String> extra = GeneratedColumn<String>(
    'extra',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    senderId,
    senderName,
    senderAvatar,
    seq,
    msgType,
    content,
    extra,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_messages_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMessagesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('sender_name')) {
      context.handle(
        _senderNameMeta,
        senderName.isAcceptableOrUnknown(data['sender_name']!, _senderNameMeta),
      );
    } else if (isInserting) {
      context.missing(_senderNameMeta);
    }
    if (data.containsKey('sender_avatar')) {
      context.handle(
        _senderAvatarMeta,
        senderAvatar.isAcceptableOrUnknown(
          data['sender_avatar']!,
          _senderAvatarMeta,
        ),
      );
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('msg_type')) {
      context.handle(
        _msgTypeMeta,
        msgType.isAcceptableOrUnknown(data['msg_type']!, _msgTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_msgTypeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('extra')) {
      context.handle(
        _extraMeta,
        extra.isAcceptableOrUnknown(data['extra']!, _extraMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {conversationId, seq},
  ];
  @override
  CachedMessagesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMessagesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      senderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_name'],
      )!,
      senderAvatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_avatar'],
      ),
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      msgType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}msg_type'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      extra: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CachedMessagesTableTable createAlias(String alias) {
    return $CachedMessagesTableTable(attachedDatabase, alias);
  }
}

class CachedMessagesTableData extends DataClass
    implements Insertable<CachedMessagesTableData> {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final int seq;
  final int msgType;
  final String content;
  final String? extra;
  final int status;
  final int createdAt;
  const CachedMessagesTableData({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.seq,
    required this.msgType,
    required this.content,
    this.extra,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['sender_id'] = Variable<String>(senderId);
    map['sender_name'] = Variable<String>(senderName);
    if (!nullToAbsent || senderAvatar != null) {
      map['sender_avatar'] = Variable<String>(senderAvatar);
    }
    map['seq'] = Variable<int>(seq);
    map['msg_type'] = Variable<int>(msgType);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || extra != null) {
      map['extra'] = Variable<String>(extra);
    }
    map['status'] = Variable<int>(status);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CachedMessagesTableCompanion toCompanion(bool nullToAbsent) {
    return CachedMessagesTableCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      senderId: Value(senderId),
      senderName: Value(senderName),
      senderAvatar: senderAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(senderAvatar),
      seq: Value(seq),
      msgType: Value(msgType),
      content: Value(content),
      extra: extra == null && nullToAbsent
          ? const Value.absent()
          : Value(extra),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory CachedMessagesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMessagesTableData(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      senderName: serializer.fromJson<String>(json['senderName']),
      senderAvatar: serializer.fromJson<String?>(json['senderAvatar']),
      seq: serializer.fromJson<int>(json['seq']),
      msgType: serializer.fromJson<int>(json['msgType']),
      content: serializer.fromJson<String>(json['content']),
      extra: serializer.fromJson<String?>(json['extra']),
      status: serializer.fromJson<int>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'senderId': serializer.toJson<String>(senderId),
      'senderName': serializer.toJson<String>(senderName),
      'senderAvatar': serializer.toJson<String?>(senderAvatar),
      'seq': serializer.toJson<int>(seq),
      'msgType': serializer.toJson<int>(msgType),
      'content': serializer.toJson<String>(content),
      'extra': serializer.toJson<String?>(extra),
      'status': serializer.toJson<int>(status),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CachedMessagesTableData copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    Value<String?> senderAvatar = const Value.absent(),
    int? seq,
    int? msgType,
    String? content,
    Value<String?> extra = const Value.absent(),
    int? status,
    int? createdAt,
  }) => CachedMessagesTableData(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    senderId: senderId ?? this.senderId,
    senderName: senderName ?? this.senderName,
    senderAvatar: senderAvatar.present ? senderAvatar.value : this.senderAvatar,
    seq: seq ?? this.seq,
    msgType: msgType ?? this.msgType,
    content: content ?? this.content,
    extra: extra.present ? extra.value : this.extra,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  CachedMessagesTableData copyWithCompanion(CachedMessagesTableCompanion data) {
    return CachedMessagesTableData(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      senderName: data.senderName.present
          ? data.senderName.value
          : this.senderName,
      senderAvatar: data.senderAvatar.present
          ? data.senderAvatar.value
          : this.senderAvatar,
      seq: data.seq.present ? data.seq.value : this.seq,
      msgType: data.msgType.present ? data.msgType.value : this.msgType,
      content: data.content.present ? data.content.value : this.content,
      extra: data.extra.present ? data.extra.value : this.extra,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessagesTableData(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('senderName: $senderName, ')
          ..write('senderAvatar: $senderAvatar, ')
          ..write('seq: $seq, ')
          ..write('msgType: $msgType, ')
          ..write('content: $content, ')
          ..write('extra: $extra, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    senderId,
    senderName,
    senderAvatar,
    seq,
    msgType,
    content,
    extra,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMessagesTableData &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.senderId == this.senderId &&
          other.senderName == this.senderName &&
          other.senderAvatar == this.senderAvatar &&
          other.seq == this.seq &&
          other.msgType == this.msgType &&
          other.content == this.content &&
          other.extra == this.extra &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class CachedMessagesTableCompanion
    extends UpdateCompanion<CachedMessagesTableData> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> senderId;
  final Value<String> senderName;
  final Value<String?> senderAvatar;
  final Value<int> seq;
  final Value<int> msgType;
  final Value<String> content;
  final Value<String?> extra;
  final Value<int> status;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CachedMessagesTableCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.senderName = const Value.absent(),
    this.senderAvatar = const Value.absent(),
    this.seq = const Value.absent(),
    this.msgType = const Value.absent(),
    this.content = const Value.absent(),
    this.extra = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMessagesTableCompanion.insert({
    required String id,
    required String conversationId,
    required String senderId,
    required String senderName,
    this.senderAvatar = const Value.absent(),
    required int seq,
    required int msgType,
    required String content,
    this.extra = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       senderId = Value(senderId),
       senderName = Value(senderName),
       seq = Value(seq),
       msgType = Value(msgType),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<CachedMessagesTableData> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? senderId,
    Expression<String>? senderName,
    Expression<String>? senderAvatar,
    Expression<int>? seq,
    Expression<int>? msgType,
    Expression<String>? content,
    Expression<String>? extra,
    Expression<int>? status,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (senderId != null) 'sender_id': senderId,
      if (senderName != null) 'sender_name': senderName,
      if (senderAvatar != null) 'sender_avatar': senderAvatar,
      if (seq != null) 'seq': seq,
      if (msgType != null) 'msg_type': msgType,
      if (content != null) 'content': content,
      if (extra != null) 'extra': extra,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMessagesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? senderId,
    Value<String>? senderName,
    Value<String?>? senderAvatar,
    Value<int>? seq,
    Value<int>? msgType,
    Value<String>? content,
    Value<String?>? extra,
    Value<int>? status,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return CachedMessagesTableCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      seq: seq ?? this.seq,
      msgType: msgType ?? this.msgType,
      content: content ?? this.content,
      extra: extra ?? this.extra,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (senderName.present) {
      map['sender_name'] = Variable<String>(senderName.value);
    }
    if (senderAvatar.present) {
      map['sender_avatar'] = Variable<String>(senderAvatar.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (msgType.present) {
      map['msg_type'] = Variable<int>(msgType.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (extra.present) {
      map['extra'] = Variable<String>(extra.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMessagesTableCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('senderName: $senderName, ')
          ..write('senderAvatar: $senderAvatar, ')
          ..write('seq: $seq, ')
          ..write('msgType: $msgType, ')
          ..write('content: $content, ')
          ..write('extra: $extra, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedConversationsTableTable extends CachedConversationsTable
    with
        TableInfo<
          $CachedConversationsTableTable,
          CachedConversationsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedConversationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peerUserIdMeta = const VerificationMeta(
    'peerUserId',
  );
  @override
  late final GeneratedColumn<String> peerUserId = GeneratedColumn<String>(
    'peer_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peerNicknameMeta = const VerificationMeta(
    'peerNickname',
  );
  @override
  late final GeneratedColumn<String> peerNickname = GeneratedColumn<String>(
    'peer_nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peerAvatarMeta = const VerificationMeta(
    'peerAvatar',
  );
  @override
  late final GeneratedColumn<String> peerAvatar = GeneratedColumn<String>(
    'peer_avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageAtMeta = const VerificationMeta(
    'lastMessageAt',
  );
  @override
  late final GeneratedColumn<int> lastMessageAt = GeneratedColumn<int>(
    'last_message_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessagePreviewMeta =
      const VerificationMeta('lastMessagePreview');
  @override
  late final GeneratedColumn<String> lastMessagePreview =
      GeneratedColumn<String>(
        'last_message_preview',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<int> isPinned = GeneratedColumn<int>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isMutedMeta = const VerificationMeta(
    'isMuted',
  );
  @override
  late final GeneratedColumn<int> isMuted = GeneratedColumn<int>(
    'is_muted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    name,
    avatar,
    peerUserId,
    peerNickname,
    peerAvatar,
    lastMessageAt,
    lastMessagePreview,
    unreadCount,
    isPinned,
    isMuted,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_conversations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedConversationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('peer_user_id')) {
      context.handle(
        _peerUserIdMeta,
        peerUserId.isAcceptableOrUnknown(
          data['peer_user_id']!,
          _peerUserIdMeta,
        ),
      );
    }
    if (data.containsKey('peer_nickname')) {
      context.handle(
        _peerNicknameMeta,
        peerNickname.isAcceptableOrUnknown(
          data['peer_nickname']!,
          _peerNicknameMeta,
        ),
      );
    }
    if (data.containsKey('peer_avatar')) {
      context.handle(
        _peerAvatarMeta,
        peerAvatar.isAcceptableOrUnknown(data['peer_avatar']!, _peerAvatarMeta),
      );
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
      );
    }
    if (data.containsKey('last_message_preview')) {
      context.handle(
        _lastMessagePreviewMeta,
        lastMessagePreview.isAcceptableOrUnknown(
          data['last_message_preview']!,
          _lastMessagePreviewMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('is_muted')) {
      context.handle(
        _isMutedMeta,
        isMuted.isAcceptableOrUnknown(data['is_muted']!, _isMutedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedConversationsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedConversationsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      ),
      peerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_user_id'],
      ),
      peerNickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_nickname'],
      ),
      peerAvatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}peer_avatar'],
      ),
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_at'],
      ),
      lastMessagePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_preview'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_pinned'],
      )!,
      isMuted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_muted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CachedConversationsTableTable createAlias(String alias) {
    return $CachedConversationsTableTable(attachedDatabase, alias);
  }
}

class CachedConversationsTableData extends DataClass
    implements Insertable<CachedConversationsTableData> {
  final String id;
  final int type;
  final String? name;
  final String? avatar;
  final String? peerUserId;
  final String? peerNickname;
  final String? peerAvatar;
  final int? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final int isPinned;
  final int isMuted;
  final int createdAt;
  const CachedConversationsTableData({
    required this.id,
    required this.type,
    this.name,
    this.avatar,
    this.peerUserId,
    this.peerNickname,
    this.peerAvatar,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.unreadCount,
    required this.isPinned,
    required this.isMuted,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<int>(type);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    if (!nullToAbsent || peerUserId != null) {
      map['peer_user_id'] = Variable<String>(peerUserId);
    }
    if (!nullToAbsent || peerNickname != null) {
      map['peer_nickname'] = Variable<String>(peerNickname);
    }
    if (!nullToAbsent || peerAvatar != null) {
      map['peer_avatar'] = Variable<String>(peerAvatar);
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<int>(lastMessageAt);
    }
    if (!nullToAbsent || lastMessagePreview != null) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    map['is_pinned'] = Variable<int>(isPinned);
    map['is_muted'] = Variable<int>(isMuted);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CachedConversationsTableCompanion toCompanion(bool nullToAbsent) {
    return CachedConversationsTableCompanion(
      id: Value(id),
      type: Value(type),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      avatar: avatar == null && nullToAbsent
          ? const Value.absent()
          : Value(avatar),
      peerUserId: peerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(peerUserId),
      peerNickname: peerNickname == null && nullToAbsent
          ? const Value.absent()
          : Value(peerNickname),
      peerAvatar: peerAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(peerAvatar),
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      lastMessagePreview: lastMessagePreview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessagePreview),
      unreadCount: Value(unreadCount),
      isPinned: Value(isPinned),
      isMuted: Value(isMuted),
      createdAt: Value(createdAt),
    );
  }

  factory CachedConversationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedConversationsTableData(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<int>(json['type']),
      name: serializer.fromJson<String?>(json['name']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      peerUserId: serializer.fromJson<String?>(json['peerUserId']),
      peerNickname: serializer.fromJson<String?>(json['peerNickname']),
      peerAvatar: serializer.fromJson<String?>(json['peerAvatar']),
      lastMessageAt: serializer.fromJson<int?>(json['lastMessageAt']),
      lastMessagePreview: serializer.fromJson<String?>(
        json['lastMessagePreview'],
      ),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      isPinned: serializer.fromJson<int>(json['isPinned']),
      isMuted: serializer.fromJson<int>(json['isMuted']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<int>(type),
      'name': serializer.toJson<String?>(name),
      'avatar': serializer.toJson<String?>(avatar),
      'peerUserId': serializer.toJson<String?>(peerUserId),
      'peerNickname': serializer.toJson<String?>(peerNickname),
      'peerAvatar': serializer.toJson<String?>(peerAvatar),
      'lastMessageAt': serializer.toJson<int?>(lastMessageAt),
      'lastMessagePreview': serializer.toJson<String?>(lastMessagePreview),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'isPinned': serializer.toJson<int>(isPinned),
      'isMuted': serializer.toJson<int>(isMuted),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CachedConversationsTableData copyWith({
    String? id,
    int? type,
    Value<String?> name = const Value.absent(),
    Value<String?> avatar = const Value.absent(),
    Value<String?> peerUserId = const Value.absent(),
    Value<String?> peerNickname = const Value.absent(),
    Value<String?> peerAvatar = const Value.absent(),
    Value<int?> lastMessageAt = const Value.absent(),
    Value<String?> lastMessagePreview = const Value.absent(),
    int? unreadCount,
    int? isPinned,
    int? isMuted,
    int? createdAt,
  }) => CachedConversationsTableData(
    id: id ?? this.id,
    type: type ?? this.type,
    name: name.present ? name.value : this.name,
    avatar: avatar.present ? avatar.value : this.avatar,
    peerUserId: peerUserId.present ? peerUserId.value : this.peerUserId,
    peerNickname: peerNickname.present ? peerNickname.value : this.peerNickname,
    peerAvatar: peerAvatar.present ? peerAvatar.value : this.peerAvatar,
    lastMessageAt: lastMessageAt.present
        ? lastMessageAt.value
        : this.lastMessageAt,
    lastMessagePreview: lastMessagePreview.present
        ? lastMessagePreview.value
        : this.lastMessagePreview,
    unreadCount: unreadCount ?? this.unreadCount,
    isPinned: isPinned ?? this.isPinned,
    isMuted: isMuted ?? this.isMuted,
    createdAt: createdAt ?? this.createdAt,
  );
  CachedConversationsTableData copyWithCompanion(
    CachedConversationsTableCompanion data,
  ) {
    return CachedConversationsTableData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      peerUserId: data.peerUserId.present
          ? data.peerUserId.value
          : this.peerUserId,
      peerNickname: data.peerNickname.present
          ? data.peerNickname.value
          : this.peerNickname,
      peerAvatar: data.peerAvatar.present
          ? data.peerAvatar.value
          : this.peerAvatar,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
      lastMessagePreview: data.lastMessagePreview.present
          ? data.lastMessagePreview.value
          : this.lastMessagePreview,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isMuted: data.isMuted.present ? data.isMuted.value : this.isMuted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedConversationsTableData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('avatar: $avatar, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerNickname: $peerNickname, ')
          ..write('peerAvatar: $peerAvatar, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('isPinned: $isPinned, ')
          ..write('isMuted: $isMuted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    name,
    avatar,
    peerUserId,
    peerNickname,
    peerAvatar,
    lastMessageAt,
    lastMessagePreview,
    unreadCount,
    isPinned,
    isMuted,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedConversationsTableData &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.avatar == this.avatar &&
          other.peerUserId == this.peerUserId &&
          other.peerNickname == this.peerNickname &&
          other.peerAvatar == this.peerAvatar &&
          other.lastMessageAt == this.lastMessageAt &&
          other.lastMessagePreview == this.lastMessagePreview &&
          other.unreadCount == this.unreadCount &&
          other.isPinned == this.isPinned &&
          other.isMuted == this.isMuted &&
          other.createdAt == this.createdAt);
}

class CachedConversationsTableCompanion
    extends UpdateCompanion<CachedConversationsTableData> {
  final Value<String> id;
  final Value<int> type;
  final Value<String?> name;
  final Value<String?> avatar;
  final Value<String?> peerUserId;
  final Value<String?> peerNickname;
  final Value<String?> peerAvatar;
  final Value<int?> lastMessageAt;
  final Value<String?> lastMessagePreview;
  final Value<int> unreadCount;
  final Value<int> isPinned;
  final Value<int> isMuted;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CachedConversationsTableCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.avatar = const Value.absent(),
    this.peerUserId = const Value.absent(),
    this.peerNickname = const Value.absent(),
    this.peerAvatar = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedConversationsTableCompanion.insert({
    required String id,
    required int type,
    this.name = const Value.absent(),
    this.avatar = const Value.absent(),
    this.peerUserId = const Value.absent(),
    this.peerNickname = const Value.absent(),
    this.peerAvatar = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isMuted = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<CachedConversationsTableData> custom({
    Expression<String>? id,
    Expression<int>? type,
    Expression<String>? name,
    Expression<String>? avatar,
    Expression<String>? peerUserId,
    Expression<String>? peerNickname,
    Expression<String>? peerAvatar,
    Expression<int>? lastMessageAt,
    Expression<String>? lastMessagePreview,
    Expression<int>? unreadCount,
    Expression<int>? isPinned,
    Expression<int>? isMuted,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
      if (peerUserId != null) 'peer_user_id': peerUserId,
      if (peerNickname != null) 'peer_nickname': peerNickname,
      if (peerAvatar != null) 'peer_avatar': peerAvatar,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (lastMessagePreview != null)
        'last_message_preview': lastMessagePreview,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isMuted != null) 'is_muted': isMuted,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedConversationsTableCompanion copyWith({
    Value<String>? id,
    Value<int>? type,
    Value<String?>? name,
    Value<String?>? avatar,
    Value<String?>? peerUserId,
    Value<String?>? peerNickname,
    Value<String?>? peerAvatar,
    Value<int?>? lastMessageAt,
    Value<String?>? lastMessagePreview,
    Value<int>? unreadCount,
    Value<int>? isPinned,
    Value<int>? isMuted,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return CachedConversationsTableCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      peerUserId: peerUserId ?? this.peerUserId,
      peerNickname: peerNickname ?? this.peerNickname,
      peerAvatar: peerAvatar ?? this.peerAvatar,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (peerUserId.present) {
      map['peer_user_id'] = Variable<String>(peerUserId.value);
    }
    if (peerNickname.present) {
      map['peer_nickname'] = Variable<String>(peerNickname.value);
    }
    if (peerAvatar.present) {
      map['peer_avatar'] = Variable<String>(peerAvatar.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<int>(lastMessageAt.value);
    }
    if (lastMessagePreview.present) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<int>(isPinned.value);
    }
    if (isMuted.present) {
      map['is_muted'] = Variable<int>(isMuted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedConversationsTableCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('avatar: $avatar, ')
          ..write('peerUserId: $peerUserId, ')
          ..write('peerNickname: $peerNickname, ')
          ..write('peerAvatar: $peerAvatar, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('isPinned: $isPinned, ')
          ..write('isMuted: $isMuted, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedFriendsTableTable extends CachedFriendsTable
    with TableInfo<$CachedFriendsTableTable, CachedFriendsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFriendsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _friendIdMeta = const VerificationMeta(
    'friendId',
  );
  @override
  late final GeneratedColumn<String> friendId = GeneratedColumn<String>(
    'friend_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    friendId,
    nickname,
    avatar,
    bio,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_friends_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFriendsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('friend_id')) {
      context.handle(
        _friendIdMeta,
        friendId.isAcceptableOrUnknown(data['friend_id']!, _friendIdMeta),
      );
    } else if (isInserting) {
      context.missing(_friendIdMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {friendId};
  @override
  CachedFriendsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFriendsTableData(
      friendId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}friend_id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      ),
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CachedFriendsTableTable createAlias(String alias) {
    return $CachedFriendsTableTable(attachedDatabase, alias);
  }
}

class CachedFriendsTableData extends DataClass
    implements Insertable<CachedFriendsTableData> {
  final String friendId;
  final String nickname;
  final String? avatar;
  final String? bio;
  final int createdAt;
  const CachedFriendsTableData({
    required this.friendId,
    required this.nickname,
    this.avatar,
    this.bio,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['friend_id'] = Variable<String>(friendId);
    map['nickname'] = Variable<String>(nickname);
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CachedFriendsTableCompanion toCompanion(bool nullToAbsent) {
    return CachedFriendsTableCompanion(
      friendId: Value(friendId),
      nickname: Value(nickname),
      avatar: avatar == null && nullToAbsent
          ? const Value.absent()
          : Value(avatar),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      createdAt: Value(createdAt),
    );
  }

  factory CachedFriendsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFriendsTableData(
      friendId: serializer.fromJson<String>(json['friendId']),
      nickname: serializer.fromJson<String>(json['nickname']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      bio: serializer.fromJson<String?>(json['bio']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'friendId': serializer.toJson<String>(friendId),
      'nickname': serializer.toJson<String>(nickname),
      'avatar': serializer.toJson<String?>(avatar),
      'bio': serializer.toJson<String?>(bio),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CachedFriendsTableData copyWith({
    String? friendId,
    String? nickname,
    Value<String?> avatar = const Value.absent(),
    Value<String?> bio = const Value.absent(),
    int? createdAt,
  }) => CachedFriendsTableData(
    friendId: friendId ?? this.friendId,
    nickname: nickname ?? this.nickname,
    avatar: avatar.present ? avatar.value : this.avatar,
    bio: bio.present ? bio.value : this.bio,
    createdAt: createdAt ?? this.createdAt,
  );
  CachedFriendsTableData copyWithCompanion(CachedFriendsTableCompanion data) {
    return CachedFriendsTableData(
      friendId: data.friendId.present ? data.friendId.value : this.friendId,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      bio: data.bio.present ? data.bio.value : this.bio,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFriendsTableData(')
          ..write('friendId: $friendId, ')
          ..write('nickname: $nickname, ')
          ..write('avatar: $avatar, ')
          ..write('bio: $bio, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(friendId, nickname, avatar, bio, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFriendsTableData &&
          other.friendId == this.friendId &&
          other.nickname == this.nickname &&
          other.avatar == this.avatar &&
          other.bio == this.bio &&
          other.createdAt == this.createdAt);
}

class CachedFriendsTableCompanion
    extends UpdateCompanion<CachedFriendsTableData> {
  final Value<String> friendId;
  final Value<String> nickname;
  final Value<String?> avatar;
  final Value<String?> bio;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CachedFriendsTableCompanion({
    this.friendId = const Value.absent(),
    this.nickname = const Value.absent(),
    this.avatar = const Value.absent(),
    this.bio = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFriendsTableCompanion.insert({
    required String friendId,
    required String nickname,
    this.avatar = const Value.absent(),
    this.bio = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : friendId = Value(friendId),
       nickname = Value(nickname),
       createdAt = Value(createdAt);
  static Insertable<CachedFriendsTableData> custom({
    Expression<String>? friendId,
    Expression<String>? nickname,
    Expression<String>? avatar,
    Expression<String>? bio,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (friendId != null) 'friend_id': friendId,
      if (nickname != null) 'nickname': nickname,
      if (avatar != null) 'avatar': avatar,
      if (bio != null) 'bio': bio,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFriendsTableCompanion copyWith({
    Value<String>? friendId,
    Value<String>? nickname,
    Value<String?>? avatar,
    Value<String?>? bio,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return CachedFriendsTableCompanion(
      friendId: friendId ?? this.friendId,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (friendId.present) {
      map['friend_id'] = Variable<String>(friendId.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFriendsTableCompanion(')
          ..write('friendId: $friendId, ')
          ..write('nickname: $nickname, ')
          ..write('avatar: $avatar, ')
          ..write('bio: $bio, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTrashTableTable extends LocalTrashTable
    with TableInfo<$LocalTrashTableTable, LocalTrashTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTrashTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entityId, entityType, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_trash_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTrashTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityId};
  @override
  LocalTrashTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTrashTableData(
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $LocalTrashTableTable createAlias(String alias) {
    return $LocalTrashTableTable(attachedDatabase, alias);
  }
}

class LocalTrashTableData extends DataClass
    implements Insertable<LocalTrashTableData> {
  final String entityId;
  final String entityType;
  final int deletedAt;
  const LocalTrashTableData({
    required this.entityId,
    required this.entityType,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_id'] = Variable<String>(entityId);
    map['entity_type'] = Variable<String>(entityType);
    map['deleted_at'] = Variable<int>(deletedAt);
    return map;
  }

  LocalTrashTableCompanion toCompanion(bool nullToAbsent) {
    return LocalTrashTableCompanion(
      entityId: Value(entityId),
      entityType: Value(entityType),
      deletedAt: Value(deletedAt),
    );
  }

  factory LocalTrashTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTrashTableData(
      entityId: serializer.fromJson<String>(json['entityId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      deletedAt: serializer.fromJson<int>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityId': serializer.toJson<String>(entityId),
      'entityType': serializer.toJson<String>(entityType),
      'deletedAt': serializer.toJson<int>(deletedAt),
    };
  }

  LocalTrashTableData copyWith({
    String? entityId,
    String? entityType,
    int? deletedAt,
  }) => LocalTrashTableData(
    entityId: entityId ?? this.entityId,
    entityType: entityType ?? this.entityType,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  LocalTrashTableData copyWithCompanion(LocalTrashTableCompanion data) {
    return LocalTrashTableData(
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrashTableData(')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityId, entityType, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTrashTableData &&
          other.entityId == this.entityId &&
          other.entityType == this.entityType &&
          other.deletedAt == this.deletedAt);
}

class LocalTrashTableCompanion extends UpdateCompanion<LocalTrashTableData> {
  final Value<String> entityId;
  final Value<String> entityType;
  final Value<int> deletedAt;
  final Value<int> rowid;
  const LocalTrashTableCompanion({
    this.entityId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTrashTableCompanion.insert({
    required String entityId,
    required String entityType,
    required int deletedAt,
    this.rowid = const Value.absent(),
  }) : entityId = Value(entityId),
       entityType = Value(entityType),
       deletedAt = Value(deletedAt);
  static Insertable<LocalTrashTableData> custom({
    Expression<String>? entityId,
    Expression<String>? entityType,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityId != null) 'entity_id': entityId,
      if (entityType != null) 'entity_type': entityType,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTrashTableCompanion copyWith({
    Value<String>? entityId,
    Value<String>? entityType,
    Value<int>? deletedAt,
    Value<int>? rowid,
  }) {
    return LocalTrashTableCompanion(
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrashTableCompanion(')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedMessagesTableTable cachedMessagesTable =
      $CachedMessagesTableTable(this);
  late final $CachedConversationsTableTable cachedConversationsTable =
      $CachedConversationsTableTable(this);
  late final $CachedFriendsTableTable cachedFriendsTable =
      $CachedFriendsTableTable(this);
  late final $LocalTrashTableTable localTrashTable = $LocalTrashTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedMessagesTable,
    cachedConversationsTable,
    cachedFriendsTable,
    localTrashTable,
  ];
}

typedef $$CachedMessagesTableTableCreateCompanionBuilder =
    CachedMessagesTableCompanion Function({
      required String id,
      required String conversationId,
      required String senderId,
      required String senderName,
      Value<String?> senderAvatar,
      required int seq,
      required int msgType,
      required String content,
      Value<String?> extra,
      Value<int> status,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$CachedMessagesTableTableUpdateCompanionBuilder =
    CachedMessagesTableCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String> senderId,
      Value<String> senderName,
      Value<String?> senderAvatar,
      Value<int> seq,
      Value<int> msgType,
      Value<String> content,
      Value<String?> extra,
      Value<int> status,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$CachedMessagesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMessagesTableTable> {
  $$CachedMessagesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderAvatar => $composableBuilder(
    column: $table.senderAvatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get msgType => $composableBuilder(
    column: $table.msgType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMessagesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMessagesTableTable> {
  $$CachedMessagesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderAvatar => $composableBuilder(
    column: $table.senderAvatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get msgType => $composableBuilder(
    column: $table.msgType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMessagesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMessagesTableTable> {
  $$CachedMessagesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderAvatar => $composableBuilder(
    column: $table.senderAvatar,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<int> get msgType =>
      $composableBuilder(column: $table.msgType, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get extra =>
      $composableBuilder(column: $table.extra, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CachedMessagesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMessagesTableTable,
          CachedMessagesTableData,
          $$CachedMessagesTableTableFilterComposer,
          $$CachedMessagesTableTableOrderingComposer,
          $$CachedMessagesTableTableAnnotationComposer,
          $$CachedMessagesTableTableCreateCompanionBuilder,
          $$CachedMessagesTableTableUpdateCompanionBuilder,
          (
            CachedMessagesTableData,
            BaseReferences<
              _$AppDatabase,
              $CachedMessagesTableTable,
              CachedMessagesTableData
            >,
          ),
          CachedMessagesTableData,
          PrefetchHooks Function()
        > {
  $$CachedMessagesTableTableTableManager(
    _$AppDatabase db,
    $CachedMessagesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMessagesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMessagesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedMessagesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<String> senderName = const Value.absent(),
                Value<String?> senderAvatar = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> msgType = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> extra = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMessagesTableCompanion(
                id: id,
                conversationId: conversationId,
                senderId: senderId,
                senderName: senderName,
                senderAvatar: senderAvatar,
                seq: seq,
                msgType: msgType,
                content: content,
                extra: extra,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                required String senderId,
                required String senderName,
                Value<String?> senderAvatar = const Value.absent(),
                required int seq,
                required int msgType,
                required String content,
                Value<String?> extra = const Value.absent(),
                Value<int> status = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedMessagesTableCompanion.insert(
                id: id,
                conversationId: conversationId,
                senderId: senderId,
                senderName: senderName,
                senderAvatar: senderAvatar,
                seq: seq,
                msgType: msgType,
                content: content,
                extra: extra,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMessagesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMessagesTableTable,
      CachedMessagesTableData,
      $$CachedMessagesTableTableFilterComposer,
      $$CachedMessagesTableTableOrderingComposer,
      $$CachedMessagesTableTableAnnotationComposer,
      $$CachedMessagesTableTableCreateCompanionBuilder,
      $$CachedMessagesTableTableUpdateCompanionBuilder,
      (
        CachedMessagesTableData,
        BaseReferences<
          _$AppDatabase,
          $CachedMessagesTableTable,
          CachedMessagesTableData
        >,
      ),
      CachedMessagesTableData,
      PrefetchHooks Function()
    >;
typedef $$CachedConversationsTableTableCreateCompanionBuilder =
    CachedConversationsTableCompanion Function({
      required String id,
      required int type,
      Value<String?> name,
      Value<String?> avatar,
      Value<String?> peerUserId,
      Value<String?> peerNickname,
      Value<String?> peerAvatar,
      Value<int?> lastMessageAt,
      Value<String?> lastMessagePreview,
      Value<int> unreadCount,
      Value<int> isPinned,
      Value<int> isMuted,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$CachedConversationsTableTableUpdateCompanionBuilder =
    CachedConversationsTableCompanion Function({
      Value<String> id,
      Value<int> type,
      Value<String?> name,
      Value<String?> avatar,
      Value<String?> peerUserId,
      Value<String?> peerNickname,
      Value<String?> peerAvatar,
      Value<int?> lastMessageAt,
      Value<String?> lastMessagePreview,
      Value<int> unreadCount,
      Value<int> isPinned,
      Value<int> isMuted,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$CachedConversationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CachedConversationsTableTable> {
  $$CachedConversationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerNickname => $composableBuilder(
    column: $table.peerNickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get peerAvatar => $composableBuilder(
    column: $table.peerAvatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedConversationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedConversationsTableTable> {
  $$CachedConversationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerNickname => $composableBuilder(
    column: $table.peerNickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get peerAvatar => $composableBuilder(
    column: $table.peerAvatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedConversationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedConversationsTableTable> {
  $$CachedConversationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get peerUserId => $composableBuilder(
    column: $table.peerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerNickname => $composableBuilder(
    column: $table.peerNickname,
    builder: (column) => column,
  );

  GeneratedColumn<String> get peerAvatar => $composableBuilder(
    column: $table.peerAvatar,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<int> get isMuted =>
      $composableBuilder(column: $table.isMuted, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CachedConversationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedConversationsTableTable,
          CachedConversationsTableData,
          $$CachedConversationsTableTableFilterComposer,
          $$CachedConversationsTableTableOrderingComposer,
          $$CachedConversationsTableTableAnnotationComposer,
          $$CachedConversationsTableTableCreateCompanionBuilder,
          $$CachedConversationsTableTableUpdateCompanionBuilder,
          (
            CachedConversationsTableData,
            BaseReferences<
              _$AppDatabase,
              $CachedConversationsTableTable,
              CachedConversationsTableData
            >,
          ),
          CachedConversationsTableData,
          PrefetchHooks Function()
        > {
  $$CachedConversationsTableTableTableManager(
    _$AppDatabase db,
    $CachedConversationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedConversationsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedConversationsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedConversationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> peerUserId = const Value.absent(),
                Value<String?> peerNickname = const Value.absent(),
                Value<String?> peerAvatar = const Value.absent(),
                Value<int?> lastMessageAt = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> isPinned = const Value.absent(),
                Value<int> isMuted = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedConversationsTableCompanion(
                id: id,
                type: type,
                name: name,
                avatar: avatar,
                peerUserId: peerUserId,
                peerNickname: peerNickname,
                peerAvatar: peerAvatar,
                lastMessageAt: lastMessageAt,
                lastMessagePreview: lastMessagePreview,
                unreadCount: unreadCount,
                isPinned: isPinned,
                isMuted: isMuted,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int type,
                Value<String?> name = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> peerUserId = const Value.absent(),
                Value<String?> peerNickname = const Value.absent(),
                Value<String?> peerAvatar = const Value.absent(),
                Value<int?> lastMessageAt = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> isPinned = const Value.absent(),
                Value<int> isMuted = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedConversationsTableCompanion.insert(
                id: id,
                type: type,
                name: name,
                avatar: avatar,
                peerUserId: peerUserId,
                peerNickname: peerNickname,
                peerAvatar: peerAvatar,
                lastMessageAt: lastMessageAt,
                lastMessagePreview: lastMessagePreview,
                unreadCount: unreadCount,
                isPinned: isPinned,
                isMuted: isMuted,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedConversationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedConversationsTableTable,
      CachedConversationsTableData,
      $$CachedConversationsTableTableFilterComposer,
      $$CachedConversationsTableTableOrderingComposer,
      $$CachedConversationsTableTableAnnotationComposer,
      $$CachedConversationsTableTableCreateCompanionBuilder,
      $$CachedConversationsTableTableUpdateCompanionBuilder,
      (
        CachedConversationsTableData,
        BaseReferences<
          _$AppDatabase,
          $CachedConversationsTableTable,
          CachedConversationsTableData
        >,
      ),
      CachedConversationsTableData,
      PrefetchHooks Function()
    >;
typedef $$CachedFriendsTableTableCreateCompanionBuilder =
    CachedFriendsTableCompanion Function({
      required String friendId,
      required String nickname,
      Value<String?> avatar,
      Value<String?> bio,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$CachedFriendsTableTableUpdateCompanionBuilder =
    CachedFriendsTableCompanion Function({
      Value<String> friendId,
      Value<String> nickname,
      Value<String?> avatar,
      Value<String?> bio,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$CachedFriendsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CachedFriendsTableTable> {
  $$CachedFriendsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFriendsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedFriendsTableTable> {
  $$CachedFriendsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFriendsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedFriendsTableTable> {
  $$CachedFriendsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get friendId =>
      $composableBuilder(column: $table.friendId, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CachedFriendsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedFriendsTableTable,
          CachedFriendsTableData,
          $$CachedFriendsTableTableFilterComposer,
          $$CachedFriendsTableTableOrderingComposer,
          $$CachedFriendsTableTableAnnotationComposer,
          $$CachedFriendsTableTableCreateCompanionBuilder,
          $$CachedFriendsTableTableUpdateCompanionBuilder,
          (
            CachedFriendsTableData,
            BaseReferences<
              _$AppDatabase,
              $CachedFriendsTableTable,
              CachedFriendsTableData
            >,
          ),
          CachedFriendsTableData,
          PrefetchHooks Function()
        > {
  $$CachedFriendsTableTableTableManager(
    _$AppDatabase db,
    $CachedFriendsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFriendsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFriendsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedFriendsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> friendId = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFriendsTableCompanion(
                friendId: friendId,
                nickname: nickname,
                avatar: avatar,
                bio: bio,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String friendId,
                required String nickname,
                Value<String?> avatar = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedFriendsTableCompanion.insert(
                friendId: friendId,
                nickname: nickname,
                avatar: avatar,
                bio: bio,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFriendsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedFriendsTableTable,
      CachedFriendsTableData,
      $$CachedFriendsTableTableFilterComposer,
      $$CachedFriendsTableTableOrderingComposer,
      $$CachedFriendsTableTableAnnotationComposer,
      $$CachedFriendsTableTableCreateCompanionBuilder,
      $$CachedFriendsTableTableUpdateCompanionBuilder,
      (
        CachedFriendsTableData,
        BaseReferences<
          _$AppDatabase,
          $CachedFriendsTableTable,
          CachedFriendsTableData
        >,
      ),
      CachedFriendsTableData,
      PrefetchHooks Function()
    >;
typedef $$LocalTrashTableTableCreateCompanionBuilder =
    LocalTrashTableCompanion Function({
      required String entityId,
      required String entityType,
      required int deletedAt,
      Value<int> rowid,
    });
typedef $$LocalTrashTableTableUpdateCompanionBuilder =
    LocalTrashTableCompanion Function({
      Value<String> entityId,
      Value<String> entityType,
      Value<int> deletedAt,
      Value<int> rowid,
    });

class $$LocalTrashTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTrashTableTable> {
  $$LocalTrashTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTrashTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTrashTableTable> {
  $$LocalTrashTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTrashTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTrashTableTable> {
  $$LocalTrashTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$LocalTrashTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTrashTableTable,
          LocalTrashTableData,
          $$LocalTrashTableTableFilterComposer,
          $$LocalTrashTableTableOrderingComposer,
          $$LocalTrashTableTableAnnotationComposer,
          $$LocalTrashTableTableCreateCompanionBuilder,
          $$LocalTrashTableTableUpdateCompanionBuilder,
          (
            LocalTrashTableData,
            BaseReferences<
              _$AppDatabase,
              $LocalTrashTableTable,
              LocalTrashTableData
            >,
          ),
          LocalTrashTableData,
          PrefetchHooks Function()
        > {
  $$LocalTrashTableTableTableManager(
    _$AppDatabase db,
    $LocalTrashTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTrashTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTrashTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTrashTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<int> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTrashTableCompanion(
                entityId: entityId,
                entityType: entityType,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityId,
                required String entityType,
                required int deletedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalTrashTableCompanion.insert(
                entityId: entityId,
                entityType: entityType,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTrashTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTrashTableTable,
      LocalTrashTableData,
      $$LocalTrashTableTableFilterComposer,
      $$LocalTrashTableTableOrderingComposer,
      $$LocalTrashTableTableAnnotationComposer,
      $$LocalTrashTableTableCreateCompanionBuilder,
      $$LocalTrashTableTableUpdateCompanionBuilder,
      (
        LocalTrashTableData,
        BaseReferences<
          _$AppDatabase,
          $LocalTrashTableTable,
          LocalTrashTableData
        >,
      ),
      LocalTrashTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedMessagesTableTableTableManager get cachedMessagesTable =>
      $$CachedMessagesTableTableTableManager(_db, _db.cachedMessagesTable);
  $$CachedConversationsTableTableTableManager get cachedConversationsTable =>
      $$CachedConversationsTableTableTableManager(
        _db,
        _db.cachedConversationsTable,
      );
  $$CachedFriendsTableTableTableManager get cachedFriendsTable =>
      $$CachedFriendsTableTableTableManager(_db, _db.cachedFriendsTable);
  $$LocalTrashTableTableTableManager get localTrashTable =>
      $$LocalTrashTableTableTableManager(_db, _db.localTrashTable);
}
