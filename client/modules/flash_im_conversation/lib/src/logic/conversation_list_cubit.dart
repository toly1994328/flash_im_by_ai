import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:flash_shared/flash_shared.dart';
import '../data/conversation_repository.dart';
import '../data/conversation.dart';
import 'conversation_list_state.dart';

/// 会话列表状态管理（支持分页 + 实时更新）
class ConversationListCubit extends Cubit<ConversationListState> {
  final ConversationRepository _repository;
  final WsClient? _wsClient;
  static const int _pageSize = 20;
  static const String _clearedMapKey = 'conv_cleared_at_map';
  final Map<String, DateTime> _clearedAtMap = {};
  /// 被手动标记为未读的会话 ID 集合，点击时不清除未读数
  final Set<String> _manuallyMarkedUnread = {};
  bool _isLoadingMore = false;
  StreamSubscription? _updateSub;
  StreamSubscription? _groupInfoSub;
  String? _activeConversationId;

  ConversationListCubit(this._repository, {WsClient? wsClient})
      : _wsClient = wsClient,
        super(const ConversationListInitial()) {
    _updateSub = _wsClient?.conversationUpdateStream.listen(_handleUpdate);
    _groupInfoSub = _wsClient?.groupInfoUpdateStream.listen(_handleGroupInfoUpdate);
  }

  Future<void> _handleUpdate(WsFrame frame) async {
    try {
      final update = ConversationUpdate.fromBuffer(frame.payload);
      final current = state;
      if (current is! ConversationListLoaded) return;

      // 1. 处理 is_deleted：从列表移除
      if (update.hasIsDeleted() && update.isDeleted) {
        final filtered = current.conversations
            .where((c) => c.id != update.conversationId)
            .toList();
        final removed = current.conversations
            .firstWhere((c) => c.id == update.conversationId,
                orElse: () => Conversation(id: update.conversationId, type: 0, createdAt: DateTime.now()));
        final deltaTotal = removed.unreadCount;
        emit(ConversationListLoaded(
          filtered,
          hasMore: current.hasMore,
          totalUnread: (current.totalUnread - deltaTotal).clamp(0, 999999),
        ));
        return;
      }

      final found = current.conversations.any((c) => c.id == update.conversationId);

      if (!found) {
        // 仅 toggle 操作（无消息体）的未知会话 → 跳过
        final isToggleOnly = !update.hasLastMessageAt() &&
            (update.hasIsPinned() || update.hasIsMuted());
        if (isToggleOnly) return;

        // 未知会话：先插入骨架，再异步补全
        final skeleton = Conversation.skeleton(
          id: update.conversationId,
          lastMessagePreview: update.lastMessagePreview,
          lastMessageAt: DateTime.fromMillisecondsSinceEpoch(update.lastMessageAt.toInt()),
          unreadCount: update.unreadCount,
        );
        final updated = [skeleton, ...current.conversations];
        emit(ConversationListLoaded(
          updated,
          hasMore: current.hasMore,
          totalUnread: update.hasTotalUnread() ? update.totalUnread : current.totalUnread,
        ));
        // 异步拉取完整信息替换骨架
        _repository.getById(update.conversationId).then((full) async {
          final s = state;
          if (s is! ConversationListLoaded) return;
          final replaced = s.conversations.map((c) {
            if (c.id == full.id) return full.copyWith(unreadCount: c.unreadCount);
            return c;
          }).toList();
          await _ensureClearedAtMapLoaded();
          _applyClearedAtToPreviews(replaced);
          emit(ConversationListLoaded(replaced, hasMore: s.hasMore, totalUnread: s.totalUnread));
        }).catchError((_) {});
        return;
      }

      // 2. 已知会话：按字段覆盖式更新
      final updated = current.conversations.map((c) {
        if (c.id == update.conversationId) {
          final isActive = _activeConversationId == update.conversationId;
          if (isActive && update.unreadCount > 0) {
            _repository.markRead(update.conversationId).catchError((_) {});
          }

          // 真实新消息到达时，清除手动「标为未读」标记
          if (update.hasLastMessageAt()) {
            _manuallyMarkedUnread.remove(update.conversationId);
          }

          return c.copyWith(
            lastMessageAt: update.hasLastMessageAt()
                ? DateTime.fromMillisecondsSinceEpoch(update.lastMessageAt.toInt())
                : c.lastMessageAt,
            lastMessagePreview: update.hasLastMessagePreview()
                ? update.lastMessagePreview
                : c.lastMessagePreview,
            isPinned: update.hasIsPinned() ? update.isPinned : c.isPinned,
            isMuted: update.hasIsMuted() ? update.isMuted : c.isMuted,
            pinnedAt: update.hasIsPinned()
                ? (update.isPinned ? DateTime.now() : null)
                : c.pinnedAt,
            unreadCount: update.hasLastMessageAt()
                ? c.unreadCount + (isActive ? 0 : update.unreadCount)
                : c.unreadCount,
          );
        }
        return c;
      }).toList();

      _sortWithPinned(updated);
      await _ensureClearedAtMapLoaded();
      _applyClearedAtToPreviews(updated);

      emit(ConversationListLoaded(
        updated,
        hasMore: current.hasMore,
        totalUnread: update.hasTotalUnread() ? update.totalUnread : current.totalUnread,
      ));
    } catch (_) {}
  }

  /// 置顶分区排序：置顶在前（按 pinnedAt 倒序），普通在后（按 lastMessageAt 倒序）
  void _sortWithPinned(List<Conversation> list) {
    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      if (a.isPinned && b.isPinned) {
        final aTime = a.pinnedAt ?? a.createdAt;
        final bTime = b.pinnedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      }
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
  }

  /// 局部更新一个会话并重新 emit（带排序）
  void _patchAndEmit(String conversationId, Conversation Function(Conversation) mapper) {
    final current = state;
    if (current is! ConversationListLoaded) return;
    final updated = current.conversations.map((c) {
      if (c.id == conversationId) return mapper(c);
      return c;
    }).toList();
    _sortWithPinned(updated);
    _applyClearedAtToPreviews(updated);
    emit(ConversationListLoaded(updated, hasMore: current.hasMore, totalUnread: current.totalUnread));
  }

  /// 确保 _clearedAtMap 已从 SharedPrefs 加载
  Future<void> _ensureClearedAtMapLoaded() async {
    if (_clearedAtMap.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clearedMapKey) ?? '{}';
    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in map.entries) {
      final dt = DateTime.tryParse(entry.value as String);
      if (dt != null) _clearedAtMap[entry.key] = dt;
    }
  }

  /// 将 clearedAt 时间戳应用于会话列表：若 lastMessageAt 早于清空时间则清空预览
  void _applyClearedAtToPreviews(List<Conversation> list) {
    if (_clearedAtMap.isEmpty) return;
    for (int i = 0; i < list.length; i++) {
      final c = list[i];
      final clearedAt = _clearedAtMap[c.id];
      if (clearedAt == null) continue;
      final lmt = c.lastMessageAt;
      if (lmt != null && lmt.isBefore(clearedAt)) {
        list[i] = c.copyWith(clearPreview: true, unreadCount: 0);
      }
    }
  }

  Future<void> loadConversations() async {
    _isLoadingMore = false;
    try {
      final sw = Stopwatch()..start();
      var conversations = await _repository.getList(limit: _pageSize, offset: 0);
      debugPrint('[D/ConvCubit] loadConversations: ${conversations.length} items in ${sw.elapsedMilliseconds}ms');
      await _ensureClearedAtMapLoaded();
      _applyClearedAtToPreviews(conversations);
      _sortWithPinned(conversations);
      final hasMore = conversations.length >= _pageSize;
      emit(ConversationListLoaded(conversations, hasMore: hasMore));
    } catch (e) {
      if (state is! ConversationListLoaded) {
        emit(ConversationListError(e.toString()));
      }
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ConversationListLoaded || !current.hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    try {
      final offset = current.conversations.length;
      var more = await _repository.getList(limit: _pageSize, offset: offset);
      _applyClearedAtToPreviews(more);
      final hasMore = more.length >= _pageSize;
      final all = [...current.conversations, ...more];
      _sortWithPinned(all);
      emit(ConversationListLoaded(all, hasMore: hasMore, totalUnread: current.totalUnread));
    } catch (_) {
    } finally {
      _isLoadingMore = false;
    }
  }

  // ─── Toggle 操作（乐观更新 + HTTP） ───

  /// 翻转置顶状态
  Future<void> togglePin(String conversationId) async {
    final current = state;
    if (current is! ConversationListLoaded) return;
    final prev = current.conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => Conversation(id: conversationId, type: 0, createdAt: DateTime.now()),
    );

    // 乐观更新
    _patchAndEmit(conversationId, (c) => c.copyWith(
      isPinned: !c.isPinned,
      pinnedAt: !c.isPinned ? DateTime.now() : null,
    ));

    try {
      await _repository.togglePin(conversationId);
    } catch (_) {
      // 失败回滚
      _patchAndEmit(conversationId, (_) => prev);
    }
  }

  /// 翻转免打扰状态
  Future<void> toggleMute(String conversationId) async {
    final current = state;
    if (current is! ConversationListLoaded) return;
    final prev = current.conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => Conversation(id: conversationId, type: 0, createdAt: DateTime.now()),
    );

    _patchAndEmit(conversationId, (c) => c.copyWith(isMuted: !c.isMuted));

    try {
      await _repository.toggleMute(conversationId);
    } catch (_) {
      _patchAndEmit(conversationId, (_) => prev);
    }
  }

  /// 标记未读
  Future<void> markUnread(String conversationId) async {
    final current = state;
    if (current is! ConversationListLoaded) return;
    final prev = current.conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => Conversation(id: conversationId, type: 0, createdAt: DateTime.now()),
    );

    _manuallyMarkedUnread.add(conversationId);
    _patchAndEmit(conversationId, (c) => c.copyWith(unreadCount: 1));

    try {
      await _repository.markUnread(conversationId);
    } catch (_) {
      _manuallyMarkedUnread.remove(conversationId);
      _patchAndEmit(conversationId, (_) => prev);
    }
  }

  /// 清空当前会话的所有消息（设备级别，仅本地存储时间戳）
  Future<void> clearMessages(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clearedMapKey) ?? '{}';
    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    final now = DateTime.now().toUtc();
    map[conversationId] = now.toIso8601String();
    await prefs.setString(_clearedMapKey, jsonEncode(map));
    _clearedAtMap[conversationId] = now;

    // 清除本地 SQLite 缓存的消息
    try {
      await _repository.store?.clearConversationMessages(conversationId);
    } catch (_) {}

    // 本地更新预览：清空最后消息和时间、未读数归零
    _patchAndEmit(conversationId, (c) => c.copyWith(
      clearPreview: true,
      unreadCount: 0,
    ));

    // 通知消息模块立刻重新过滤当前已加载的消息列表
    ConversationClearedEvent(conversationId: conversationId).emit();
  }

  /// 获取指定会话的本地清空时间戳（供消息模块过滤用）
  Future<DateTime?> getClearedAt(String conversationId) async {
    if (_clearedAtMap.containsKey(conversationId)) {
      return _clearedAtMap[conversationId];
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clearedMapKey) ?? '{}';
    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    final val = map[conversationId];
    if (val != null) {
      final dt = DateTime.tryParse(val as String);
      if (dt != null) _clearedAtMap[conversationId] = dt;
      return dt;
    }
    return null;
  }

  Future<void> deleteConversation(String id) async {
    try {
      await _repository.delete(id);
      final current = state;
      if (current is ConversationListLoaded) {
        final conv = current.conversations.firstWhere(
          (c) => c.id == id,
          orElse: () => Conversation(id: id, type: 0, createdAt: DateTime.now()),
        );
        final updated = current.conversations.where((c) => c.id != id).toList();
        emit(ConversationListLoaded(
          updated,
          hasMore: current.hasMore,
          totalUnread: (current.totalUnread - conv.unreadCount).clamp(0, 999999),
        ));
      }
    } catch (_) {}
  }

  /// 标记当前正在查看的会话（收到该会话消息时不累加未读）
  void setActiveConversation(String conversationId) {
    _activeConversationId = conversationId;
  }

  /// 离开聊天页时清除活跃会话标记
  void clearActiveConversation() {
    _activeConversationId = null;
  }

  /// 清除会话未读数
  ///
  /// [skipIfManuallyMarked] 为 true 时，若该会话被手动标为未读则跳过清除。
  /// 点击进入聊天时传 true，右键菜单「标为已读」时传 false（强制清除）。
  Future<void> clearUnread(String conversationId, {bool skipIfManuallyMarked = false}) async {
    if (skipIfManuallyMarked && _manuallyMarkedUnread.contains(conversationId)) return;
    _manuallyMarkedUnread.remove(conversationId);
    final current = state;
    if (current is! ConversationListLoaded) return;
    final idx = current.conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    final conv = current.conversations[idx];
    if (conv.unreadCount == 0) return;
    final delta = conv.unreadCount;
    final updated = current.conversations.map((c) {
      if (c.id == conversationId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();
    emit(ConversationListLoaded(
      updated,
      hasMore: current.hasMore,
      totalUnread: (current.totalUnread - delta).clamp(0, 999999),
    ));
    // 通知后端
    _repository.markRead(conversationId).catchError((_) {});
  }

  void _handleGroupInfoUpdate(WsFrame frame) {
    try {
      final update = GroupInfoUpdate.fromBuffer(frame.payload);
      final current = state;
      if (current is! ConversationListLoaded) return;

      final updated = current.conversations.map((c) {
        if (c.id == update.conversationId) {
          return Conversation(
            id: c.id,
            type: c.type,
            name: update.hasName() ? update.name : c.name,
            avatar: update.hasAvatar() ? update.avatar : c.avatar,
            peerUserId: c.peerUserId,
            peerNickname: c.peerNickname,
            peerAvatar: c.peerAvatar,
            lastMessageAt: c.lastMessageAt,
            lastMessagePreview: c.lastMessagePreview,
            unreadCount: c.unreadCount,
            isPinned: c.isPinned,
            isMuted: c.isMuted,
            pinnedAt: c.pinnedAt,
            createdAt: c.createdAt,
          );
        }
        return c;
      }).toList();

      emit(ConversationListLoaded(updated, hasMore: current.hasMore, totalUnread: current.totalUnread));
    } catch (_) {}
  }

  // ─── @提及标记 ───

  final Map<String, List<MentionMeRecord>> _mentionMeMap = {};

  /// 收到 @我 的消息时调用
  void addMentionMe(String conversationId, MentionMeRecord record) {
    _mentionMeMap.putIfAbsent(conversationId, () => []).add(record);
    final current = state;
    if (current is ConversationListLoaded) {
      emit(ConversationListLoaded(
        current.conversations,
        hasMore: current.hasMore,
        totalUnread: current.totalUnread,
      ));
    }
  }

  /// 进入会话时清除 @我 标记
  void clearMentionMe(String conversationId) {
    _mentionMeMap.remove(conversationId);
  }

  /// 获取某会话的 @我 记录列表
  List<MentionMeRecord> getMentionMeRecords(String conversationId) {
    return _mentionMeMap[conversationId] ?? [];
  }

  @override
  Future<void> close() {
    _updateSub?.cancel();
    _groupInfoSub?.cancel();
    return super.close();
  }
}
