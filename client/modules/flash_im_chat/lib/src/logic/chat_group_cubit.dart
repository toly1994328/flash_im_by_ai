import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_core/flash_im_core.dart' show WsClient, WsFrame, GroupInfoUpdate;

import '../data/mention_member.dart';
import '../data/message_repository.dart';

/// 群组信息状态
class ChatGroupState extends Equatable {
  final String title;
  final bool isDisband;
  final String? announcement;
  final List<MentionMember>? members;

  const ChatGroupState({
    required this.title,
    this.isDisband = false,
    this.announcement,
    this.members,
  });

  ChatGroupState copyWith({
    String? title,
    bool? isDisband,
    String? announcement,
    List<MentionMember>? members,
  }) {
    return ChatGroupState(
      title: title ?? this.title,
      isDisband: isDisband ?? this.isDisband,
      announcement: announcement ?? this.announcement,
      members: members ?? this.members,
    );
  }

  @override
  List<Object?> get props => [title, isDisband, announcement, members];
}

/// 群组相关状态管理
///
/// 职责：群名、公告、解散状态、群成员列表、监听 WS 群信息更新
class ChatGroupCubit extends Cubit<ChatGroupState> {
  final String conversationId;
  final WsClient _wsClient;
  final MessageRepository _repository;
  final Future<Map<String, dynamic>> Function()? _groupDetailFetcher;
  StreamSubscription? _groupInfoSub;

  ChatGroupCubit({
    required this.conversationId,
    required WsClient wsClient,
    required MessageRepository repository,
    required String initialTitle,
    bool isDisband = false,
    String? announcement,
    Future<Map<String, dynamic>> Function()? groupDetailFetcher,
  })  : _wsClient = wsClient,
        _repository = repository,
        _groupDetailFetcher = groupDetailFetcher,
        super(ChatGroupState(
          title: initialTitle,
          isDisband: isDisband,
          announcement: announcement,
        )) {
    _groupInfoSub = _wsClient.groupInfoUpdateStream.listen(_onGroupInfoUpdate);
  }

  /// 异步拉取群详情（公告 + 解散状态）
  Future<void> loadGroupDetail() async {
    final Future<Map<String, dynamic>> Function()? fetcher = _groupDetailFetcher;
    if (fetcher == null) return;
    try {
      final Map<String, dynamic> detail = await fetcher();
      final int status = detail['status'] as int? ?? 0;
      final String? announcement = detail['announcement'] as String?;
      emit(state.copyWith(
        isDisband: status == 1,
        announcement: announcement,
      ));
    } catch (_) {}
  }

  /// 加载群成员列表
  Future<void> loadGroupMembers() async {
    try {
      final res = await _repository.dio.get('/groups/$conversationId/detail');
      final Map<String, dynamic> data = res.data as Map<String, dynamic>;
      final List rawMembers = data['members'] as List? ?? [];
      final List<MentionMember> members = rawMembers.map((m) => MentionMember(
        userId: (m['user_id'] ?? m['id']).toString(),
        nickname: m['nickname'] as String? ?? '?',
        avatar: m['avatar'] as String?,
      )).toList();
      emit(state.copyWith(members: members));
    } catch (_) {}
  }

  /// 获取群成员列表（供 membersFetcher 使用）
  Future<List<MentionMember>> fetchGroupMembers() async {
    await loadGroupMembers();
    return state.members ?? const [];
  }

  /// 可显示的公告（解散/无公告时为 null）
  String? get notice =>
      state.isDisband ? null : state.announcement?.isNotEmpty == true ? state.announcement : null;

  void _onGroupInfoUpdate(WsFrame frame) {
    final GroupInfoUpdate update = GroupInfoUpdate.fromBuffer(frame.payload);
    if (update.conversationId != conversationId) return;
    emit(state.copyWith(
      title: update.hasName() ? update.name : null,
      announcement: update.hasAnnouncement() ? update.announcement : null,
      isDisband: update.hasStatus() ? update.status == 1 : null,
    ));
  }

  @override
  Future<void> close() {
    _groupInfoSub?.cancel();
    return super.close();
  }
}
