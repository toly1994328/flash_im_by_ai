import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_shared/flash_shared.dart' show ShowToastEvent;

import '../data/group_detail.dart';
import '../data/group_repository.dart';

/// 群详情页状态
sealed class GroupInfoState extends Equatable {
  const GroupInfoState();
  @override
  List<Object?> get props => [];
}

class GroupInfoLoading extends GroupInfoState {
  const GroupInfoLoading();
}

class GroupInfoError extends GroupInfoState {
  final String message;
  const GroupInfoError(this.message);
  @override
  List<Object?> get props => [message];
}

class GroupInfoLoaded extends GroupInfoState {
  final GroupDetail detail;
  const GroupInfoLoaded(this.detail);
  @override
  List<Object?> get props => [detail];
}

/// 群详情状态管理
///
/// 管理群详情加载和所有群管理操作（邀请/踢人/转让/解散/退出/改名/验证开关）。
/// 操作失败时 emit [ShowToastEvent]，成功后自动刷新详情。
class GroupInfoCubit extends Cubit<GroupInfoState> {
  final GroupRepository _repository;
  final String conversationId;

  GroupRepository get repository => _repository;

  GroupInfoCubit({
    required GroupRepository repository,
    required this.conversationId,
  })  : _repository = repository,
        super(const GroupInfoLoading()) {
    loadDetail();
  }

  GroupDetail? get detail => state is GroupInfoLoaded ? (state as GroupInfoLoaded).detail : null;
  bool get isOwner => detail?.ownerId == _currentUserId;
  String? _currentUserId;

  void setCurrentUserId(String? userId) => _currentUserId = userId;

  Future<void> loadDetail() async {
    try {
      final GroupDetail detail = await _repository.getGroupDetail(conversationId);
      emit(GroupInfoLoaded(detail));
    } catch (e) {
      emit(GroupInfoError(e.toString()));
    }
  }

  Future<void> toggleJoinVerification(bool value) async {
    try {
      await _repository.updateGroupSettings(conversationId, joinVerification: value);
      await loadDetail();
    } catch (e) {
      ShowToastEvent('操作失败：$e').emit();
      await loadDetail();
    }
  }

  Future<int> inviteMembers(List<int> memberIds) async {
    try {
      final int count = await _repository.addMembers(conversationId, memberIds);
      await loadDetail();
      return count;
    } catch (e) {
      ShowToastEvent('邀请失败：$e').emit();
      return 0;
    }
  }

  Future<void> removeMember(int userId) async {
    try {
      await _repository.removeMember(conversationId, userId);
      await loadDetail();
    } catch (e) {
      ShowToastEvent('移除失败：$e').emit();
    }
  }

  Future<void> removeMembers(List<String> userIds) async {
    int removed = 0;
    for (final String uid in userIds) {
      try {
        await _repository.removeMember(conversationId, int.parse(uid));
        removed++;
      } catch (e) {
        ShowToastEvent('移除失败：$e').emit();
      }
    }
    if (removed > 0) {
      ShowToastEvent('已移除 $removed 人').emit();
      await loadDetail();
    }
  }

  Future<void> transferOwner(int newOwnerId, String nickname) async {
    try {
      await _repository.transferOwner(conversationId, newOwnerId);
      ShowToastEvent('已将群主转让给 $nickname').emit();
      await loadDetail();
    } catch (e) {
      ShowToastEvent('转让失败：$e').emit();
    }
  }

  Future<void> disbandGroup() async {
    try {
      await _repository.disbandGroup(conversationId);
      ShowToastEvent('群聊已解散').emit();
    } catch (e) {
      ShowToastEvent('解散失败：$e').emit();
    }
  }

  Future<void> leaveGroup() async {
    try {
      await _repository.leaveGroup(conversationId);
      ShowToastEvent('已退出群聊').emit();
    } catch (e) {
      ShowToastEvent('退出失败：$e').emit();
    }
  }

  Future<void> updateGroupName(String newName) async {
    try {
      await _repository.updateGroup(conversationId, name: newName);
      ShowToastEvent('群名已修改').emit();
      await loadDetail();
    } catch (e) {
      ShowToastEvent('修改失败：$e').emit();
    }
  }
}
