import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_cache/flash_im_cache.dart';

import '../data/message.dart';
import 'chat_state.dart';

/// 多选模式的 Mixin。
///
/// 包含进入/退出多选、切换选中、批量删除逻辑。
mixin ChatSelectMixin on Cubit<ChatState> {
  // ─── 抽象 getter / 方法，由 ChatCubit 实现 ───

  LocalStore? get localStore;
  String get conversationId;
  String get currentUserId;
  VoidCallback? get onConversationChanged;
  void syncConversationPreview(LocalStore store, List<Message> messages);

  // ─── 多选模式 ───

  void enterMultiSelect(String initialId) {
    final s = state;
    if (s is ChatLoaded) {
      emit(s.copyWith(isMultiSelect: true, selectedIds: {initialId}));
    }
  }

  void exitMultiSelect() {
    final s = state;
    if (s is ChatLoaded) {
      emit(s.copyWith(isMultiSelect: false, selectedIds: const {}));
    }
  }

  void toggleSelect(String messageId) {
    final s = state;
    if (s is! ChatLoaded) return;
    final ids = Set<String>.from(s.selectedIds);
    if (ids.contains(messageId)) {
      ids.remove(messageId);
    } else {
      ids.add(messageId);
    }
    emit(s.copyWith(selectedIds: ids));
  }

  Future<void> deleteSelected() async {
    final s = state;
    final store = localStore;
    if (s is! ChatLoaded || store == null) return;
    final idsToDelete = Set<String>.from(s.selectedIds);
    for (final id in idsToDelete) {
      await store.moveToTrash(id, 'message');
    }
    final updated = s.messages.where((m) => !idsToDelete.contains(m.id)).toList();
    emit(s.copyWith(messages: updated, isMultiSelect: false, selectedIds: const {}));
    syncConversationPreview(store, updated);
  }
}
