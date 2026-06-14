import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/group_repository.dart';
import '../../logic/group_info_cubit.dart';

/// 群详情 Cubit 作用域
///
/// 负责创建和提供 [GroupInfoCubit]，与具体 UI 组件解耦。
/// 包裹在 [GroupChatInfoPage] 外层使用。
class GroupInfoScope extends StatelessWidget {
  final GroupRepository repository;
  final String conversationId;
  final String? currentUserId;
  final Widget child;

  const GroupInfoScope({
    super.key,
    required this.repository,
    required this.conversationId,
    this.currentUserId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupInfoCubit(
        repository: repository,
        conversationId: conversationId,
      )..setCurrentUserId(currentUserId),
      child: child,
    );
  }
}
