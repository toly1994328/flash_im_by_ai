import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:fx_logger/fx_logger.dart';

import 'local_store.dart';
import 'models/cached_message.dart';
import 'models/cached_conversation.dart';
import 'models/cached_friend.dart';

/// 同步引擎
///
/// 订阅 WsClient 的事件流，将实时数据写入 LocalStore。
/// 监听连接状态，重连后自动增量同步。
/// 通过回调通知上层数据变更（参考腾讯 IM SDK 模式）。
class SyncEngine {
  final LocalStore _store;
  final WsClient _wsClient;
  final Dio _dio;
  final String? currentUserId;
  final List<StreamSubscription> _subs = [];
  bool _isSyncing = false;
  final _log = FxLog('Sync');

  /// 同步状态流（true=同步中，false=同步完成/空闲）
  final _syncingController = StreamController<bool>.broadcast();
  Stream<bool> get syncingStream => _syncingController.stream;
  bool get isSyncing => _isSyncing;

  /// 回调：会话数据变更时触发
  void Function()? onConversationChanged;

  /// 回调：好友数据变更时触发
  void Function()? onFriendListChanged;

  /// 回调：消息数据变更时触发（携带会话 ID）
  void Function(String conversationId)? onMessagesChanged;

  /// 回调：收到 @我 的消息时触发（conversationId, "messageId:type"）
  void Function(String conversationId, String mentionId)? onMentionMe;

  SyncEngine({
    required LocalStore store,
    required WsClient wsClient,
    required Dio dio,
    this.currentUserId,
    this.onConversationChanged,
    this.onFriendListChanged,
    this.onMessagesChanged,
    this.onMentionMe,
  })  : _store = store,
        _wsClient = wsClient,
        _dio = dio;

  /// 开始监听 WS 事件和连接状态
  void start() {
    _log.d('start() called, wsState=${_wsClient.state}');
    _subs.add(_wsClient.stateStream.listen(_onStateChange));
    _subs.add(_wsClient.chatMessageStream.listen(_handleChatMessage));
    _subs.add(
        _wsClient.conversationUpdateStream.listen(_handleConversationUpdate));
    _subs.add(_wsClient.friendAcceptedStream.listen(_handleFriendAccepted));
    _subs.add(_wsClient.friendRemovedStream.listen(_handleFriendRemoved));
    _subs.add(_wsClient.messageRecalledStream.listen(_handleMessageRecalled));

    // 如果已经认证（恢复会话场景），立即同步
    if (_wsClient.state == WsConnectionState.authenticated) {
      _log.d('already authenticated, triggering sync');
      _syncAfterReconnect();
    }
  }

  void _onStateChange(WsConnectionState state) {
    _log.d('WS state changed: $state');
    if (state == WsConnectionState.authenticated) {
      _syncAfterReconnect();
    }
  }

  // ─── 重连 / 首次同步 ───

  Future<void> _syncAfterReconnect() async {
    if (_isSyncing) {
      _log.d('already syncing, skip');
      return;
    }
    _isSyncing = true;
    _syncingController.add(true);
    try {
      final isFirst = await _store.isFirstLogin();
      _log.d('sync start (firstLogin=$isFirst)');
      await _syncConversations();
      await _syncFriends();
      await _syncMessages(fullPull: isFirst);
      _log.i('sync completed');
    } catch (e) {
      _log.w('sync failed: $e');
    } finally {
      _isSyncing = false;
      _syncingController.add(false);
    }
  }

  Future<void> _syncConversations() async {
    try {
      final res = await _dio.get('/conversations',
          queryParameters: {'limit': 200, 'offset': 0});
      final List data = res.data as List;
      _log.d('syncConversations: ${data.length} remote');
      final remote = data.map((e) => _jsonToConversation(e as Map<String, dynamic>)).toList();
      await _store.syncConversations(remote);
      onConversationChanged?.call();
    } catch (e) {
      _log.w('syncConversations failed: $e');
    }
  }

  Future<void> _syncFriends() async {
    try {
      final res = await _dio.get('/api/friends',
          queryParameters: {'limit': 1000, 'offset': 0});
      final List data = res.data['data'] as List;
      _log.d('syncFriends: ${data.length} remote');
      final remote = data.map((e) => _jsonToFriend(e as Map<String, dynamic>)).toList();
      await _store.syncFriends(remote);
      onFriendListChanged?.call();
    } catch (e) {
      _log.w('syncFriends failed: $e');
    }
  }

  Future<void> _syncMessages({bool fullPull = false}) async {
    try {
      if (fullPull) {
        // 首次登录：对每个会话拉最近消息
        final conversations = await _store.getConversations(limit: 200);
        _log.d('fullPull: ${conversations.length} conversations');
        for (final conv in conversations) {
          await _pullLatestMessages(conv.id);
        }
      } else {
        // 增量同步：对每个有缓存的会话拉差量
        final convIds = await _store.getCachedConversationIds();
        _log.d('incremental: ${convIds.length} cached conversations');
        for (final convId in convIds) {
          final maxSeq = await _store.getMaxSeq(convId);
          await _pullAfterSeq(convId, maxSeq);
        }
      }
    } catch (e) {
      _log.w('syncMessages failed: $e');
    }
  }

  Future<void> _pullLatestMessages(String conversationId) async {
    try {
      final res = await _dio.get('/conversations/$conversationId/messages',
          queryParameters: {'limit': 50});
      final List data = res.data as List;
      if (data.isEmpty) return;
      _log.d('pullLatest $conversationId: ${data.length} messages');
      final messages = data.map((e) => _jsonToMessage(e as Map<String, dynamic>)).toList();
      await _store.cacheMessages(messages, conversationId: conversationId);
    } catch (e) {
      _log.w('pullLatest $conversationId failed: $e');
    }
  }

  Future<void> _pullAfterSeq(String conversationId, int afterSeq) async {
    try {
      final res = await _dio.get('/conversations/$conversationId/messages',
          queryParameters: {'after_seq': afterSeq, 'limit': 100});
      final List data = res.data as List;
      if (data.isEmpty) return;
      _log.d('pullAfterSeq $conversationId (after=$afterSeq): ${data.length} messages');
      final messages = data.map((e) => _jsonToMessage(e as Map<String, dynamic>)).toList();
      await _store.cacheMessages(messages, conversationId: conversationId);
    } catch (e) {
      _log.w('pullAfterSeq $conversationId failed: $e');
    }
  }

  // ─── 实时事件处理 ───

  void _handleChatMessage(WsFrame frame) {
    try {
      final chatMsg = ChatMessage.fromBuffer(frame.payload);
      _log.d('chatMessage: conv=${chatMsg.conversationId}, seq=${chatMsg.seq}');
      final message = CachedMessage(
        id: chatMsg.id,
        conversationId: chatMsg.conversationId,
        senderId: chatMsg.senderId,
        senderName: chatMsg.senderName,
        senderAvatar:
            chatMsg.senderAvatar.isEmpty ? null : chatMsg.senderAvatar,
        seq: chatMsg.seq.toInt(),
        msgType: chatMsg.type.value,
        content: chatMsg.content,
        extra: chatMsg.extra.isNotEmpty
            ? utf8.decode(chatMsg.extra)
            : null,
        createdAt: chatMsg.createdAt.toInt(),
      );
      _store.cacheMessages([message],
          conversationId: chatMsg.conversationId);

      // 检测 @我：解析 extra.mentions
      if (currentUserId != null && chatMsg.extra.isNotEmpty) {
        try {
          final extraStr = utf8.decode(chatMsg.extra);
          final extraJson = json.decode(extraStr) as Map<String, dynamic>?;
          final mentions = extraJson?['mentions'] as List?;
          if (mentions != null) {
            final hasAll = mentions.any((m) => m['user_id'] == 'all');
            final hasMe = mentions.any((m) => m['user_id'] == currentUserId);
            if (hasAll) {
              onMentionMe?.call(chatMsg.conversationId, '${chatMsg.id}:all');
            } else if (hasMe) {
              onMentionMe?.call(chatMsg.conversationId, '${chatMsg.id}:me');
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      _log.w('handleChatMessage failed: $e');
    }
  }

  void _handleConversationUpdate(WsFrame frame) {
    try {
      final update = ConversationUpdate.fromBuffer(frame.payload);
      _log.d('convUpdate: ${update.conversationId}, preview=${update.lastMessagePreview}');
      _store.updateConversation(
        update.conversationId,
        lastMessagePreview: update.lastMessagePreview,
        lastMessageAt: update.lastMessageAt.toInt(),
        lastMessageExtra: update.lastMessageExtra.isNotEmpty ? update.lastMessageExtra : null,
      );
      // 不调 onConversationChanged：ConversationListCubit 自己监听 WS 帧做局部更新
    } catch (e) {
      _log.w('handleConversationUpdate failed: $e');
    }
  }

  void _handleFriendAccepted(WsFrame frame) {
    try {
      final notif = FriendAcceptedNotification.fromBuffer(frame.payload);
      _log.d('friendAccepted: ${notif.friendId} ${notif.nickname}');
      final friend = CachedFriend(
        friendId: notif.friendId,
        nickname: notif.nickname,
        avatar: notif.avatar.isEmpty ? null : notif.avatar,
        createdAt: notif.createdAt.toInt(),
      );
      _store.cacheFriends([friend]);
    } catch (e) {
      _log.w('handleFriendAccepted failed: $e');
    }
  }

  void _handleFriendRemoved(WsFrame frame) {
    try {
      final notif = FriendRemovedNotification.fromBuffer(frame.payload);
      _log.d('friendRemoved: ${notif.friendId}');
      _store.deleteFriend(notif.friendId);
    } catch (e) {
      _log.w('handleFriendRemoved failed: $e');
    }
  }

  void _handleMessageRecalled(WsFrame frame) {
    try {
      final recalled = MessageRecalled.fromBuffer(frame.payload);
      _log.d('messageRecalled: ${recalled.messageId} in ${recalled.conversationId}');
      // 本地缓存中该消息的 status 会在下次增量同步时被覆盖为 1
      // 这里不需要额外操作，ChatCubit 会通过自己的监听处理 UI 更新
    } catch (e) {
      _log.w('handleMessageRecalled failed: $e');
    }
  }

  // ─── JSON → 纯 Dart 模型 ───

  CachedMessage _jsonToMessage(Map<String, dynamic> json) {
    return CachedMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'].toString(),
      senderName: json['sender_name'] as String? ?? '',
      senderAvatar: json['sender_avatar'] as String?,
      seq: json['seq'] as int,
      msgType: json['msg_type'] as int? ?? 0,
      content: json['content'] as String,
      extra: json['extra'] != null ? jsonEncode(json['extra']) : null,
      status: json['status'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String)
          .millisecondsSinceEpoch,
    );
  }

  CachedConversation _jsonToConversation(Map<String, dynamic> json) {
    return CachedConversation(
      id: json['id'] as String,
      type: json['conv_type'] as int,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      peerUserId: json['peer_user_id'] as String?,
      peerNickname: json['peer_nickname'] as String?,
      peerAvatar: json['peer_avatar'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
              .millisecondsSinceEpoch
          : null,
      lastMessagePreview: json['last_message_preview'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
      pinnedAt: json['pinned_at'] != null
          ? DateTime.parse(json['pinned_at'] as String).millisecondsSinceEpoch
          : null,
      createdAt: DateTime.parse(json['created_at'] as String)
          .millisecondsSinceEpoch,
    );
  }

  CachedFriend _jsonToFriend(Map<String, dynamic> json) {
    return CachedFriend(
      friendId: json['friend_id'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String)
          .millisecondsSinceEpoch,
    );
  }

  /// 释放所有订阅
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _syncingController.close();
  }
}
