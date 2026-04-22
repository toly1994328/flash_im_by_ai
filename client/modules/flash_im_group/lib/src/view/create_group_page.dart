import 'package:flash_shared/flash_shared.dart';
import 'package:flutter/material.dart';
import '../data/group_models.dart';

/// 创建群聊页面 — MemberPickerPage 的业务包装
///
/// 在通用选人能力之上，加了群名自动拼接逻辑。
/// 返回 CreateGroupResult（含群名 + 成员 ID 列表）。
class CreateGroupPage extends StatelessWidget {
  final List<SelectableMember> members;
  final Set<String> initialSelectedIds;
  final void Function(CreateGroupResult result)? onCreated;

  const CreateGroupPage({
    super.key,
    required this.members,
    this.initialSelectedIds = const {},
    this.onCreated,
  });

  String _buildGroupName(List<String> ids, List<SelectableMember> members) {
    final memberMap = {for (final m in members) m.id: m.nickname};
    final names = ids.map((id) => memberMap[id] ?? '').where((n) => n.isNotEmpty).toList();
    if (names.length <= 3) return names.join('、');
    return '${names.take(3).join('、')}等';
  }

  @override
  Widget build(BuildContext context) {
    return MemberPickerPage(
      members: members,
      lockedIds: initialSelectedIds,
      title: '选择联系人',
      confirmLabel: '完成',
      minNewSelection: initialSelectedIds.isEmpty ? 2 : 1,
      onConfirm: (result) {
        final groupResult = CreateGroupResult(
          name: _buildGroupName(result.allIds, members),
          memberIds: result.allIds.map((id) => int.parse(id)).toList(),
        );
        if (onCreated != null) {
          onCreated!(groupResult);
        } else {
          Navigator.pop(context, groupResult);
        }
      },
    );
  }
}
